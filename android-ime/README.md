# Android Keyboard Skeleton (Gemini IME)

This folder contains a starter `InputMethodService` (`GeminiImeService.kt`) for Android keyboard dictation.

## What it does now
- Adds a simple keyboard view with a hold-to-record button.
- Records microphone audio while pressed.
- Stops on release and sends audio to a placeholder transcription function.
- Commits resulting text with `InputConnection.commitText()`.

## What you need to wire
- Full Android Studio project scaffolding (Gradle, manifest, XML metadata).
- `BIND_INPUT_METHOD` service declaration and keyboard XML metadata.
- Runtime mic permission handling.
- Actual Gemini API request in `transcribeWithGemini()`.

## Why this exists
iOS has major system restrictions for third-party keyboard dictation. Android allows direct custom-IME dictation, so this is the most practical phone keyboard path.
