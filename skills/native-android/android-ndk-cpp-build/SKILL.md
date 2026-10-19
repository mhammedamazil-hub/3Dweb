---
name: android-ndk-cpp-build
description: >
  Build and verify native C++ Android apps (NDK + CMake + Filament + Jolt) in this
  repo's split sandbox/CI environment. Use when touching CMakeLists.txt, the Kotlin
  NativeActivity/JNI bridge, APK assembly, 16 KB page alignment, ABI/STL/RTTI flags,
  fetching Filament or glTF assets, or when a build needs to run but the local machine
  has no JDK/Android SDK. Covers which steps run locally and which must run on GitHub
  Actions, and the specific link/flag traps that silently produce broken binaries.
---

# Native Android C++ build loop (this project)

## The one rule that matters

**This sandbox cannot build an APK.** There is no JDK, no `ANDROID_HOME`, no NDK, and
`dl.google.com`, `services.gradle.org`, `repo.maven.apache.org` and `deb.debian.org` are
all unreachable — nothing can be installed to change that. GitHub Actions runners
*are* reachable and are fully provisioned (Temurin 17, SDK platforms 34–37, build-tools,
NDK 27.3/29/30, cmake 3.31.6, ninja 1.13.2, `/dev/kvm`).

So: **author and test C++ locally; compile, link, install and profile on CI.** Never try
to make the sandbox produce an APK, and never claim a GPU behaviour is "verified" from
here — there is no GPU, no ICD and no `/dev/dri`.

| Task | Run locally | Run on CI |
| --- | --- | --- |
| Edit C++/CMake/GLSL | ✅ | — |
| Compile physics/engine as a **host** library, run headless asserts | ✅ (`cmake`/`ninja` from pip) | optional |
| `gltf-transform` inspect/optimize (except `toktx` steps) | ✅ | ✅ |
| `aapt`/`d8`/Gradle/`assembleDebug`, APK signing | ❌ | ✅ |
| Emulator boot, `adb install`, screencap | ❌ (no KVM) | ✅ |
| `simpleperf` / AGI / real fps | ❌ | ⚠️ CPU-side only; true numbers come from a device |

## Fetching dependencies: use the right host

- ✅ `codeload.github.com/<owner>/<repo>/tar.gz/refs/tags/<tag>` — source tarballs (this is how Jolt and Bullet were obtained).
- ✅ `git clone --depth 1 --filter=blob:none --sparse` + `git sparse-checkout set Models/X` — large asset repos, selectively.
- ❌ `https://github.com/<owner>/<repo>/releases/download/...` — **302 → `release-assets.githubusercontent.com`, which is blocked.** Filament's `filament-*-android-native.tgz` and the NDK zip cannot be fetched locally. Do it in CI (verified reachable there: `curl -sIL …/filament-v1.78.0-android-native.tgz` → 200).
- ❌ Maven/Gradle deps, `raw.githubusercontent.com`, `objects.githubusercontent.com`, Actions logs (`gh run view --log` → `EOF`).
- ✅ PyPI and npm ship real binaries: `pip install cmake ninja imageio-ffmpeg astc-encoder-py`, `npm i -g @gltf-transform/cli`.

## Reading CI results when logs are unreachable

Actions logs are blocked from here, so **CI must report through Git**:

```yaml
- run: { ./gradlew :app:assembleDebug; aapt dump badging app/build/outputs/apk/debug/*.apk; } > docs/build-report.md
- run: git add -f docs/build-report.md && git commit -m "ci: build report" && git push origin HEAD:$GITHUB_REF_NAME
```
then `git fetch origin <branch> && git show FETCH_HEAD:docs/build-report.md`. Always `mkdir -p` the directory first, and never `git add -A` from a scratch tree — a stray 90 MB `libJolt.a` will be happily pushed.

## Link traps that cost hours (all hit for real here)

1. **Bootstrap order is the whole game, and it fails silently.** Every Jolt entry point must be preceded by
   ```cpp
   JPH::RegisterDefaultAllocator();                       // MUST be first Jolt call
   JPH::Trace = MyTrace;  JPH_IF_ENABLE_ASSERTS(JPH::AssertFailed = MyAssert;)
   JPH::Factory::sInstance = new JPH::Factory();          // before RegisterTypes()
   JPH::RegisterTypes();
   ```
   Omit `RegisterDefaultAllocator()` and the process dies with a bare `SIGSEGV` — no message, no assert,
   before your first `printf`. I lost an hour to this in setup; a missing `Trace` callback does the same trick
   when an assert fires (the assert path then calls through a null pointer, so the *real* message is lost).
