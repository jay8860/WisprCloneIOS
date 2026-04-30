# SpeakDash

**Voice dictation for Mac. In any language. Without the screenshot creep.**

SpeakDash is a press-and-hold voice dictation app for macOS. Press a key, hold it, talk, and watch perfectly formatted text appear in any app you're using — including native Hinglish (Hindi-English code-switching).

Built by [QuantSummit AI](https://quantsummit.ai). Marketing site: [speakdash.app](https://speakdash.app).

## What this build includes

- Global hotkey press-and-hold dictation (default: `Option + Space`)
- Optional double-press Right Option trigger mode
- Mic capture (16 kHz mono WAV; optional compressed M4A upload)
- Cloud transcription via Google Gemini's `generateContent` audio input
- Optional offline Whisper fallback (whisper.cpp) with user-supplied binary + model
- App-aware prompting (different tone/style per active app bundle ID)
- Mixed Hindi + English ("Hinglish") support with Devanagari ↔ Roman script preference
- Automatic punctuation + spoken punctuation word conversion
- Spoken list detection with one-item-per-line bullet formatting
- Spoken formatting commands (`new line`, `new paragraph`, Hindi variants)
- Snippet expansion + dictionary replacements + acronym expansion
- Paste-at-cursor injection with clipboard restore
- On-screen HUD cues for `Recording`, `Transcribing`, and `Inserted`
- Sensitive-field guard (password / secure field blocking)
- Confidence guard (words-per-second sanity check)
- Auto-stop recording safety timer
- License-key gated tiers (Free / Personal / Pro / Lifetime)
- Sparkle-based auto-updates (notarized DMG distribution)
- Diagnostics exporter (zip)
- Recent-dictations history window with search

## Project layout

```
Sources/SpeakDash/             — Swift source
  SpeakDashApp.swift           — main entry point
  SpeakDashSettingsWindow.swift
  SpeakDashOnboardingWindow.swift
  SpeakDashLicenseWindow.swift
  SpeakDashSparkleUpdater.swift
  SpeakDashDiagnostics.swift
  SpeakDashLogger.swift
  SpeakDashLicenseVerifier.swift
  LicenseManager.swift
  AudioInputDeviceManager.swift
  AudioProcessing.swift
  OfflineWhisperClient.swift
  UpdateChecker.swift
  AppVersion.swift
scripts/                       — build, packaging, release, Sparkle tooling
appcast.xml                    — Sparkle update feed (publish to speakdash.app)
server.mjs                     — optional secure proxy (Railway-deployable)
relay/                         — local LAN relay (legacy iOS Shortcut path)
```

## Build the app

Requires macOS 14+, Swift 6.2 toolchain.

```bash
cd "/Users/jayantnahata/Desktop/ChatGPT Codex Folder/wispr-clone-gemini"
zsh scripts/build_app_bundle.sh
```

Output: `dist/SpeakDash.app`

## Sign + notarize for public distribution

Set these environment variables, then run the production script:

```bash
export DEVELOPER_ID_APP="Developer ID Application: QuantSummit AI (TEAM_ID)"
export APPLE_ID="your-apple-id@example.com"
export APPLE_TEAM_ID="ABC123XYZ4"
export APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"
export SPARKLE_PUBLIC_ED_KEY="<from sparkle_generate_keys.sh>"
zsh scripts/release_build_notarized_dmg.sh
```

## Sparkle keys (one-time)

```bash
zsh scripts/sparkle_generate_keys.sh
```

Save the public key to your release env as `SPARKLE_PUBLIC_ED_KEY`. Keep the private key in your macOS Keychain — never commit it.

## Release a new version (after generating notarized DMG)

```bash
export SPARKLE_FEED_URL="https://speakdash.app/appcast.xml"
zsh scripts/release_prepare_website_drop.sh
```

Upload everything in `release/updates/` to your CDN (Cloudflare R2 recommended).

## Permissions required (macOS)

- Microphone (for audio capture)
- Accessibility (for paste-at-cursor injection)
- Input Monitoring (for global hotkey detection)

The app prompts for these on first launch via the onboarding wizard. **No screen recording is requested or used — SpeakDash never reads your screen.**

## Configuration

Config file is created automatically at:
`~/.speakdash/config.json`

Logs: `~/.speakdash/logs/speakdash.log`

## License & business model

SpeakDash is licensed software. Three commercial tiers plus a lifetime option:

| Tier | Price | Includes |
|---|---|---|
| Free | $0 | 30 minutes/week dictation, all features |
| Personal (BYO API key) | $4.99/mo · $39/yr | Unlimited dictation, your own Gemini/OpenAI key |
| Pro (Managed) | $9.99/mo · $79/yr | Unlimited managed cloud transcription |
| Lifetime | $129 one-time | Personal tier, paid once, all future updates |

INR pricing for India: ₹399/mo · ₹799/mo · ₹9,999 lifetime.

Payments handled by [Lemon Squeezy](https://lemonsqueezy.com) as merchant of record (handles EU VAT, UK VAT, US sales tax, India GST).

## Privacy

- We do not capture screenshots of your screen.
- We do not store your audio.
- We do not store your transcripts.
- On-device mode (Personal/Lifetime) processes audio locally via whisper.cpp.
- Cloud mode sends audio to Google Gemini, processed and discarded.

Full privacy policy: [speakdash.app/privacy](https://speakdash.app/privacy)

## Support

Email: hello@quantsummit.ai
Press: press@quantsummit.ai

## Repo

Source: [github.com/jay8860/WisprCloneIOS](https://github.com/jay8860/WisprCloneIOS) (legacy name; planned rename to `speakdash-mac`)
