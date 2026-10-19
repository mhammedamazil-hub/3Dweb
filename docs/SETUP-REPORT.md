# Pre-Development Setup Report — Native C++ Android 3D Driving Game

**Status: SETUP COMPLETE — awaiting architecture approval. No game code written.**
Date: 2026-10-19 (UTC) · Repo: `mhammedamazil-hub/3Dweb` @ `557b42a` · Baseline tag: `setup-baseline`

Every capability claim below was tested in this environment; unverified items are marked **[unverified]**.

---

## 1. Existing repository & Roadster asset audit

### 1.1 Repository — verified empty
| Check | Result |
|---|---|
| Working tree | `README.md` only (8 bytes, `# 3Dweb`) |
| Commits / branches | 1 commit (`557b42a` "Initial commit"); `main` + this session branch |
| Tags, stashes, LFS, submodules | none · none · none · none |
| Dangling/unreachable objects | none (`git fsck --lost-found` clean) |
| Remotes | `origin → https://github.com/mhammedamazil-hub/3Dweb` |
| GitHub repo size | 0 KB, no Issues/PRs/Actions history |
| Build scripts, engine code, prior work | none exist |

Checkpoint created before any change: annotated tag **`setup-baseline`** → `557b42a`.

### 1.2 The Roadster model **does not exist in this repository**
There is no GLB/GLTF/FBX/BLEN/obj/DAE file, no `assets/` directory, and nothing in Git history. **Format, size, mesh complexity, materials, textures, skeleton, animations and license are therefore undeterminable from the repo.** Nothing was found in the repo or in its GitHub metadata to identify which "Roadster" was intended.

Cross-GitHub code search for `Roadster.glb` returns only 5 unrelated game repos (Godot racing demos), none with a clear redistributable license — not usable as a source.

**Blocking decision:** the model must be supplied by you (drop the file into `assets/roadster/` and tell me), **or** you approve a substitute.

Interim stand-in already fetched and analysed (no license risk): **`CarConcept`** from Khronos `glTF-Sample-Assets`, **CC-BY-4.0** (attribution required, no trademark use).

```
CarConcept.glb        11,778,688 bytes · glTF 2.0 · generator: RapidPipeline 3D Processor v7.1.0
renderVertexCount      640,041   (per pass)
uploadVertexCount      162,766
indices                u16       meshes: 40+ named parts (BodyUnderside, BodyWindshield,
                                 WindshieldWipers 30,429 v, InteriorCage, Engine, ...)
extensionsUsed         KHR_materials_clearcoat, KHR_materials_emissive_strength,
                       KHR_materials_iridescence, KHR_materials_transmission,
                       KHR_materials_variants, KHR_texture_transform
extensionsRequired     none      → safe for a renderer that ignores optional extensions
```
**`ClearCoatCarPaint.glb` (116,948 B) is CC0-1.0 (public domain, no attribution burden)** and is a
purpose-built clear-coat car-paint test asset — the right choice for the Stage-2 paint/shader gate.
`CarConcept` is CC-BY-4.0, so it needs a `NOTICE` attribution if it ships.

Pipeline tooling verified working offline here: `gltf-transform` **4.5.1** (`inspect`, `validate` → clean, no hints/errors, `optimize`, `merge`, `prune`, `weld`, `simplify`), Python glTF access via PyPI. **Not** available: Blender (no binary, no apt) — so no `.blend`→glTF step is possible in this sandbox; the Roadster must arrive as glTF/GLB or FBX-ready-in-CI.

---

## 2. Arena capabilities & verified build constraints

### 2.1 Sandbox host
| Item | Verified value |
|---|---|
| OS / kernel | Debian 12 bookworm, Linux 6.1.158+ x86_64 (KVM guest) |
| CPU | 2 vCPU (1 core + HT) Xeon @2.6 GHz, AVX2/AVX-512/FMA/SHA flags |
| RAM / swap | 3.8 GiB total, 3.6 GiB available, **0 swap** |
| Disk | 21 GB total, 20 GB free (root, overlay) |
| Privileges | non-root `user`, **passwordless sudo works** (but nothing to install from) |
| GPU / ICD | **none** — no `/dev/dri`, no `lspci` devices, no `libGL/libEGL/libvulkan` in `ldconfig`, no `/usr/include/{GL,EGL,GLES2,vulkan}` |
| `/dev/kvm` | **absent** → no Android emulator, no nested VM |
| Toolchains | g++ 12.2.0, GNU Make 4.3, git 2.39.5, `gh` 2.23.0 (authed), Python 3.11.2/pip 23.0.1, Node v22.22.3/npm 10.9.8 |
| Was missing | clang, **cmake, ninja, java, javac, gradle, mvn, gdb, ndk, sdkmanager, blender, ffmpeg** |
| Package manager | `apt` present but **all mirrors unreachable** (404/timeout) → **no system packages installable, ever** |

