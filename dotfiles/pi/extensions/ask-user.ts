import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import { askQuestions, type Result } from "./lib/questions.js";

const QuestionSchema = Type.Object({
	question: Type.String({ minLength: 1, description: "The question to display to the user." }),
	options: Type.Optional(Type.Array(Type.String({ minLength: 1 }), {
		maxItems: 8,
		description: "Suggested answers. A custom answer is always available. Omit for free-form input.",
	})),
});
const Params = Type.Object({ questions: Type.Array(QuestionSchema, { minItems: 1, maxItems: 8 }) });

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
			return { content: [{ type: "text", text: JSON.stringify(result) }], details: result };
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
