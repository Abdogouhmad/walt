# Walt: UI Modernization, OTA + Versioning, and Release CI — Ported from Brewline

**Audience:** opencode coding agent, working in the `walt` repository
**Reference implementation:** `~/Desktop/brewline` — a separate Flutter project (a café POS app) that already has working, battle-tested versions of everything asked for here. **Inspect the actual code there before implementing anything in this doc** — this spec describes *which* patterns to port and *why*, but the real implementation details (exact widget structure, exact CI YAML) live in that repo, not here. Treat this document as the map, not the territory.
**Target app:** Walt — a privacy-first Android expense tracker (Flutter, Material Design 3, Riverpod, SQLite/Hive, `fl_chart`, biometric auth, Gemma-based AI insights, Google Pay notification interception). **Android-only** — this changes how several Brewline patterns port over; see the callouts below.
**Status:** Ready for implementation.

---

## 0. How to Use This Document

Brewline and Walt are different apps with different purposes — don't port Brewline's café-specific *business logic* (there's no PIN keypad, no printer, no refunds, no shifts in an expense tracker). What's actually worth porting is the **design system** and the **release engineering** — things that are genuinely app-agnostic and where Brewline's implementation has already had real design/engineering effort put into it. Three things, matching the three items in the linked GitHub issue:

1. **UI modernity/simplicity** → Brewline's design system (§1)
2. **Functionality improvement** → an in-app OTA update system with real versioning/changelog discipline (§2–3)
3. **CI for GitHub releases** → a release workflow building arm64/armv7/universal APKs with changelog-sourced release notes (§4)

---

## 1. UI: Port the Design System, Not the Screens

### 1.1 What to port
- **Dynamic color.** If Walt isn't already using `dynamic_color` (Material You) — check first — adopt it the same way Brewline does: `DynamicColorBuilder` at the app root, a `ColorScheme.fromSeed(seedColor: kBrandSeedColor)` fallback for devices/OS versions without dynamic color support, and **zero hardcoded hex values anywhere else in the app.** This is Brewline's single most consistently-applied rule and the one most worth strictly enforcing here too.
- **Corner radii:** 28dp on cards, sheets, and dialogs; 16dp on fields, buttons, and smaller containers. Audit Walt's existing screens for whatever radii are currently in use and normalize to these two values.
- **Spacing system:** a small `AppSpacing` constants class (`xs`/`sm`/`md`/`lg`/`xl` at 4/8/16/24/32dp) used everywhere instead of arbitrary per-screen `EdgeInsets` values — copy this file's shape directly from Brewline's `core/design/spacing.dart`.
- **Motion:** tactile scale/fill transitions (150–200ms) on state changes, not instant snaps — matches what Brewline calls "M3 Expressive" throughout.
- **Consistent empty/loading/error states:** one visual treatment for "no expenses yet," one for "loading," one for a failed AI-insight fetch — reused everywhere those states occur, rather than each screen inventing its own.

### 1.2 What's simpler here because Walt is Android-only
Brewline splits every action sheet between a desktop dialog and a mobile bottom sheet, driven by a `Breakpoints`/`ScreenSize` utility, because it targets phones, tablets, *and* desktops. **Walt doesn't need any of that** — there's exactly one form factor. Port the *visual shape* of Brewline's action sheets (28dp rounded top corners, draggable, consistent content layout) as a single always-bottom-sheet component, and skip building any responsive-breakpoint infrastructure entirely. Don't introduce `Breakpoints.of(context)`-style code here — it would be unused complexity for an app that only ever runs on one form factor.

### 1.3 Badge/status consistency
Brewline consolidated several independently-specced badges ("Refunded," "Low stock," "Beta") into one shared `StatusBadge` widget with semantic variants (`info`/`warning`/`error`/`success`) mapped to `colorScheme` container pairs. Walt has its own equivalent candidates worth the same treatment — spending-category tags, an AI-insight confidence/freshness indicator, an "update available" badge (§3) — build one shared badge component for these rather than a bespoke one per feature.

### 1.4 What NOT to port
Anything specific to Brewline being a point-of-sale system: the PIN keypad, printer settings/transport abstraction, shift/cashout/refund concepts, the multi-role login model. None of that has an analog in a single-user expense tracker — don't import it just because it's well-built in the reference repo.

---

## 2. Versioning & Changelog — the Foundation Both OTA and CI Depend On

Get this right first; both §3 and §4 read from it.

- **Semantic versioning** (`MAJOR.MINOR.PATCH`) in `pubspec.yaml`'s `version:` field, as Walt's human-facing version string.
- **A deterministic Android `versionCode`** derived from that semver string via a fixed formula (e.g. `major * 10000 + minor * 100 + patch`), rather than an independently-tracked incrementing counter — this guarantees the version code and version name can never drift out of sync with each other, and CI never has to remember external state between runs.
- **`CHANGELOG.md` in [Keep a Changelog](https://keepachangelog.com) format** as the **single authoritative source** for release notes — every release's entry here becomes, unedited, both the GitHub Release body *and* the in-app OTA changelog text (§3). Don't hand-write release notes a second time anywhere else; that's exactly the kind of duplication that drifts out of sync over a few releases.

---

## 3. OTA Update System (Android-only subset of Brewline's plan)

Brewline's full OTA plan covers Android, Windows, and Linux with a platform-handler abstraction — Walt only needs the Android piece of it, which is meaningfully simpler.

### 3.1 ⚠️ Same signing-key risk as Brewline — read this first
Every release APK must be signed with the same stable release keystore, forever. If the signature ever changes between versions, Android forces an uninstall before it'll install the "update," which wipes Walt's local database — a user's entire expense history and AI-insight data gone in what looks to them like a normal update. Generate one release keystore now if one doesn't already exist, store it outside the repo, back it up in at least two places, and wire it into the Android build config permanently.

### 3.2 Manifest
One small JSON file, hosted free on GitHub (a release asset or a raw repo file) — same shape as Brewline's, minus the multi-platform sections Walt doesn't need:
```json
{
  "latestVersionCode": 42,
  "latestVersionName": "2.3.0",
  "minSupportedVersionCode": 30,
  "mandatory": false,
  "releaseNotes": "<the matching CHANGELOG.md section, injected by CI — see §4>",
  "apkUrl": "https://github.com/<you>/walt/releases/download/v2.3.0/walt-universal-v2.3.0.apk",
  "sha256": "<sha256 of that exact apk>",
  "publishedAt": "2026-09-19T00:00:00Z"
}
```
- Compare `latestVersionCode` against `PackageInfo.buildNumber`, same integer comparison Brewline uses for its Android path.
- `minSupportedVersionCode`/`mandatory` work exactly as in Brewline: an escape hatch for a release with a genuinely breaking data/security issue, shown as a non-dismissible full-screen block rather than the normal dismissible update prompt.

### 3.3 Which APK does the in-app updater fetch?
CI builds three APK variants (§4): `armeabi-v7a`, `arm64-v8a`, and a universal fat APK. **Recommendation: the in-app OTA updater always downloads the universal APK**, not a per-ABI one. Detecting the running device's ABI and picking the matching smaller file is a real feature (needs `device_info_plus` or similar, plus manifest entries per ABI) for a marginal download-size benefit at Walt's scale — not worth the added complexity for v1. The per-ABI APKs still get built and published as GitHub Release assets, for anyone who wants to manually download a smaller file directly from GitHub — they're just not part of the automated in-app path. Revisit only if download size becomes an actual complaint.

### 3.4 Mechanics
Same as Brewline's Android path: `ota_update` (or a current equivalent — verify it's still maintained before locking it in) downloads the APK, verifies the `sha256` from the manifest before anything is installed, and hands off to Android's `PackageInstaller`. Requires `REQUEST_INSTALL_PACKAGES` in the manifest; Android will prompt once per device to allow installs from this app.

### 3.5 UI placement
Same shape as Brewline's Settings-page update section: current version shown, a manual "Check for Updates" action, an optional auto-check toggle, a "last checked" timestamp, and the update prompt rendered through the bottom-sheet component from §1.2 (not a dialog — no desktop branch needed here).

---

## 4. CI: GitHub Actions Release Workflow

### 4.1 Trigger
On a version tag push (e.g. `v2.3.0`) — matches Brewline's release-automation approach.

### 4.2 Build three artifacts, restricted to the two ABIs actually requested
```
flutter build apk --release --split-per-abi --target-platform android-arm,android-arm64
flutter build apk --release --target-platform android-arm,android-arm64
```
- The first command produces two separate, smaller APKs: `app-armeabi-v7a-release.apk` (armv7) and `app-arm64-v8a-release.apk` (armv8).
- The second (no `--split-per-abi`) produces the universal fat APK containing both ABIs — this is the one §3.3 has the in-app updater fetch.
- Restricting `--target-platform` to just these two ABIs (rather than the Flutter default, which also includes `x86_64`) keeps all three artifacts smaller and matches exactly what was asked for — don't build an x86_64 variant nobody requested.

### 4.3 Checksums
Compute SHA-256 for all three APKs — needed for the manifest (§3.2) and worth publishing alongside the release assets regardless, so anyone downloading directly from GitHub can verify their download too.

### 4.4 Changelog → release notes → manifest, one source, three destinations
1. Extract the section of `CHANGELOG.md` corresponding to the tag being built (the "Unreleased" section header renamed to the version being released, or however the workflow identifies "this version's entry" — pick one convention and document it in the workflow file itself).
2. Use that extracted text, verbatim, as the GitHub Release body.
3. Use that same extracted text as the `releaseNotes` value written into `update_manifest.json` (§3.2).
This is the concrete mechanism behind §2's "single source of truth" rule — write it once in this step, don't let the workflow or a human re-type it in a second place.

### 4.5 Publish
- Create the GitHub Release (using the extracted changelog as the body, per §4.4), attach all three APKs plus a checksums file as release assets.
- Update `update_manifest.json` (in the repo or as a release asset, matching wherever Brewline's equivalent file lives) with the new `latestVersionCode`/`latestVersionName`/`apkUrl` (pointing at the **universal** APK per §3.3)/`sha256`/`releaseNotes`.

---

## 5. Documentation Requirements

- `CHANGELOG.md` gets a short header comment explaining it's the single source for both GitHub release notes and the in-app OTA changelog — so a future contributor doesn't start hand-writing release notes separately in the GitHub UI when cutting a release.
- The release workflow YAML gets inline comments at the changelog-extraction step (§4.4) explaining exactly which section-identification convention it relies on, since that's the one step most likely to silently break if `CHANGELOG.md`'s formatting drifts.
- `update_manifest.json`'s schema gets documented (a short comment or a `README` note) explaining why the in-app updater always points at the universal APK rather than a per-ABI one, cross-referencing §3.3, so a future "optimization" doesn't wire up per-ABI selection without knowing that was a deliberate simplicity choice.

---

## 6. Acceptance Checklist

**UI**
- [ ] Dynamic color is in use app-wide; no hardcoded hex outside the fallback seed constant
- [ ] Corner radii normalized to 16dp/28dp across existing and new screens
- [ ] `AppSpacing` exists and is used consistently
- [ ] Action sheets use a single always-bottom-sheet component — no unused responsive/breakpoint infrastructure was introduced
- [ ] At least one shared `StatusBadge`-equivalent component exists and is reused across Walt's own badge-like UI

**Versioning/Changelog**
- [ ] `versionCode` is deterministically derived from `pubspec.yaml`'s semver version, not independently tracked
- [ ] `CHANGELOG.md` follows Keep a Changelog format and is the only place release notes are authored

**OTA**
- [ ] Release keystore exists, is backed up outside the repo, and every release build is signed with it
- [ ] Manifest check compares versionCode correctly, fails silently offline, never blocks app startup
- [ ] In-app updater downloads and installs the universal APK, verifies its SHA-256 before install
- [ ] Mandatory-update path (`minSupportedVersionCode`) blocks app use with a non-dismissible screen when triggered

**CI**
- [ ] Tag-triggered workflow produces exactly three artifacts: armv7, armv8, and universal — no unrequested x86_64 build
- [ ] SHA-256 checksums computed and published for all three
- [ ] GitHub Release body and `update_manifest.json`'s `releaseNotes` both come from the same extracted `CHANGELOG.md` section — verified identical, not just similar
- [ ] `update_manifest.json`'s `apkUrl` points at the universal APK, not a per-ABI one