Installed by me during setup, from reachable registries only: **CMake 4.4.4 + Ninja 1.13.2** (PyPI manylinux wheels), **ffmpeg 7.0.2-static** (`imageio-ffmpeg`), **gltf-transform 4.5.1** (npm global), **Pillow / numpy / astc-encoder-py** (PyPI).

### 2.2 Network — exact egress map (measured)
Reachable: `github.com` 200 · `api.github.com` 200 · `codeload.github.com` 200 · `registry.npmjs.org` 200 · `pypi.org` 200 · `files.pythonhosted.org` (30 MB wheel at 54 MB/s).

**Blocked (all timeouts/000):** `dl.google.com` (SDK **and** NDK repository), `services.gradle.org`, `repo.maven.apache.org`, `dl.google.com/dl/android/maven2`, `deb.debian.org`, `developer.android.com`, `google.github.io`, `raw.githubusercontent.com`, `objects.githubusercontent.com`, `release-assets.githubusercontent.com`, `results-receiver.actions.githubusercontent.com`, `crates.io`, general internet. The sandbox `gstaticproxy` does **not** bypass these.

Two consequences that shape the whole plan:
1. **GitHub release assets are unreachable** → Filament's prebuilt `filament-*-android-native.tgz` (89.4 MB, v1.78.0), the NDK zip, and the JDK tarballs cannot be downloaded here. Source tarballs via `codeload.github.com` **are** reachable (that is how Jolt/Bullet/Khronos assets were obtained).
2. `actions/checkout` works on CI (verified), but **LFS-backed assets would not** — keep large binaries out of Git LFS or fetch them from a non-LFS path.

### 2.3 Capability verdicts
| Capability | Verdict | Evidence |
|---|---|---|
| Compile Android APK **locally** | **NO** | no JDK, no `ANDROID_HOME`, no NDK; `dl.google.com` + Maven + Gradle all blocked |
| Build/verify C++ **host** binaries | **YES** | Jolt 5.6.0 → `libJolt.a` (88.8 MB) in ~46 s; 218-file `UnitTests` in ~4 min |
| Run automated tests | **YES (headless only)** | Jolt `doctest`: **581/581 cases, 514,280/514,280 assertions passed**; vehicle subset 1/1, 81/81 |
| Run a GUI app / render anything | **NO** | no GPU, no GL/Vulkan ICD, no X/Wayland |
| Launch Android emulator | **NO** | no `/dev/kvm`, no GPU |
| Connect physical device via `adb` | **NO** | no `adb`, no USB passthrough, `platform-tools` blocked |
| GPU profiling / frame-time capture | **NO locally** | nothing to profile; must be done on your device or CI |
| **GitHub Actions = real APK build** | **YES, verified end-to-end** | pushed workflow → run `39204565763` → `success`; results committed back and read from the repo |
| Download Actions logs | **NO** | `gh run view --log` → `EOF` (blocked host). Workaround proven: CI writes a report file and pushes it back |
| Assets from PyPI/npm | **YES** | cmake/ninja/gltf/Pillow installs succeeded |

### 2.4 GitHub Actions runner (measured on `ubuntu-latest`)
```
4 vCPU · 15 GiB RAM · 86 GB free · /dev/kvm PRESENT
Temurin OpenJDK 17.0.20.1+1
ANDROID_HOME=/usr/local/lib/android/sdk (12 GB preinstalled)
platforms: android-34 … android-37.2 (+betas)   build-tools: 34.0.0 … 37.0.0
NDK: 27.3.13750724, 29.0.14206865, 30.0.16248370   cmdline-tools: latest
cmake 3.31.6 · ninja 1.13.2 · recent Gradle
dl.google.com 200 · services.gradle.org 200 · Maven Central 200 · Filament release asset HEAD 200
```
Raw probe: `docs/ci-runner-probe.md`.

