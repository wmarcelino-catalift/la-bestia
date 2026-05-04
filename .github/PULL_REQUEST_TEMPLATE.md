<!--
  Conventional Commits required. Title format: <type>(<scope>): <subject>
  See CONTRIBUTING.md for the full ritual.
-->

## What

<!-- One sentence: what changed. -->

## Why

<!-- Outcome / business effect. Reference an issue if there is one. -->

## How (high level)

<!-- 2-4 bullets. Mention modified hooks/agents/schemas. -->

## Verification

- [ ] `bash tests/run.sh all` passes locally
- [ ] `shellcheck` clean
- [ ] Schema validation passes
- [ ] CHANGELOG.md `[Unreleased]` section updated
- [ ] If new agent: route-prompt keywords added, eval canonical added
- [ ] If new hook: bats test added (and ran red before the hook existed)
- [ ] No Obsidian / vault references reintroduced
- [ ] No UI surfaces added (HTML, dashboards, image generation)

## One-way doors?

<!--
  If yes (changes that are hard to reverse — schema breakage, removing an agent, renaming a public file),
  link the ADR in memory/decisions/ and tag a reviewer explicitly.
-->

- [ ] None
- [ ] Yes — ADR: `memory/decisions/<NNNN>-<slug>.md`

## Migration impact

<!-- For breaking changes: what existing operators must do. -->
