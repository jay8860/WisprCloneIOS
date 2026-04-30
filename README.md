# Wispr Clone Gemini (macOS)

A local, no-subscription dictation tool for macOS that behaves like a Wispr-style press-and-hold keyboard dictation workflow.

## What this build includes
- Global hotkey press-and-hold dictation (default: `Option + Space`)
- Optional double-press Right Option trigger mode
- WAV microphone capture
- Gemini transcription via `generateContent` audio input
- App-aware prompting (different tone/style per app bundle id)
- Mixed Hindi + English support with script preference controls
- Automatic punctuation + spoken punctuation word conversion
- Spoken list detection with one-item-per-line bullet formatting
- Spoken formatting commands (`new line`, `new paragraph`, Hindi variants)
- Snippet expansion (for quick commands)
- Dictionary replacement corrections
- Paste-at-cursor injection with clipboard restore
- On-screen HUD cues for `Recording`, `Transcribing`, and `Inserted`
- Sensitive-field guard (password/secure field blocking)
- Confidence guard based on words-per-second
- Auto-stop recording safety timer
- Reliability hardening:
  - short-press filtering
  - retry on transient Gemini failures
  - serial transcription queueing
  - optional compressed audio upload (M4A) to reduce latency
  - optional offline Whisper fallback (whisper.cpp) if Gemini fails

## Project path
`/Users/jayantnahata/Desktop/ChatGPT Codex Folder/wispr-clone-gemini`

## Repo contents
- macOS dictation app source: `Sources/`, `Package.swift`, `scripts/build_app_bundle.sh`
- DMG packaging: `scripts/build_dmg.sh`
- proxy server for secure mobile/backend use: `server.mjs`, `package.json`, `RAILWAY_DEPLOY.md`

## Run
1. Build:
   ```bash
   cd /Users/jayantnahata/Desktop/ChatGPT\ Codex\ Folder/wispr-clone-gemini
   swift build
   ```
2. Save API key to Keychain (recommended):
   ```bash
   printf '%s' 'your_key_here' | swift run wispr-clone-gemini --set-api-key-stdin
   ```
3. Start:
   ```bash
   swift run
   ```

You should now see an on-screen cue like `Recording • <AppName>` while dictating.

Alternative (session-only key, no Keychain):
```bash
export GEMINI_API_KEY="your_key_here"
swift run wispr-clone-gemini
```

CLI utilities:
```bash
swift run wispr-clone-gemini --help
swift run wispr-clone-gemini --clear-api-key
```

## Build a macOS app (.app) and DMG
```bash
cd /Users/jayantnahata/Desktop/ChatGPT\ Codex\ Folder/wispr-clone-gemini
zsh scripts/build_app_bundle.sh
zsh scripts/build_dmg.sh
```

## License + Updates
- Menu bar now includes `License...` (stores key in Keychain) and `Check for Updates...` (checks latest GitHub release).
- Update settings are in `config.json`:
  - `updatesEnabled`
  - `updatesLatestReleaseAPIURL`
  - `updatesReleasesPageURL`

## Production Release (Notarized DMG)
This repo includes a notarization script scaffold:
`/Users/jayantnahata/Desktop/ChatGPT Codex Folder/wispr-clone-gemini/scripts/release_build_notarized_dmg.sh`

It requires `Developer ID Application` signing and notarization credentials.

## Permissions required (macOS)
- Accessibility
- Input Monitoring
- Microphone

The app prompts for these at startup.

## Config
Config file is created automatically at:
`~/.wispr-clone-gemini/config.json`

Important fields:
- `hotkey.keyCode`, `hotkey.modifiers`
- `preferredInputDeviceUID` (optional; picks a specific mic by UID, otherwise uses system default)
- `compressAudioForUpload` (optional; exports to M4A before uploading to Gemini)
- `enableOfflineWhisperFallback` (optional; uses whisper.cpp when Gemini fails)
- `offlineWhisperBinaryPath`, `offlineWhisperModelPath` (paths for whisper.cpp)
- `languageHint`
- `languageMode` (`auto`, `english`, `hindi`, `mixed`)
- `scriptPreference` (`auto`, `native`, `romanized`)
- `defaultStyleMode`, `appModeOverrides`
- `maxTranscriptionRetries`
- `minRecordingMs`
- `maxRecordingSeconds`
- `convertSpokenFormattingCommands`
- `enableVoiceEditingCommands`
- `blockInSensitiveFields`
- `enableConfidenceGuard`, `maxWordsPerSecond`
- `formatSpokenLists` (auto-detect and format dictated lists)
- `listBulletStyle` (`dash` or `asterisk`)
- `acronyms`
- `snippets`
- `replacements`
- `appStyles`

## iPhone / Android / elsewhere
### iPhone
Apple does not allow third-party custom keyboards to use microphone dictation directly in the same way system dictation works. Because of this OS limitation, true Wispr-style keyboard mic parity is not currently achievable as a standalone iOS custom keyboard extension.

Use the compliant iPhone workflow in:
`/Users/jayantnahata/Desktop/ChatGPT Codex Folder/wispr-clone-gemini/IPHONE_SETUP.md`
and local relay:
`/Users/jayantnahata/Desktop/ChatGPT Codex Folder/wispr-clone-gemini/relay/gemini_relay.js`

### Android
A custom IME with mic + Gemini is feasible. Next step is an Android `InputMethodService` client that sends captured audio to Gemini and commits text with `InputConnection.commitText()`.

### Windows/Linux
Feasible through global hotkeys + clipboard/text injection using native hooks per OS.

## Notes on parity with Wispr Flow
This is a local clone implementation, not the proprietary Wispr codebase. Public features can be matched incrementally, but exact internals are not publicly available.