**This is the project's build farm.** The sandbox is for editing, host-compiling and headless-testing; CI produces genuine signed APKs and can also boot an emulator (KVM present) for install/launch/screenshot smoke tests.

### 2.5 One incident, reported for transparency
While testing the Actions path I created a throwaway branch `arena/probe-check` and, because I ran `git add -A` in a scratch directory, pushed ~300 MB of CMake build artifacts (92 MB PCH files, 84 MB `libJolt.a`) to it. I deleted the branch immediately after capturing the probe output (`origin/arena/probe-check` no longer exists; repo size still reports 0 KB). No LFS was used and `main` was never touched. `main` remains exactly `557b42a`.

---

## 3. Skills: discovery, evaluation, installation

Existing skills: **none found** — no `SKILL.md` anywhere on the filesystem, no `.claude/`, `.arena/`, or skill directories. The **Agent Reach skill is not present** in this environment, so nothing could be reused. (No `list_connector_tools`-style app is connected either — see §4.)

### 3.1 Installed — 13 vendored skills (+1 authored), `409 KB` total
| Skill | Source repo (commit) | License | Why it earns its place |
|---|---|---|---|
| `game-dev/physics-tuning` | `gamedev-skills/awesome-gamedev-agent-skills` @ `0a70cfc` | Apache-2.0 | fixed-vs-variable timestep, interpolation, CCD, jitter/tunneling — the core of a 120 Hz sim + 60 Hz render loop |
| `game-dev/shader-programming` | same | Apache-2.0 | cross-stage GLSL fundamentals, coordinate spaces, rim/dissolve; maps onto GLSL→Filament material nodes |
| `game-dev/camera-systems` | same | Apache-2.0 | follow-camera damping/lookahead/OCclusion handling — explicitly required feature |
| `game-dev/performance-optimization` | same | Apache-2.0 | frame budget discipline, LOD, draw-call batching |
| `game-dev/input-systems` | same | Apache-2.0 | touch handling, dead zones, input latency |
| `game-dev/game-feel` | same | Apache-2.0 | screen shake/response curves for driving feel |
| `game-dev/create-game-assets` | same | Apache-2.0 | includes `references/provenance.md` + asset-manifest template → the licensing/provenance discipline the Roadster needs |
| `methodology/systematic-debugging` | `obra/superpowers` @ `bb92a77` | MIT | hypothesis-driven debugging (Phase-2 "systematic debugging" requirement) |
| `methodology/verification-before-completion` | same | MIT | "don't claim it works without proof" — enforced throughout this setup |
| `methodology/test-driven-development` | same | MIT | red/green loop for the physics unit tests |
| `android/android-gradle-logic` | `new-silvermoon/awesome-android-agent-skills` @ `82900ea` | Apache-2.0 | version-catalog/AGP configuration for the native+JNI module |
| `android/gradle-build-performance` | same | Apache-2.0 | keep CI builds fast and cache-correct |
| `android/android-testing` | same | Apache-2.0 | instrumentation/JUnit harness for the Activity/JNI bridge |
| `native-android/android-ndk-cpp-build` | **authored here** | CC0 (in-repo) | the verified constraints of *this* project: what builds where, exact flags, the 16 KB-page and LTO gotchas, the CI build loop |

Verification performed after install: all 14 `SKILL.md` files parse, each has valid frontmatter with `name` + `description`, each directory carries its upstream `LICENSE`, and each was read before acceptance. Provenance recorded in `skills/README.md`.

