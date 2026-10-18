import {
	ExtensionEditorComponent,
	type ExtensionAPI,
	type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { Key, matchesKey, Text, truncateToWidth, wrapTextWithAnsi } from "@earendil-works/pi-tui";
import { Type, type Static } from "typebox";

const QuestionSchema = Type.Object({
	question: Type.String({ minLength: 1, description: "The question to display to the user." }),
	options: Type.Optional(Type.Array(Type.String({ minLength: 1 }), {
		maxItems: 8,
		description: "Suggested answers. A custom answer is always available. Omit for free-form input.",
	})),
});

const Params = Type.Object({
	questions: Type.Array(QuestionSchema, { minItems: 1, maxItems: 8 }),
});

type Question = Static<typeof QuestionSchema>;
type Answer = { question: string; answer: string; custom: boolean };
type Result = { answers: Answer[]; cancelled: boolean };

async function askQuestions(
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

			function abort() {
				finish(undefined);
			}

			function refresh() {
				if (draft) draft.focused = focused && editing;
				tui.requestRender();
			}

			function answerEditor(prefill = "") {
				return new ExtensionEditorComponent(
					tui,
					keybindings,
					"Your answer",
					prefill,
					(value) => {
						if (value.trim()) finish({ question: question.question, answer: value.trim(), custom: true });
					},
					() => {
						if (!options.length) finish(undefined);
						else {
							editing = false;
							refresh();
						}
					},
					undefined,
					editorCommand,
				);
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
						if (editing && options.length) {
							editing = false;
							refresh();
						} else startEditing();
						return;
					}
					if (editing) {
						draft?.handleInput(data);
						refresh();
						return;
					}
					if (keybindings.matches(data, "app.editor.external")) {
						startEditing(options[selected] ?? "");
						draft?.handleInput(data);
					} else if (matchesKey(data, Key.escape) || matchesKey(data, Key.ctrl("c"))) finish(undefined);
					else if (data === "k" || matchesKey(data, Key.up)) selected = (selected + options.length) % (options.length + 1);
					else if (data === "j" || matchesKey(data, Key.down)) selected = (selected + 1) % (options.length + 1);
					else if (matchesKey(data, Key.enter)) {
						if (selected === options.length) startEditing();
						else finish({ question: question.question, answer: options[selected], custom: false });
					}
					refresh();
				},
				render(width: number) {
					const w = Math.max(1, width);
					const lines = [theme.fg("accent", "─".repeat(w))];
					lines.push(...wrapTextWithAnsi(theme.fg("accent", `Question ${index + 1}/${questions.length}`), w));
					lines.push(...wrapTextWithAnsi(question.question, w), "");
					if (options.length) {
						for (const [i, option] of [...options, "Write my own answer…"].entries()) {
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
				dispose() {
					finished = true;
					signal?.removeEventListener("abort", abort);
				},
			};
		});
		if (!answer) return { answers, cancelled: true };
		answers.push(answer);
	}
	return { answers, cancelled: false };
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "ask_user",
		label: "Ask user",
		description: "Ask the user clarification questions in an interactive panel. Supports suggested choices, free-form answers, and an external editor. Ask related questions together.",
		promptGuidelines: [
			"When you need clarification, preferences, or a decision from the user, use ask_user instead of asking questions in ordinary response text. Never invent an answer if the user cancels.",
		],
		parameters: Params,
		executionMode: "sequential",
		async execute(_id, params, signal, _onUpdate, ctx) {
			if (ctx.mode !== "tui") {
				return {
					content: [{ type: "text", text: "ask_user requires the interactive Pi TUI. Ask the questions in plain text instead." }],
					details: { answers: [], cancelled: true } satisfies Result,
					isError: true,
				};
			}
			const result = await askQuestions(ctx, params.questions, signal, pi.getSettings().externalEditor);
			return {
				content: [{ type: "text", text: JSON.stringify(result) }],
				details: result,
			};
		},
		renderCall(args, theme) {
			const questions = Array.isArray(args.questions) ? args.questions : [];
			return new Text(theme.fg("toolTitle", theme.bold("Ask user")) +
				questions.map((q) => `\n${q.question ?? ""}`).join(""), 0, 0);
		},
		renderResult(result, _options, theme) {
			const details = result.details as Result | undefined;
			if (!details) return new Text("Question unavailable", 0, 0);
			const lines = details.answers.map((a) => `${theme.fg("muted", a.question)}\n${theme.fg("success", "✓ ")}${a.answer}`);
			if (details.cancelled) lines.push(theme.fg("warning", "Cancelled; unanswered questions were not answered."));
			return new Text(lines.join("\n"), 0, 0);
		},
	});
}
