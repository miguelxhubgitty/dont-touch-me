# Internal Development Journal — Don't Touch Me

**Audience:** project owner. Internal, detailed, source-grounded. Not public devlog content.

## Purpose
A living, readable explanation of every important part of the game, from player experience through implementation and release. Record *why* things work as they do, not just *what* changed. Make it possible to question any mechanic, formula, parameter, animation, edge case, test, or release decision with an exact source reference.

## Required sections to maintain
1. **Current snapshot:** version, Git branch and commit, what is live versus locally developed, verified facts and unverified claims.
2. **Player experience:** walkthrough from first launch; click/touch; idle, annoyance, relaxation, sleep, wake; all 15 normal reactions and the special reaction.
3. **Mechanic reference:** variables, defaults, thresholds, timers, random pools, weighting/repetition rules, state changes, interruption rules, recovery, resize/focus behavior, and edge cases. Source function/file references and worked examples.
4. **Animation and rendering:** geometry, transforms, drawing order, timing, hit detection, face/eye attachment, sleeping movement, aspect ratios, performance choices. Explain observations separately from confirmed root causes.
5. **Project anatomy:** Godot version, scene tree, scripts, exported resources, typography, platform configuration and reasons for separation.
6. **Testing:** suites, exact meaning and limitations of checks; smoke tests vs device tests; known defects and regression coverage.
7. **Distribution and operations:** per-format builds, release branching, aesthetic integration, artifact caches, itch.io, website, signing and approvals. Distinguish a draft, upload, live publication and verified availability.
8. **Decision history:** issue, alternatives, chosen solution, rationale, trade-offs, linked commits and what was deliberately deferred.
9. **Open questions and future ideas:** status [idea | planned | in progress | tested | shipped | rejected], priority, acceptance criteria, prerequisites; link to `plans/` and `GAME_ROADMAP.md`.
10. **Change-by-change entries:** date, scope, before/after user experience, technical reason, affected files/functions, tests run, risks, resulting commit, release destination.
11. **Glossary and question index:** explain all technical terms in accessible English and point common questions to exact sections.

## Editorial rules
- Explain in plain English first, technical detail second, examples third; be exhaustive but not repetitive.
- Source facts from the actual code, tests, and Git history. Never invent or infer exact values, implementation choices, or test results. Mark unknowns explicitly.
- Keep **planned** changes distinct from **implemented** and **published** work.
- Record failed attempts and unresolved bugs when relevant; do not quietly erase them.
- Use links to repository files, functions and commits. Do not copy secrets, tokens, private keys or confidential business information.
- Append meaningful dated entries rather than rewriting history; update the current reference sections when behavior actually changes.
- Public devlogs are **separate**. Their brief, dry, critical Butter Boy voice is not required here.

## Journal initialization status
**Scaffold only — comprehensive source audit pending.** This document defines the required standard, not an assertion that the game has already been fully documented. Populate each section by reading the actual source and release history before treating it as authoritative.