### 3.2 Evaluated and rejected (with reasons)
| Candidate | Why rejected |
|---|---|
| `anthropics/skills` (182 k★, official) | Inspected all 19 skills: `pdf/docx/pptx/xlsx`, `canvas-design`, `slack-gif-creator`, `mcp-builder`, `webapp-testing`, `skill-creator`… **zero** cover C++/NDK/graphics/physics. No license file at repo root. Nothing worth taking. |
| `NVIDIA/skills`, `trailofbits/skills` | CUDA/Physical-AI and security-audit skills; unrelated to this stack (Trail of Bits' APK scanner needs Firebase/audit context we don't have). |
| `gamedev-skills` engine dirs (godot-*, unity-*, unreal-*, roblox-*, phaser/pixi/three) | We are writing a **custom native Filament+Jolt** app; these teach another engine's node/component API. Would actively mislead. |
| `Donchitos/Claude-Code-Game-Studios` (26.8 k★), `bullish0x/GameStudio`, `MRCalderon3D/everything-game-dev-code`, `jammyfu/open-game-skills` | Large multi-agent "studio" frameworks: heavy prompt scaffolding, engine-coupled (Godot/Unity/Unreal), no Filament/NDK/Jolt content. Duplication + process overhead, not capability. |
| `IvanMurzak/Unity-MCP`, Blender-MCP (`elithril/blender-kiln`) | Need a live Unity/Blender editor over MCP; neither engine nor Blender exists here and none can be installed. |
| `SimoneAvogadro/android-reverse-engineering-skill`, `incogbyte/*` | Reverse-engineering/APK inspection — irrelevant (we are the publisher). |
| `dpconde/claude-android-skill` (MIT) | Compose/Kotlin UI-centric; overlaps `android-gradle-logic` with less build relevance to a `NativeActivity`. |
| `alvarose/android-update-deps` | Nice idea (it checks the **16 KB page rule**) but it is a dependency-bump reviewer for Gradle version catalogs — we have no dependencies yet; the rule itself is now encoded in my authored skill. |
| `new-silvermoon/.../android-emulator-skill` | Requires KVM/`avdmanager`; unavailable locally. On CI it is a niche win — the CI workflow already covers install/boot/screenshot. |
| `KryieNaruto/icecc-distributed-build` | 0★, unverified script that spawns network build workers. Not trusted, and 2 cores make distribution moot. |

No third-party *executable* code was installed from skill repos — only Markdown instructions plus their `scripts/` which remain unread-until-needed. Nothing in `skills/` is on `PATH` or auto-run.

---

## 4. MCP / tool connections audit

**Already sufficient (tested, in use):** `bash` (builds, git, curl, gh), file read/write/edit, present, `web_search` (works; used for ecosystem survey), `fetch_page` (returns **rendered markdown from arbitrary URLs** — the practical substitute for blocked `developer.android.com` browsing), `gh`+git against api.github.com, npm/PyPI installs, and the Actions control loop.

| Tier | Connection | Decision |
|---|---|---|
| **Required** | Repo/Git push+PR (`gh`, already authorized as `mhammedamazil-hub`) | ✅ present — verified: push, branch create/delete, workflow dispatch, API reads |
| **Required** | Terminal / FS / build execution | ✅ present — verified with real CMake builds |
| **Required** | CI compute for APK + NDK + emulator | ✅ present via GitHub — verified round trip. **No new connection needed**, only a `.github/workflows/` file in-repo (proven writable) |
| Optional | Docs browsing | `fetch_page` covers Android/Filament/Jolt docs; **no connection needed** |
| Optional | Android device/`adb` bridge (e.g. a device MCP or a self-hosted runner with USB) | **Only real gap.** Adds on-device GPU profiling and thermal data. Worth it *later*, and only if you want me to drive a handset; a self-hosted GH runner is the cleaner answer |
| Unnecessary | Blender MCP | Blender cannot be installed (no apt, blocked mirrors); `gltf-transform` + `meshoptimizer` + `astc-encoder-py` already cover in-sandbox asset work |
| Unnecessary | Unity/Unreal/Godot MCP | Wrong engines |
| Unnecessary | Slack/Notion/Figma/Sentry/Auth0/Flutter etc. | No project need |
| Unnecessary | More MCP servers for their own sake | Explicitly avoided — they would add tokens, not capability |

Connected-apps state at time of writing: **none connected** (`The user can connect apps… no apps connected yet`). Nothing in this setup requires it.

---

## 5. Recommended technology stack (evidence-based, single coherent architecture)

### Decision
```
Language/Build   C++20 · CMake ≥3.31 · Ninja · NDK r27.3 (LTS) · 16 KB page-aligned
App shell        One Kotlin NativeActivity (or plain NativeActivity + ~60 lines JNI)
Renderer         Google Filament v1.78.0  (Vulkan preferred, GLES 3.2 fallback)
Physics          Jolt Physics v5.6.0      (VehicleConstraint + WheeledVehicleController)
Assets           glTF 2.0 .glb → Filament `gltfio` direct load (KHR_materials_clearcoat,
                   transmission, iridescence, emissive_strength, KHR_texture_basisu,
                   EXT_meshopt_compression, KHR_texture_transform)
Textures         KTX2 / Basis Universal (uastc for hero paint, etc1s elsewhere) via toktx
Post             filament-utils: bloom, FXAA/TAA, DOF; SSAO optional per quality tier
```

