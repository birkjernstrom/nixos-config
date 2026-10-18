import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { createRequire } from "node:module";
import { setTimeout } from "node:timers/promises";
import { resolve } from "node:path";
import { test } from "node:test";

const root = resolve(process.argv[2]);
const require = createRequire(`${root}/package.json`);
const { createJiti } = require("jiti");
const jiti = createJiti(import.meta.url, {
	alias: {
		"@earendil-works/pi-coding-agent": `${root}/dist/index.js`,
		"@earendil-works/pi-tui": require.resolve("@earendil-works/pi-tui"),
		typebox: require.resolve("typebox"),
	},
});
const { default: extension } = await jiti.import("../extensions/ask-user.ts");
const { KeybindingsManager } = await import(`${root}/dist/core/keybindings.js`);
const { initTheme } = await import(`${root}/dist/modes/interactive/theme/theme.js`);
initTheme("dark");
const { visibleWidth } = await import(require.resolve("@earendil-works/pi-tui"));
const { Compile } = await import(require.resolve("typebox/compile"));
let tool;
const commands = new Map();
let settings = {};
extension({
	registerTool(value) { tool = value; },
	registerCommand(name, value) { commands.set(name, value); },
	getSettings() { return settings; },
});

const keybindings = new KeybindingsManager();
const tui = {
	requestRender() {},
	terminal: { rows: 40, columns: 100 },
};
const theme = { fg: (_color, text) => text, bold: (text) => text };

async function execute(questions, interactions, signal) {
	let calls = 0;
	const ctx = {
		mode: "tui",
		ui: {
			async custom(factory) {
				let result;
				let complete = false;
				const component = factory(tui, theme, keybindings, (value) => {
					result = value;
					complete = true;
				});
				component.focused = true;
				await interactions[calls++](component);
				assert.ok(complete, "dialog should complete");
				component.dispose();
				return result;
			},
		},
	};
	const result = await tool.execute("test", { questions }, signal, undefined, ctx);
	return { result, calls };
}

function checkWidths(component) {
	for (const width of [1, 10, 40, 100]) {
		component.invalidate();
		for (const line of component.render(width)) assert.ok(visibleWidth(line) <= width);
	}
}

test("registers the tool, sequential execution, and guidance without slash commands", () => {
	assert.equal(tool.name, "ask_user");
	assert.equal(tool.executionMode, "sequential");
	assert.ok(tool.promptGuidelines.length);
	assert.equal(commands.size, 0);
	const schema = Compile(tool.parameters);
	assert.ok(schema.Check({ questions: [{ question: "Why?" }] }));
	assert.ok(!schema.Check({ questions: [] }));
	assert.ok(!schema.Check({ questions: [{ question: "" }] }));
});

test("selects a suggested answer and renders at narrow widths", async () => {
	const { result } = await execute([{ question: "Pick 界", options: ["One", "Two"] }], [
		(component) => {
			checkWidths(component);
			component.handleInput("\x1b[B");
			component.handleInput("\r");
		},
	]);
	assert.deepEqual(result.details, { answers: [{ question: "Pick 界", answer: "Two", custom: false }], cancelled: false });
});

test("j/k navigate and wrap around the choices", async () => {
	const { result } = await execute([{ question: "Pick", options: ["One", "Two"] }], [
		(component) => {
			component.handleInput("k");
			assert.match(component.render(100).join("\n"), /› 3\. Write my own answer/);
			component.handleInput("j");
			assert.match(component.render(100).join("\n"), /› 1\. One/);
			component.handleInput("j");
			component.handleInput("\r");
		},
	]);
	assert.equal(result.details.answers[0].answer, "Two");
});

test("j/k are normal letters while writing an answer", async () => {
	const { result } = await execute([{ question: "Pick", options: ["One"] }], [
		(component) => {
			component.handleInput("\t");
			component.handleInput("j");
			component.handleInput("k");
			component.handleInput("\r");
		},
	]);
	assert.equal(result.details.answers[0].answer, "jk");
});

test("supports custom text, back navigation, and preserved drafts", async () => {
	const { result } = await execute([{ question: "Pick", options: ["One"] }], [
		(component) => {
			component.handleInput("\t");
			component.handleInput("My answer");
			checkWidths(component);
			component.handleInput("\x1b");
			component.handleInput("\t");
			component.handleInput("\r");
		},
	]);
	assert.equal(result.details.answers[0].answer, "My answer");
	assert.equal(result.details.answers[0].custom, true);
});

test("free-form questions reject blank submission", async () => {
	const { result } = await execute([{ question: "Anything else?" }], [
		(component) => {
			component.handleInput("\r");
			component.handleInput("Details");
			component.handleInput("\r");
		},
	]);
	assert.equal(result.details.answers[0].answer, "Details");
});

test("cancelling later questions preserves earlier answers without inventing the rest", async () => {
	const { result, calls } = await execute([
		{ question: "First?", options: ["Yes"] },
		{ question: "Second?" },
		{ question: "Third?" },
	], [
		(component) => component.handleInput("\r"),
		(component) => component.handleInput("\x1b"),
	]);
	assert.equal(calls, 2);
	assert.equal(result.details.cancelled, true);
	assert.equal(result.details.answers.length, 1);
});

test("abort dismisses the active panel", async () => {
	const controller = new AbortController();
	const { result } = await execute([{ question: "Waiting?" }], [() => controller.abort()], controller.signal);
	assert.equal(result.details.cancelled, true);
});

test("already-aborted requests open no panels", async () => {
	const { result, calls } = await execute([{ question: "Waiting?" }], [], AbortSignal.abort());
	assert.equal(calls, 0);
	assert.equal(result.details.cancelled, true);
});

test("external editor receives the selected answer and returns edits without submitting", async () => {
	const directory = mkdtempSync(`${tmpdir()}/pi-ask-test-`);
	const script = `${directory}/editor.mjs`;
	writeFileSync(script, 'import { readFileSync, writeFileSync } from "node:fs"; const file = process.argv[2]; writeFileSync(file, readFileSync(file, "utf8") + " edited\\n");');
	const previousEditor = process.env.EDITOR;
	const previousVisual = process.env.VISUAL;
	try {
		for (const configured of [true, false]) {
			const command = `${process.execPath} ${script}`;
			settings = configured ? { externalEditor: command } : {};
			process.env.EDITOR = command;
			delete process.env.VISUAL;
			let stopped = false;
			let restarted = false;
			tui.stop = () => { stopped = true; };
			tui.start = () => { restarted = true; };
			const { result } = await execute([{ question: "Pick", options: ["One"] }], [
				async (component) => {
					component.handleInput("\u0007");
					assert.ok(stopped);
					for (let i = 0; !restarted && i < 100; i++) await setTimeout(10);
					assert.ok(restarted, "TUI should restart after the editor exits");
					component.handleInput("\r");
				},
			]);
			assert.equal(result.details.answers[0].answer, "One edited");
		}
	} finally {
		settings = {};
		if (previousEditor === undefined) delete process.env.EDITOR;
		else process.env.EDITOR = previousEditor;
		if (previousVisual === undefined) delete process.env.VISUAL;
		else process.env.VISUAL = previousVisual;
		rmSync(directory, { recursive: true, force: true });
	}
});

test("non-TUI execution returns a clear fallback", async () => {
	const result = await tool.execute("test", { questions: [{ question: "Why?" }] }, undefined, undefined, { mode: "print" });
	assert.equal(result.isError, true);
	assert.match(result.content[0].text, /plain text/);
});
