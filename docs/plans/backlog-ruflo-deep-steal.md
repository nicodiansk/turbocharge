# Backlog — Ruflo Deep Steal & Improve

**Status:** Backlog (not in current session scope)
**Trigger:** When user clones `ruvnet/ruflo` locally inside this repo and invokes `/turbocharge:brainstorm` on it.

## Intent

Ruflo's README is the best-in-class pitch for a Claude Code orchestration tool right now. Its structural and copy DNA is worth extracting systematically — not just the parts already lifted in the v2.3.0 scaffold. The goal is to **steal what works and improve what doesn't**, positioning turbocharge as the disciplined-pipeline counter to ruflo's amplification pitch.

## Patterns Already Noted (from initial scan)

- Three-word product category + italicized elaboration under the banner
- Origin story in a quote block (personal, named creator, "feels inevitable")
- Capability-led framing ("100+ Specialized Agents") not feature-led
- Reassurance paragraph right after the architecture flex ("you don't need to learn 310+ tools")
- With/Without table inverted as "Claude Code Alone" vs "Claude Code + Ruflo" (product framed as upgrade to existing tool)
- Heavy `<details>` usage for deep content — keeps hero lean
- Emoji-led capability bullets (7 of them, each one-liner)
- Named sub-systems (SONA, RuVector, Hive Mind) as proper nouns — builds mythology

## Patterns To Evaluate (during deep brainstorm)

- Whether a "Getting into the Flow" style pun section fits turbocharge's voice
- Whether to name sub-systems as proper nouns (e.g. "the Review Chain" as a capital-T Thing)
- Whether architecture mermaid diagram upfront is a flex or a wall
- How much of the mythology / personal-origin framing lands without sounding cargo-culted

## What To Improve On (where ruflo is weak)

- Ruflo's README is LONG and front-loads architecture before pain. A reader who doesn't already feel agent sprawl won't finish.
- Capability bullets mix user value and implementation detail ("Works With Any LLM" vs "ONNX Runtime, MiniLM").
- The "feels inevitable" origin is charming but borders on self-mythology. Turbocharge should feel honest, not legendary.
- No clear "start here if you're new" path — ruflo trusts the reader to synthesize. Turbocharge should make the first move obvious.

## When To Trigger

User will clone ruflo into this repo (likely `./ruflo/` or a sibling ref dir), then run `/turbocharge:brainstorm` referencing this backlog doc. Expected output: a concrete lift-and-improve checklist feeding a README rewrite task.

## Related

- Current positioning brainstorm: `docs/plans/2026-04-13-positioning-design.md` (in progress this session)
- v2.3.0 scaffold already lifted: hero → why → install → pipeline → with/without → what-you-get → iron laws → collapsible deep-dives