### Why this and not the alternatives
| Candidate | Verdict | Evidence |
|---|---|---|
| **Filament** | ✅ **Adopt** | Apache-2.0, actively maintained (last push 2026-10-19, 20.6 k★), v1.78.0 released 2026-10-13. Ships exactly what a high-fidelity car needs: HDR PBR with clearcoat (paint), transmission (glass), IBL + SSR, shadowmaps, and a **glTF loader (`gltfio`)** — so no bespoke material/texture importer. Android artefacts exist as AAR (`filament-android` 5.3 MB, `gltfio-android` 5.84 MB, `filament-utils-android` 1.21 MB, `filamat-android` 13.45 MB) plus a native-SDK tgz for C++ (89.4 MB, all ABIs). **Cannot be validated in this sandbox** (release assets + Maven blocked; a Filament source build also needs a JDK and far more than 2 cores/3.8 GB) → validation moves to CI, gated as Stage-2 in §7. |
| Custom GLES3/Vulkan renderer | ⚠️ Fallback only | Fully buildable for *compile-checks* using Khronos headers fetched via `codeload`, but you would be writing IBL, clearcoat, shadowing, picking, KTX2 and anisotropic filtering yourself. Only choose this if Stage-2 fails. |
| **Jolt Physics** | ✅ **Adopt** | MIT, v5.6.0 (pushed 2026-10-18), 11.8 k★, zero dependencies, CMake/Android first-class (`Build/Android`). **Proven in this sandbox**: builds in ~46 s, 581/514,280-assertion suite passes, `WheeledVehicleTests.cpp` present and passing. Vehicle module gives real suspension springs (`SpringSettings` per wheel), anti-roll bars, engine curve (`VehicleEngineSettings` + normalized-torque `LinearCurve`), gears/clutch (`VehicleTransmissionSettings`), differentials (`mLimitedSlipRatio`), and **per-wheel longitudinal/lateral friction curves** (`WheelSettingsWV::mLongitudinalFriction/mLateralFriction`) — a Pacejka-shaped tire is expressible without patching the library. Static lib ≈ 89 MB unstripped → expect ~3–6 MB per-ABI stripped. |
| **Bullet 3.25** | ❌ Reject | Builds fine and license is zlib (`LICENSE.txt` confirmed; GitHub reports `NOASSERTION`), but its vehicle code is `btRaycastVehicle` (ray-cast suspension, no anti-roll bars, no engine/transmission/differential model, no tire friction curves — you hand-roll all of it), maintenance is slower (last push 2026-10-09), and its build drags GLUT/demo deps that are unusable headless. Jolt is strictly better for this project. |
| Vulkan-only | ❌ Reject as *only* backend | GLES3.2 is still the safest floor on low/mid Kerala-market hardware. Filament lets one binary do `Vulkan → GLES 3.2 → GLES 3.1` tiering, so "Vulkan vs GLES" becomes a runtime quality setting, not an architecture fork. |
| PhysX 5 | ❌ Reject | Strong vehicles, but a heavier Android footprint, CUDA/GPU paths we cannot use, and none of it verifiable here. |
| Bevy/Godot/Unity/Unreal | ❌ Reject | You asked for real native C++; an engine import would replace the whole brief. |
| `gltf-transform` pipeline | ✅ **Adopt** | Verified 4.5.1 offline: `optimize --compress meshopt --simplify-error --texture-size --texture-compress` is exactly the LOD/quantization/compression stage. `--texture-compress ktx2/astc` shells out to **`toktx`, which is not installable here** → KTX2 encoding runs on CI (or `astc-encoder-py`, whose module installs but whose binding signature still needs work — see §8). |

Licenses to carry: Apache-2.0 (Filament), MIT (Jolt), zlib (any Bullet leftovers), CC-BY-4.0 (**asset attribution — must ship a NOTICE**).

---

