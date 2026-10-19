#!/usr/bin/env bash
# Reproduce the Phase-1 environment audit from docs/SETUP-REPORT.md §2.
# Read-only; safe to run anywhere. Expects ~2 min (network timeouts dominate).
set -u
echo "== host =="; uname -srm; nproc; free -h | head -2; df -h / | tail -1
echo; echo "== toolchains =="
for c in gcc g++ clang cmake ninja make java javac gradle adb sdkmanager ndk-build blender git gh python3 pip3 node npm; do
  printf "  %-12s " "$c"; command -v $c >/dev/null 2>&1 && ($c --version 2>&1 | head -1) || echo MISSING
done
echo; echo "== android/graphics prerequisites =="
echo "  ANDROID_HOME=${ANDROID_HOME:-unset}  JAVA_HOME=${JAVA_HOME:-unset}"
echo "  /dev/kvm: $([ -e /dev/kvm ] && echo present || echo 'absent -> emulator impossible locally')"
echo "  GPU/ICD : '$(ls /dev/dri 2>/dev/null | tr '\n' ' ')' (empty -> no rendering here)"
echo "  GL libs : $(ldconfig -p 2>/dev/null | grep -c -E 'libGL|libEGL|vulkan') found"
echo; echo "== egress (allowlist: github.com, codeload, api.github, npmjs, pypi) =="
probe(){ # prints HTTP code; a truncated-but-200 transfer still counts as reachable
  local code; code=$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 6 --max-time 18 "$1" 2>/dev/null)
  [ -z "$code" ] || [ "$code" = "000" ] && code="BLOCKED"
  printf "  %-28s %s\n" "$2" "$code"; }
probe https://github.com/google/filament github.com
probe https://api.github.com/rate_limit api.github.com
probe https://codeload.github.com/google/filament/tar.gz/refs/heads/main codeload.github.com
probe https://registry.npmjs.org/gltf-transform registry.npmjs.org
probe https://pypi.org/simple/numpy/ pypi.org
probe https://dl.google.com/android/repository/repository2-3.xml dl.google.com
probe https://services.gradle.org/distributions/ services.gradle.org
probe https://repo.maven.apache.org/maven2/ maven-central
probe https://raw.githubusercontent.com/git/git/master/README.md raw.githubusercontent.com
echo; echo "== repo state =="
git -C "$(dirname "$0")/.." log --oneline -1
echo "  (expect: APK builds happen on CI only; see docs/SETUP-REPORT.md sections 5-7)"