2. **Jolt's vehicle API changed in 5.x.** `WheeledVehicle`/`Vehicle` are gone. Assemble:
   `VehicleConstraintSettings{ mWheels: [WheelSettingsWV ×4], mController: WheeledVehicleControllerSettings{mEngine,mTransmission,mDifferentials}, mAntiRollBars }`
   → `new VehicleConstraint(chassisBody, settings)` → `SetVehicleCollisionTester(new VehicleCollisionTesterCastCylinder(layer, 0.05f))`
   → `physics.AddConstraint(vc)` **and** `physics.AddStepListener(vc)`.
3. **Init order is load-bearing:** `Factory::sInstance = new Factory();` *before* `RegisterTypes()`, and `UnregisterTypes()` *before* deleting the factory. Reversed, it segfaults.
4. **`PhysicsSystem::Init` in 5.x needs three filter objects** (`BroadPhaseLayerInterface`, `ObjectVsBroadPhaseLayerFilter`, `ObjectLayerPairFilter`) — older `SetLayerPairFilterTable` calls do not exist. The interfaces are pure virtual: if you build with asserts on, expect `GetBroadPhaseLayerName` to be required too.
5. **Flag matching.** Jolt's own targets compile with `-fno-rtti -fno-exceptions -flto=auto -fno-fat-lto-objects` plus `-mavx2 -mfma -mf16c -mpopcnt -mlzcnt`, and exports `-DJPH_*` options. An app target that compiles the same headers with a different set is an ODR/ABI violation that surfaces as a crash in `Factory`/`RegisterTypes` — *before* your code runs, with no message. On arm64, `JPH_USE_NEON`/`JPH_ENABLE_ASSERTS` must match too. Prefer inheriting the imported `Jolt::Jolt` CMake target over hand-written flag lists. Note that **matching every flag still will not save a missing `RegisterDefaultAllocator()`** — I verified that LTO/IPO, `-fno-rtti -fno-exceptions`, the full `-DJPH_*` set, and static-vs-shared linking were all *not* the cause, so do not go hunting there first.
6. **Release vs Debug Jolt are not interchangeable** (`NDEBUG`, `JPH_FLOATING_POINT_EXCEPTIONS_ENABLED`, `JPH_ENABLE_ASSERTS`). Never mix a Debug `.a` with a Release app.

## Android-specific settings that are not optional

```cmake
# arm64 only unless a 32-bit tier is explicitly wanted
set(CMAKE_OABI_HOOKS off)
target_compile_options(app PRIVATE -fno-rtti -fno-exceptions)      # match Jolt
target_link_options(app PRIVATE -Wl,-z,max-page-size=16384)        # Android 15 / Play 16 KB rule
```
```kotlin
ndkVersion = "27.3.13750724"                    // pin; r30 drifts
android { packaging { jniLibs.useLegacyPackaging = false } }
```
```xml
<application android:extractNativeLibs="false" android:hardwareAccelerated="true">
<activity … android:configChanges="orientation|screenSize|keyboardHidden"> <!-- NativeActivity must handle these -->
```
Verify 16 KB alignment in CI, do not trust it:
`objdump -p lib/arm64-v8a/libapp.so | grep -i 'LOAD' | awk '{print $NF}'` → every `align` must be ≥ `2**14`.

## Frame loop / input notes (Filament on Android)

- `ASource` + `AChoreographer` for vsync; drive `SimpleAnimation`/`Engine.render` from the choreographer callback, not a `while(true)` thread.
- Fixed-step simulation (120 Hz) with render interpolation; never feed `deltaTime` straight into the solver.
- Read touch state in `AInputEvent` callbacks on the looper thread and publish atomically to the sim thread.
- Prefer the Vulkan `SwapChain`; keep a GLES 3.2 tier as a runtime switch rather than a build variant.
- Frame pacing: `SwapChainFlags::ALLOW_PROTECTED` off, `FrameRateRange(min, target, max)` to ask for 60/90/120 where the panel supports it, and back off on `ThermalStatus` changes.

## Pre-flight checklist

```bash
export PATH=/usr/local/bin:$PATH
cmake --version | head -1        # 4.4.4 (pip) — host checks only
ninja --version                  # 1.13.2
gltf-transform --version         # 4.5.1 — asset pipeline
command -v javac || echo "OK: no JDK expected; APK build happens on CI"
ls /dev/kvm 2>/dev/null || echo "OK: no KVM; emulator is CI-only"
```
If a step here says "run on CI", run it on CI. A locally "passing" native build is not
evidence the APK works, and a green CI build is not evidence the game runs well — the
device is.