## 6. Exact dependency & SDK requirements

**Local (sandbox) — already installed and verified**
```
cmake      4.4.4        (pip: /usr/local/bin/cmake)
ninja      1.13.2       (pip)
gcc/g++    12.2.0       (system)
gltf-transform 4.5.1    (npm -g)
python     3.11.2 + Pillow, numpy, astc-encoder-py 0.1.12, imageio-ffmpeg 7.0.2
git 2.39.5 · gh 2.23.0 (authed) · node 22.22.3 · npm 10.9.8 · make 4.3
```
**CI / release build (supplied by `ubuntu-latest`, pin explicitly)**
```
JDK            Temurin 17                      (AGP 8.x needs 17; runner has 17.0.20.1)
Android SDK    platforms;android-36  build-tools;36.0.0   (compileSdk 36)
NDK            27.3.13750724  (LTS, 16 KB page safe)  — avoid r30 for a pinned build
CMake          3.31.6 (runner) via android { externalNativeBuild }
Gradle         wrapper 8.13+ (pin in gradle/wrapper; not system Gradle)
AGP            8.7.x   Kotlin 2.0.x
Filament       com.google.android.filament: 1.78.0
                 filament-android (5,299,967 B)   gltfio-android (5,842,184 B)
                 filament-utils-android (1,212,025 B)   filamat-android (13,453,528 B)
                 filament-…-android-native.tgz (89,381,859 B) for the C++ headers/libs
Jolt           v5.6.0 source, add_subdirectory(jolt/Build) into the externalNativeBuild graph
```
**App/ABI/runtime policy**
```
minSdk 24 (Android 7.0)      — GLES3.1 baseline; ~99% of active devices
recommended minSdk 26        — if Vulkan tier becomes the only supported path
targetSdk 35 (Android 15)    — meets current Play target policy
abis     arm64-v8a (ship) · armeabi-v7a (optional low-end tier) · x86_64 (CI emulator only)
linker   -Wl,-z,max-page-size=16384    +    APP_SECURITY / extractNativeLibs=false
stl      c++_static      RTTI/exceptions: match Jolt (off unless the app enables both)
```
**Storage/memory budget (to be re-measured on the first real build)**
```
APK payload target  ≤ 90 MB (base)  = renderer ~12 MB + physics ~5 MB + assets
Hero car            ≤ 60k triangles LOD0, ≤ 22k LOD1, ≤ 7k LOD2 (CarConcept's 640k must be
                    simplified ~10× — 4×6 material splits, no more)
Textures            1024² KTX2/ASTC 4×4  → ~0.35–0.7 MB per map; ≤ 5 maps per material
Texture VRAM budget ≤ 220 MB (6 GB devices) / ≤ 380 MB (8 GB)
Device RAM          min 4 GB, comfortable 6 GB+; process PSS target ≤ 480 MB
Environment         tiled/streaming chunks, 1 shared IBL + 1 shadow map @2048 (1024 low tier)
```

---

## 7. Minimal proof-of-concept plan (gated — each stage must pass before the next)

