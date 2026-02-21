# chip-8-web

WebAssembly frontend for the CHIP-8 emulator, compiled with SwiftWasm + JavaScriptKit.

## Build

Requires Swift 6.0+ and the matching SwiftWasm SDK installed.

```bash
# Install WASM SDK (must match your Swift version)
swift sdk install https://github.com/swiftwasm/swift/releases/download/swift-wasm-6.0.2-RELEASE/swift-wasm-6.0.2-RELEASE-wasm32-unknown-wasi.artifactbundle.zip

# Build
swift package --swift-sdk 6.0.2-RELEASE-wasm32-unknown-wasi js
```

Output goes to `.build/plugins/PackageToJS/outputs/Package/`. Serve over HTTP (not `file://`).

## Architecture

SPM executable target depending on `Chip8EmulatorPackage` and `JavaScriptKit`.

- **Sources/main.swift** — entry point: canvas rendering, keyboard mapping, ROM loading, game loop
- **Resources/index.html** — HTML page with `<canvas>`, ROM picker, keyboard guide
- **Resources/roms/** — 25 bundled .ch8 ROM files

### How it works

1. `WebDelegate` implements `Chip8EngineDelegate`: renders pixels via Canvas 2D `fillRect()`, beeps via Web Audio API
2. Keyboard maps QWERTY keys to CHIP-8 keypad (1234/QWER/ASDF/ZXCV)
3. ROMs load via `<select>` dropdown (fetched with JS `fetch()`) or `<input type="file">`
4. Game loop uses `requestAnimationFrame` with 10 `engine.tick()` calls per frame (~600Hz at 60fps)

## Local Development

For local development, change `Package.swift` dependency to use a local path:
```swift
.package(path: "../Chip8EmulatorPackage"),
```
CI uses the URL-based dependency pointing at the GitHub repo.

## Deployment

Hosted on AWS Amplify (manual deploy mode — no repo connection).

- **URL:** https://swift-chip8.fallibledev.com
- **Amplify app ID:** `d33c39pddjzsdk` (region `eu-west-2`)
- **Pattern:** GitHub Actions builds WASM → pushes pre-built artifacts to Amplify via `create-deployment` API
- **Why manual deploy:** Amplify's build environment doesn't have Swift/SwiftWasm, so we build in CI and push artifacts

On push to `main`, the workflow zips `.build/plugins/PackageToJS/outputs/Package/` and deploys it. PRs only build (no deploy).

### Future: Mobile support

CHIP-8 input maps to a QWERTY keyboard (1234/QWER/ASDF/ZXCV → hex keypad). Touch input for mobile devices is not yet implemented.

## Workflow

- Branch protection on `main`: PR required, `build` CI check required, enforce admins
- CI: `.github/workflows/build.yml` — SwiftWasm build on Ubuntu, deploy to Amplify on main

### PR flow

1. Commit to a feature branch
2. Push and create PR
3. Set PR to auto-merge (`gh pr merge --auto --squash`)
4. CI must pass before merge completes
