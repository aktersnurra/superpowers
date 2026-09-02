import { readFileSync, readdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const EXTREMELY_IMPORTANT_MARKER = "<EXTREMELY_IMPORTANT>";
const BOOTSTRAP_MARKER = "superpowers:using-superpowers bootstrap for pi";
const CATALOG_REQUEST_MARKER = "superpowers:pi-skill-catalog-request";
const CATALOG_MARKER = "superpowers:skill-catalog for pi";

const extensionDir = dirname(fileURLToPath(import.meta.url));
const packageRoot = resolve(extensionDir, "../..");
const skillsDir = resolve(packageRoot, "skills");
const bootstrapSkillPath = resolve(skillsDir, "using-superpowers", "SKILL.md");

let cachedBootstrap: string | null | undefined;
let cachedCatalog: string | null | undefined;

export default function superpowersPiExtension(pi: ExtensionAPI) {
	let injectBootstrap = true;

	pi.on("resources_discover", async () => ({
		skillPaths: [skillsDir],
	}));

	pi.on("session_start", async () => {
		injectBootstrap = true;
	});

	pi.on("session_compact", async () => {
		injectBootstrap = true;
	});

	pi.on("agent_end", async () => {
		injectBootstrap = false;
	});

	pi.on("context", async (event) => {
		const catalogRequestIndex = event.messages.findIndex(messageContainsCatalogRequest);
		if (catalogRequestIndex >= 0 && !event.messages.some(messageContainsCatalog)) {
			const catalog = getCatalogContent();
			if (catalog) {
				const catalogMessage = {
					role: "user" as const,
					content: [{ type: "text" as const, text: catalog }],
					timestamp: Date.now(),
				};
				return {
					messages: [
						...event.messages.slice(0, catalogRequestIndex + 1),
						catalogMessage,
						...event.messages.slice(catalogRequestIndex + 1),
					],
				};
			}
		}

		if (!injectBootstrap) return;
		if (event.messages.some(messageContainsBootstrap)) return;

		const bootstrap = getBootstrapContent();
		if (!bootstrap) return;

		const bootstrapMessage = {
			role: "user" as const,
			content: [{ type: "text" as const, text: bootstrap }],
			timestamp: Date.now(),
		};

		const insertAt = firstNonCompactionSummaryIndex(event.messages);
		return {
			messages: [
				...event.messages.slice(0, insertAt),
				bootstrapMessage,
				...event.messages.slice(insertAt),
			],
		};
	});
}

function getBootstrapContent(): string | null {
	if (cachedBootstrap !== undefined) return cachedBootstrap;

	try {
		const skillContent = readFileSync(bootstrapSkillPath, "utf8");
		if (disableModelInvocation(skillContent)) {
			cachedBootstrap = null;
			return null;
		}
		const body = removeCatalogRequest(stripFrontmatter(skillContent));
		cachedBootstrap = `${EXTREMELY_IMPORTANT_MARKER}
${BOOTSTRAP_MARKER}

You have superpowers.

The using-superpowers skill content is included below and is already loaded for this Pi session. Follow it now. Do not try to load using-superpowers again.

${body}

${piToolMapping()}
</EXTREMELY_IMPORTANT>`;
		return cachedBootstrap;
	} catch {
		cachedBootstrap = null;
		return null;
	}
}

function getCatalogContent(): string | null {
	if (cachedCatalog !== undefined) return cachedCatalog;

	try {
		const entries = readdirSync(skillsDir, { withFileTypes: true })
			.filter((entry) => entry.isDirectory() && entry.name !== "using-superpowers")
			.map((entry) => skillCatalogEntry(resolve(skillsDir, entry.name, "SKILL.md")))
			.filter((entry): entry is string => entry !== null)
			.sort();
		cachedCatalog = `${CATALOG_MARKER}

## Available Superpowers skills

${entries.join("\n")}`;
		return cachedCatalog;
	} catch {
		cachedCatalog = null;
		return null;
	}
}

function skillCatalogEntry(skillPath: string): string | null {
	const content = readFileSync(skillPath, "utf8");
	const frontmatter = content.match(/^---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)/)?.[1];
	if (frontmatter === undefined) return null;

	const name = frontmatterValue(frontmatter, "name");
	const description = frontmatterValue(frontmatter, "description");
	if (name === undefined || description === undefined) return null;
	return `- **${name}** — ${description}`;
}

function frontmatterValue(frontmatter: string, key: string): string | undefined {
	const value = frontmatter.match(new RegExp(`^${key}:\\s*(.+?)\\s*$`, "m"))?.[1];
	return value?.replace(/^(?:"|')|(?:"|')$/g, "");
}

function disableModelInvocation(content: string): boolean {
	const frontmatter = content.match(/^---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)/)?.[1];
	return frontmatter !== undefined && /^disable-model-invocation\s*:\s*true(?:\s+#.*)?\s*$/m.test(frontmatter);
}

function removeCatalogRequest(content: string): string {
	return content.replace(`<!-- ${CATALOG_REQUEST_MARKER} -->`, "").trim();
}

function stripFrontmatter(content: string): string {
	const match = content.match(/^---\n[\s\S]*?\n---\n([\s\S]*)$/);
	return (match ? match[1] : content).trim();
}

function piToolMapping(): string {
	return `## Pi tool mapping

Pi has native skills but does not expose Claude Code's \`Skill\` tool. When a Superpowers instruction says to invoke a skill, use Pi's native skill system instead: load the relevant \`SKILL.md\` with \`read\` when the skill applies, or let a human invoke \`/skill:name\` explicitly.

Pi's built-in coding tools are lowercase: \`read\`, \`write\`, \`edit\`, \`bash\`, plus optional \`grep\`, \`find\`, and \`ls\`. Use those for the corresponding actions: read a file, create or edit files, run shell commands, search file contents, find files by name, and list directories.

Pi does not ship a standard subagent tool. If a subagent tool such as \`subagent\` from \`pi-subagents\` is available, use it for Superpowers subagent workflows. If no subagent tool is available, do the work in this session or explain the missing capability instead of inventing \`Task\` calls.

Pi does not ship a standard task-list tool. If an installed todo/task tool is available, use it. Otherwise track work in plan files or a repo-local \`TODO.md\` when task tracking is needed. Treat older \`TodoWrite\` references as this task-tracking action.`;
}

function messageContainsBootstrap(message: unknown): boolean {
	return messageContains(message, BOOTSTRAP_MARKER);
}

function messageContainsCatalogRequest(message: unknown): boolean {
	return messageContains(message, CATALOG_REQUEST_MARKER);
}

function messageContainsCatalog(message: unknown): boolean {
	return messageContains(message, CATALOG_MARKER);
}

function messageContains(message: unknown, marker: string): boolean {
	const content = (message as { content?: unknown }).content;
	if (typeof content === "string") return content.includes(marker);
	if (!Array.isArray(content)) return false;
	return content.some((part) => {
		return (
			part &&
			typeof part === "object" &&
			(part as { type?: unknown }).type === "text" &&
			typeof (part as { text?: unknown }).text === "string" &&
			(part as { text: string }).text.includes(marker)
		);
	});
}

function firstNonCompactionSummaryIndex(messages: unknown[]): number {
	let index = 0;
	while ((messages[index] as { role?: unknown } | undefined)?.role === "compactionSummary") {
		index += 1;
	}
	return index;
}
