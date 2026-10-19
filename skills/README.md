# Agent Skills (vendored)

Skills here are plain Markdown instruction packs (the Agent Skills format) vendored into the
repo so the build environment can stay offline and provenance stays auditable. Nothing in this
directory is executable-on-install; scripts inside a skill are only run when a task calls for
them. Each directory keeps its upstream `LICENSE`.

Installed during pre-development setup on 2026-10-19. Verified: every `SKILL.md` has frontmatter
with `name` + `description`, and every file was read before acceptance.

| Group | Skills | Upstream | Commit | License |
| --- | --- | --- | --- | --- |
| `game-dev/` | physics-tuning, shader-programming, camera-systems, performance-optimization, input-systems, game-feel, create-game-assets | `gamedev-skills/awesome-gamedev-agent-skills` | `0a70cfc64672d512c5b5b6006b5dcb5cf90dbdbd` | Apache-2.0 |
| `android/` | android-gradle-logic, gradle-build-performance, android-testing | `new-silvermoon/awesome-android-agent-skills` | `82900eacc8dbe13de93c6310af27b9df4b2bd2f6` | Apache-2.0 |
| `methodology/` | systematic-debugging, verification-before-completion, test-driven-development | `obra/superpowers` | `bb92a77741419a4ab5f06e711a283343f1ada0c3` | MIT |
| `native-android/` | android-ndk-cpp-build | authored in-repo for this project | — | CC0-1.0 |

Deliberately **not** installed (and why): see `docs/SETUP-REPORT.md` §3.2 — engine-specific packs
(Godot/Unity/Unreal/Roblox/Phaser/PixiJS) would teach the wrong API for a custom Filament + Jolt
native build; `anthropics/skills` contains no C++/NDK/graphics material; multi-agent "game studio"
frameworks add process, not capability; Blender/Unity MCP skills need editors that cannot be
installed here.

## Refreshing a skill

```bash
# source tarballs are reachable; GitHub release assets are not
curl -sLO https://codeload.github.com/<owner>/<repo>/tar.gz/refs/heads/main
tar xzf main.tar.gz
rsync -a --delete <repo>-main/skills/disciplines/<name>/ skills/game-dev/<name>/   # keep LICENSE
```
Re-check the upstream commit after every refresh and update the table above.

## Not present
No Agent Reach skill or any other pre-existing skill was found in this environment
(no `SKILL.md` on the filesystem, no `~/.claude/skills`, no `.arena/skills`), so nothing could
be reused. See `docs/SETUP-REPORT.md` §3.
