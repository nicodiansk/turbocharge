---
paths:
  - "scripts/release.sh"
  - "scripts/directory-filter.sh"
  - "scripts/tests/t_release_tree.sh"
  - "scripts/tests/t_directory_copy.sh"
  - "CHANGELOG.md"
  - ".claude-plugin/plugin.json"
---

# Directory release

The detail of `.claude/CLAUDE.md` Publishing Flow step 5. The two rules for pushing `release` stay there, since they guard a push that can't be taken back.

The listing tracks a **`release`** branch, so merges to `master` don't create directory versions.

- The portal switched from `master` to `release` with 3.4.1. Change the tracked branch on its Settings tab only when no publish request is waiting, because changing it cancels a waiting publish request.
- To send a release to the directory: `bash scripts/release.sh vX.Y.Z --push` (repo scripts are mode 644; `core.filemode` is off). It builds a trimmed commit from the tag's plugin files (`.claude-plugin/`, `agents/`, `hooks/`, `skills/`, `templates/`, `workflows/`, README, LICENSE, NOTICE) and fast-forwards `release` to it; dev files (`.claude/`, which holds CLAUDE.md and this rule, CHANGELOG, `.github/`, `scripts/`, `evals/`, `images/`, `examples/`) never reach the directory, whose scan flags them. A new top-level path must be added to `SHIPPED` in `scripts/release.sh` or to `DEV_ONLY` in `t_release_tree.sh`. The webhook scans `release`, and once it passes you click **Publish update**.
- The directory copy differs from the tag in six ways. Every shipped markdown file goes through `scripts/directory-filter.sh`, which drops `<!-- repo-only -->` … `<!-- /repo-only -->` blocks and un-comments `<!-- directory-only` … `-->` blocks (hidden on GitHub). The whole `hooks/` directory, the review workflow and the debug skill's two code files (`find-polluter.sh`, `condition-based-waiting-example.ts`) are left out (`DIRECTORY_DROP`: the directory copy ships no hooks and no file outside the allowed types, and review runs one code-reviewer); the copy's NOTICE drops their lines. Every skill and agent loses the frontmatter keys in `DIRECTORY_STRIP_KEYS` (`memory`, `maxTurns`, `background`, `experimental`). The manifests drop `3 hooks` and `1 workflow`. Ship is user-only (`DIRECTORY_USER_ONLY`: release.sh puts `disable-model-invocation: true` in its frontmatter), as in 2.8.1 and 3.3.0; repo installs keep the ship Claude can start (`t_ship_menu.sh`).
- `DIRECTORY_DROP` also leaves out the atlas and wrap skills' three scripts (`atlas-symbols.sh`, `validate-atlas.sh`, `write-snapshot.sh`): they start with `#!`.
- In skills and agents, use repo-only blocks around text that holds only for repo installs, and reword shared text so it's true in both copies. Avoid directory-only blocks there: repo installs read the raw file, so Claude would see the directory's alternative text as a comment.
- Directory rules met so far, each as what the scan refuses → what we do:
  - UNREAD_ASSET_REFERENCED: shipped text that names a bundled image or font (`icon.png` in a file tree was enough) → no such text in shipped files.
  - RUNTIME_FETCH_EXEC: text that reads as fetching code and running it → the repo-marketplace install, CI note, project layout and `./scripts/…` commands sit in repo-only blocks (3.4.2).
  - MCP_FORWARDS_CREDENTIAL_ENV ("Uses a credential from the user's machine", held 3.4.0 to 3.5.6): a password-store command such as `pass` starting a segment after a parenthesis reads as a secret being read → reworded in 3.5.7.
  - LOCAL_CODE_NOT_CHECKED, then LOCAL_CODE_HOOK_COMMAND (3.5.7): command hooks only from a Verified organization. SessionStart takes only command and mcp_tool hooks, so the bootstrap can't become a prompt hook → the directory copy ships no hooks since 3.5.8.
  - LOCAL_CODE_FILE_TYPE (3.5.8): only Markdown, text, JSON, YAML and images; nothing starting with `#!`, no package manager configuration, UTF-8 with no NUL bytes → `DIRECTORY_DROP` (3.5.9).
  - LOCAL_CODE_FRONTMATTER_KEY (3.5.8, count 10 → 2 → 0): a skill or agent key, or a value under one, outside an unpublished list → `DIRECTORY_STRIP_KEYS` (3.5.9); since 3.5.11 plan dispatches the planner from the main session in both copies, so no skill has `context` or `agent`.
- Frontmatter the directory accepts from us (3.5.11 scan, no blocking finding): `name`, `description`, `tools`, `disallowedTools`, `model` (`sonnet`, `inherit`), `effort`, `argument-hint`, `disable-model-invocation`. Refused: `context`, `agent`, and most of `memory`, `maxTurns`, `background`, `experimental` (stripped together in 3.5.9; 8 of their 10 occurrences counted). Other authors saw `skills` on agents and `version`, `author`, `tags` on skills refused. `claude plugin validate --strict` checks no skill or agent frontmatter. A new key outside the accepted list goes into `DIRECTORY_STRIP_KEYS` until a scan accepts it.
- Before changing anything for a hold, read the report's `params`: the card shows only `.claude-plugin/plugin.json`, and the `ListPluginSubmissionVersions` response the Versions tab loads names the rule, the file and the match. 3.5.0 to 3.5.6 changed things on guesses and the hold stayed. A version held by policy is "not with Anthropic for review" (the portal shows "Waiting on you"). "Verified organization" is undocumented and can't be requested yet. Every version, passing ones included, waits for an Anthropic reviewer (the Overview's Auto-publish row), and a Publish click records a request for one.
- `release.sh` refuses a tree whose text names a bundled asset, pipes a download into a shell, keeps a marker, names a left-out file (by its name without the extension), reads as a password-store command, holds a `hooks.json` or a hook of type `command`, counts hooks, or still says `1 workflow`. It also refuses a file outside the allowed types, one that starts with `#!`, a package manager configuration, a text file with a NUL byte or not in UTF-8, a frontmatter key in `DIRECTORY_STRIP_KEYS`, and a `context` or `agent` key (`t_release_tree.sh`, `t_directory_copy.sh`). The CHANGELOG stays on GitHub; the README links to it by URL.
- Merges to `master` reach repo-marketplace installs (`turbocharge@turbocharge`) right away.
- The live directory version shows in `claude plugin list --available --json` under `turbocharge-nicodiansk`.
