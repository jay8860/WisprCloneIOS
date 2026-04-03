# Research Notes: Wispr-style Dictation + Open Source Alternatives

## Wispr Flow (public signals)
Public docs and help pages indicate these capabilities:
- Global dictation trigger + keyboard shortcuts
- Auto Edit / rewrite style controls
- Custom words + snippets
- App-aware context and voice profile concepts
- Support for multiple languages

Public API docs show:
- Streaming and non-streaming speech-to-text endpoints
- WebSocket and REST patterns
- Configurable context payloads (domain dictionaries, formatting preferences)

Data controls pages mention model/provider architecture and privacy controls, but do not publish full internal implementation details.

## Open source tools worth borrowing from
### OpenWhispr
- Repo: https://github.com/ishan0102/open-whispr
- Stack: Electron + Rust, offline Whisper model support
- Useful patterns: offline-first model pipeline, desktop integration hooks, configurable shortcuts

### AudioWhisper
- Repo: https://github.com/Beingpax/AudioWhisper
- Stack: Python desktop workflow for recording/transcription with shortcuts
- Useful patterns: practical push-to-talk UX and lightweight local config

### whisper-to-input
- Repo: https://github.com/mallorbc/whisper-to-input
- Stack: keyboard/text insertion pipeline around speech transcription
- Useful patterns: input-focused workflow and direct text insertion behavior

### whisper-asr-webservice
- Repo: https://github.com/ahmetoner/whisper-asr-webservice
- Stack: containerized Whisper inference API
- Useful patterns: server deployment path, API contract for mobile/desktop clients

## SuperWhisper status
I did not find an official public source repository for the production SuperWhisper app. There are community wrappers and related projects, but the main commercial app implementation appears closed source.

## Recommended technical direction
- Keep local native clients for keyboard integration per platform.
- Reuse one shared transcription contract (same prompt schema and cleanup rules).
- Add optional backend relay only if you want key management or usage analytics.
