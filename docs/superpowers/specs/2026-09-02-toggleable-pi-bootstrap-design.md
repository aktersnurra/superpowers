# Toggleable Pi Bootstrap Design

## Problem

Pi's `using-superpowers` bootstrap is injected by `.pi/extensions/superpowers.ts` without checking the skill's `disable-model-invocation` frontmatter. As a result, setting the skill to Manual through `pi-skill-visibility` still places its full description in model context.

## Goal

The Pi bootstrap must follow the same visibility rule as all other skills:

- Startup: inject the bootstrap automatically.
- Manual: do not inject it automatically; explicit `/skill:using-superpowers` remains available.

## Design

The Superpowers Pi extension will read the `disable-model-invocation` frontmatter value from `skills/using-superpowers/SKILL.md` before constructing its bootstrap message.

- When the value is `true`, `getBootstrapContent()` returns `null`; the existing `context` handler does not insert a message.
- When the field is absent or `false`, the extension preserves current bootstrap behavior.
- Visibility is checked before cache population so a reload after `/toggle-skills` uses the newly written setting.

This reuses Pi's standard skill visibility mechanism and does not couple Superpowers to the `pi-skill-visibility` registry or extension lifecycle.

## Tests

Extend the Pi extension tests to verify:

1. a visible `using-superpowers` skill injects the bootstrap;
2. `disable-model-invocation: true` prevents injection; and
3. an explicit invocation remains Pi-native behavior rather than an extension concern.

## Scope

Only the Pi bootstrap extension and its focused tests change. No skill content, registry format, or unrelated harness integration changes.
