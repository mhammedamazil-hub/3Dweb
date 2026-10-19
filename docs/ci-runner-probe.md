<!-- Captured 2026-10-19 from GitHub Actions run 39204565763 (branch arena/probe-check, since deleted) on ubuntu-latest. Reproduce: push a workflow that writes this file and commits it back; Actions logs are not downloadable from the sandbox. -->
# GitHub Actions runner probe (auto-generated)
generated: 2026-10-19T05:26:38Z

## host
Linux runnervm8k3b6 6.17.0-1022-azure #22-Ubuntu SMP Mon Jul 27 17:24:03 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux
4
               total        used        free      shared  buff/cache   available
Mem:            15Gi       1.4Gi        11Gi        42Mi       3.2Gi        14Gi
/dev/root       145G   60G   86G  42% /
kvm: /dev/kvm

## java
openjdk version "17.0.20.1" 2026-08-18
OpenJDK Runtime Environment Temurin-17.0.20.1+1 (build 17.0.20.1+1)
OpenJDK 64-Bit Server VM Temurin-17.0.20.1+1 (build 17.0.20.1+1, mixed mode, sharing)

## ANDROID_HOME=/usr/local/lib/android/sdk
build-tools
cmake
cmdline-tools
extras
licenses
ndk
packages-list.txt
platform-tools
platforms
platforms: android-34 android-34-ext10 android-34-ext11 android-34-ext12 android-34-ext8 android-35 android-35-ext14 android-35-ext15 android-36 android-36-ext18 android-36-ext19 android-36.1 android-37.0 android-37.1 android-37.2 android-37.2-beta1 android-37.2-beta2 android-37.2-beta3 
build-tools: 34.0.0 35.0.0 35.0.1 36.0.0 36.1.0 37.0.0 
ndk: 27.3.13750724 29.0.14206865 30.0.16248370   ndk-bundle: 
cmdline-tools: latest 

## cmake/ninja/gradle
cmake version 3.31.6
1.13.2

Here are the highlights of this release:
 - Java 27 support
 - Maven mirror settings reuse
 - Linked problem locations in build output


## network reachability from runner
https://dl.google.com/android/repository/repository2-3.xml -> 200
https://services.gradle.org/distributions/ -> 200
https://repo.maven.apache.org/maven2/ -> 200
https://github.com -> 200
https://objects.githubusercontent.com -> 404

## Filament prebuilt Android native tgz (release asset) reachable?
filament release asset HEAD -> 200 size=0

## disk cost of an NDK install (dry check)
12G	/usr/local/lib/android/sdk
