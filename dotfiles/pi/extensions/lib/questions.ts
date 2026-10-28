import { ExtensionEditorComponent, type ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Key, matchesKey, truncateToWidth, wrapTextWithAnsi } from "@earendil-works/pi-tui";

export type Question = { question: string; options?: string[] };
export type Answer = { question: string; answer: string; custom: boolean };
export type Result = { answers: Answer[]; cancelled: boolean };
let queue: Promise<unknown> = Promise.resolve();

export function askQuestions(
	ctx: ExtensionContext,
	questions: Question[],
	signal?: AbortSignal,
	editorCommand?: string,
): Promise<Result> {
	const result = queue.then(() => showQuestions(ctx, questions, signal, editorCommand));
	queue = result.catch(() => undefined);
	return result;
}

async function showQuestions(
	ctx: ExtensionContext,
	questions: Question[],
	signal?: AbortSignal,
	editorCommand?: string,
): Promise<Result> {
	const answers: Answer[] = [];
	if (ctx.mode !== "tui" || signal?.aborted) return { answers, cancelled: true };
	for (const [index, question] of questions.entries()) {
		if (signal?.aborted) return { answers, cancelled: true };
		const answer = await ctx.ui.custom<Answer | undefined>((tui, theme, keybindings, done) => {
			const options = question.options ?? [];
			const choices = [...options, "Write my own answer…"];
			let selected = 0;
			let editing = options.length === 0;
			let focused = false;
			let finished = false;
			let draft: ExtensionEditorComponent | undefined;
			function finish(value: Answer | undefined) {
				if (finished) return;
				finished = true;
				signal?.removeEventListener("abort", abort);
				done(value);
			}
			function abort() { finish(undefined); }
			function refresh() {
				if (draft) draft.focused = focused && editing;
				tui.requestRender();
			}
			function answerEditor(prefill = "") {
				return new ExtensionEditorComponent(tui, keybindings, "Your answer", prefill,
					(value) => {
						if (value.trim()) finish({ question: question.question, answer: value.trim(), custom: true });
					},
					() => {
						if (!options.length) finish(undefined);
						else { editing = false; refresh(); }
					}, undefined, editorCommand);
			}
			function startEditing(prefill = "") {
				draft ??= answerEditor(prefill);
				editing = true;
				refresh();
			}
			if (editing) draft = answerEditor();
			signal?.addEventListener("abort", abort, { once: true });
			if (signal?.aborted) queueMicrotask(abort);
			return {
				get focused() { return focused; },
				set focused(value: boolean) {
					focused = value;
					if (draft) draft.focused = value && editing;
				},
				handleInput(data: string) {
					if (finished) return;
					if (matchesKey(data, Key.tab)) {
						if (editing && options.length) { editing = false; refresh(); }
						else startEditing();
						return;
					}
					if (editing) { draft?.handleInput(data); refresh(); return; }
					if (keybindings.matches(data, "app.editor.external")) {
						startEditing(options[selected] ?? "");
						draft?.handleInput(data);
					} else if (matchesKey(data, Key.escape) || matchesKey(data, Key.ctrl("c"))) finish(undefined);
					else if (data === "k" || matchesKey(data, Key.up)) selected = (selected + choices.length - 1) % choices.length;
					else if (data === "j" || matchesKey(data, Key.down)) selected = (selected + 1) % choices.length;
					else if (matchesKey(data, Key.enter)) {
						if (selected === options.length) startEditing();
						else if (options[selected] !== undefined) finish({ question: question.question, answer: options[selected], custom: false });
					}
					refresh();
				},
				render(width: number) {
					const w = Math.max(1, width);
					const lines = [theme.fg("accent", "─".repeat(w))];
					lines.push(...wrapTextWithAnsi(theme.fg("accent", `Question ${index + 1}/${questions.length}`), w));
					lines.push(...question.question.split("\n").flatMap((line) => wrapTextWithAnsi(line || " ", w)));
					lines.push("");
					if (options.length) {
						for (const [i, option] of choices.entries()) {
							const active = !editing && selected === i;
							lines.push(...wrapTextWithAnsi(theme.fg(active ? "accent" : "muted", `${active ? "›" : " "} ${i + 1}. ${option}`), w));
						}
						lines.push("");
					}
					if (editing && draft) lines.push(...draft.render(w));
					else {
						lines.push(...wrapTextWithAnsi(theme.fg("dim", "j/k or ↑↓ choose · Enter select · Tab write · Ctrl+G external editor · Esc cancel"), w));
						lines.push(theme.fg("accent", "─".repeat(w)));
					}
					return lines.map((line) => truncateToWidth(line, w));
				},
				invalidate() { draft?.invalidate(); },
				dispose() { finished = true; signal?.removeEventListener("abort", abort); },
			};
		});
		if (!answer) return { answers, cancelled: true };
		answers.push(answer);
	}
	return { answers, cancelled: false };
}