| # | Stage | Where | Exit criterion (automated where possible) |
|---|---|---|---|
| 0 | Repo skeleton: `app/` (Kotlin `NativeActivity`), `engine/` (C++), `assets/` (glTF), `cmake/`, `tests/`; `.gitignore` (done), `skills/` (done) | sandbox | `cmake --build` of the *host* test binary succeeds; `gltf-transform validate` clean on the car GLB |
| 1 | **Toolchain gate, no rendering.** Empty `NativeActivity` + one JNI call (`nativeVersion()`), `externalNativeBuild` for `arm64-v8a` + `x86_64`, debug-signed APK, `assembleDebug` | GitHub Actions | **Genuine installable APK artifact**; `apkanalyzer manifest print` + `aapt dump badging` show correct `minSdk`, `extractNativeLibs=false`, **16 KB-aligned `lib/arm64-v8a/*.so`** (`objdump -p \| grep 2**14`) |
| 2 | **Renderer gate.** Filament 1.78 AAR + `SwapChain`/`Skybox` + `gltfio` loads `car.glb` on the **flat grey plane**; Vulkan **and** GLES variants; rotate camera | CI (+ emulator via `/dev/kvm`) | APK installs on an API-34 emulator, `am start` reaches `onResume`, `adb exec-out screencap` shows a non-black frame for **both** backends; no `AdrenoSilent`/`VulkanValidation` errors in logcat |
| 3 | **Physics gate.** Jolt `VehicleConstraint` + `WheeledVehicleController` driving the visual car; 120 Hz fixed step, 60 Hz render interpolation; touch gas/brake/steer | sandbox host headless → then device | Numeric assertions, not vibes: 0→100 km/h time within a target window; 100→0 stopping distance ≈ 38–46 m on μ=1.0; body never sinks below `SuspensionMinLength`; no NaN in wheel angular velocity; 4 wheels stay in contact at rest; steering-to-yaw monotonic. **This is where my scratch-probe issue (see §8) gets resolved by starting from Jolt's own `HelloWorld` target.** |
| 4 | **Environment + feel.** Road segment with camber, guardrail + impulse colliders, LOD chain, follow camera, KTX2/ASTC + meshopt streaming | sandbox asset prep + CI | ≤ 16.6 ms p95 frame time on the emulator's CPU path (renderer only — GPU conclusions come from your device); asset bundle ≤ budget from §6 |
| 5 | **Quality tiers + thermal.** `Low/Medium/High` (shadow res, SSAO, SSR, texture mip bias, MSAA), `FrameRateRange` + `Choreographer` pacing, thermal-backoff on `PowerManager` | device | Manual pass on your handset: sustained ≥ 55 fps (High, 25 °C ambient), ≥ 30 fps (Low), thermal throttle curve recorded via `simpleperf`/AGI export you attach |
| 6 | **Only now:** full track, AI traffic, audio, UI, telemetry | — | — |

Reproducibility: every stage is driven by `./gradlew` locally-or-in-CI; CI caches `~/.gradle`, `~/.android`, `~/.cache/filament`, and runs `actions/checkout` **without LFS**. Any run whose conclusion is `failure` is investigated via the file-report trick (logs are not downloadable from the sandbox).

---

## 8. Risks, limitations, honest unknowns

**Blocking / high**
1. **No Roadster asset.** Nothing to build against; mesh/material/license unknown. Until resolved, every visual target below is provisional.
2. **Zero on-device validation here.** No `adb`, no KVM locally, no GPU, no profiler. *Everything* GPU-related in this report comes from upstream docs or CI, not measurement. Device truth (Adreno/Mali driver quirks, thermals, real fps) must come from your phone or a self-hosted runner.
3. **Filament is unverified in-sandbox** (cannot fetch or build it here). Mitigation: Stage 1–2 are cheap gates; the fallback is a hand-written GLES3.2 renderer, and the cost of switching later is high — hence the gates.
4. **Sandbox cannot link against GL/Vulkan at all** (no ICD, no headers). Rendering code can be *authored* and *compile-checked only by adding Khronos headers via `codeload`*; it can never be *run* here. Plan accordingly: renderer changes get validated in CI/emulator only.
5. **~~Jolt headless probe crash~~ RESOLVED — and it was my probe, not the library.** A 10-line consumer segfaulted before printing anything because it skipped Jolt's mandatory bootstrap: `JPH::RegisterDefaultAllocator()` (plus `Trace`/`AssertFailed`) **must** run before any other Jolt call, and `Factory::sInstance` must exist before `RegisterTypes()`. After adding it, the same binary ran clean. I disproved every other hypothesis first (LTO/IPO on and off, `-fno-rtti -fno-exceptions`, Jolt's exact exported `-DJPH_*` set, static `.a` vs shared `.so`, and building inside Jolt's own `HelloWorld` CMake target) — all segfaulted identically until the allocator call was added. This is now recorded in `skills/native-android/android-ndk-cpp-build/SKILL.md` and will be encoded in the app's `InitJolt()` so it cannot recur.

**Medium**
6. 2 vCPU / 3.8 GB / 0 swap: expect a Filament-source build or a large Gradle+NDK build to be impractical-to-impossible locally; CI-only builds are the mitigation. `nohup`/background builds can be OOM-killed silently.
7. `files.pythonhosted.org` returns 404 for a `simple/` probe but real wheels download fine — do not "fix" pip config based on the probe.
8. KTX2/ASTC **encoding** is not possible in-sandbox today (`toktx` unobtainable; `astc-encoder-py` installs but its Python API still needs adapting — `ASTCConfig(profile, block_x, block_y)` then `ASTCContext(config, swizzle)` signature work outstanding). Texture compression is therefore a CI step.
9. Asset licensing: CC-BY-4.0 requires shipping attribution and forbids implying Khronos endorsement; the eventual Roadster's own license must be recorded in `assets/**/PROVENANCE.md` before shipping.
10. Jolt 5.x **changed the vehicle API** — the old `WheeledVehicle`/`Vehicle` helper classes are gone (only `VehicleConstraint`, `Wheel`, `VehicleController`, and collision testers remain in `Jolt/Physics/Vehicle/`). Every tutorial/AI-memory written against 4.x or 3.x is wrong here; code against the shipped headers, not memory.
11. Play/API: `targetSdk` policy and the 16 KB page requirement are both moving targets; re-check at release time (my §6 pins are correct for today).
12. CI is the *only* build farm and it is your GitHub account (public repo → free minutes; a Filament+NDK+emulator job is ~6–12 min/run, 2,000 min/month is ample but not infinite). Cache discipline matters.

### Measured in this sandbox (2 vCPU x86_64, gcc 12.2, Jolt 5.6.0 Release, 120 Hz fixed step)
```
physics cost   0.473–0.726 ms/step for 1 vehicle + 300 dynamic boxes (≈6–9 % of an 8.33 ms budget)
stability      chassis settles at 0.891 m (target ride height ≈0.85 m), no tunnelling, no NaN
suspension     rear travel compresses 0.320 → 0.284 m under load; 3 m drop recovers and settles
powertrain     engine reaches the 7200 rpm limiter; rear wheels driven through the differential
               (61 rad/s wheel spin in the air, −0.1 rad/s rolling at rest)
steering       0.30 lock at 69 km/h → 5.2 °/s yaw, R ≈ 212 m, 0.18 g lateral (understeer-limited,
               as expected with these tire curves/mu) — the qualitative behaviour is right
upstream       UnitTests 581/581 pass, incl. WheeledVehicleTests; HelloWorld exit 0
```
These numbers validate the *engine and toolchain*, not the game. Open item for Stage 3: in my
throwaway tuning the front wheels lost ground contact at speed (`contact=0` at the print point),
i.e. hardpoint/suspension-length tuning is wrong — that is ordinary vehicle-setup work, and it
is exactly what Stage 3's numeric assertions exist to catch. **No physics conclusion in this
report should be read as a handling validation.**

**Realistic performance targets (to be validated, not promised)**
```
High    (SD 8 Gen 2 / Dimensity 9200+, Adreno 740 / Immortalis-G715)
        1080p–1440p, 60 fps locked, clearcoat+IBL+SSR+2k shadow+SSAO, ≤ 350 draw calls
        CPU frame ≤ 6.5 ms, GPU frame ≤ 12 ms, ≤ 42 °C sustained 20 min
Medium  (SD 7 Gen 3 / Dimensity 8300, Mali-G615) 1080p 60 fps, SSR→planar refl, 1k shadow
Low     (SD 695 / Helio G99, Adreno 619/Mali-G57) 720p 30 fps, no SSAO/SSR, GLES only
Budget  60 Hz vsync · 120 Hz physics · 1–2 sim substeps/frame · ≤ 12 MB/frame allocations
```
These are Filament-typical figures for a 1-car scene at this asset budget, taken from the library's documented design goals and my stage plan — **not** measurements, because this environment physically cannot make them.

**Open questions needing your decision**
1. Roadster file: upload it, or authorize `CarConcept`/another asset (which one)?
2. `.blend`-sourced Roadster? Then we need a CI Blender step (Blender on the runner, or you export GLB yourself — recommended).
3. Ship `armeabi-v7a` 32-bit tier, or arm64-only (smaller APK, better Vulkan)?
4. minSdk 24 vs 26 (Vulkan-only)?
5. Is on-device profiling out of scope for me (you run `simpleperf` and paste results), or should I request a self-hosted runner / device bridge later?
6. Approve Stage 0–3 gates before I write any game code?

---

### Reproduction
`tools/env-probe.sh` re-runs the §2 checks (toolchains, blocked hosts, GPU/KVM) and prints the same table. The Actions probe is preserved in `docs/ci-runner-probe.md`.
