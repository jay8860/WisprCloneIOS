# iPhone Setup (No Bypass, Compliant Path)

Apple iOS does not provide a public way for third-party keyboard extensions to run full custom microphone dictation exactly like system dictation inside every app. A stable workaround is:

- iPhone uses native dictation in a Shortcut
- Shortcut calls your Mac relay for Gemini cleanup
- Gemini key stays on your Mac only

## 1. On Mac: store Gemini key in Keychain
From project root:

```bash
cd /Users/jayantnahata/Desktop/ChatGPT\ Codex\ Folder/wispr-clone-gemini
printf '%s' 'YOUR_GEMINI_KEY' | swift run wispr-clone-gemini --set-api-key-stdin
```

## 2. On Mac: start relay
```bash
export GEMINI_API_KEY="$(security find-generic-password -s wispr-clone-gemini -a gemini_api_key -w)"
export RELAY_PORT=8787
node relay/gemini_relay.js
```

The relay prints an `x-relay-token`. Keep it private.

## 3. Find your Mac LAN IP
```bash
ipconfig getifaddr en0
```
(use `en1` if needed)

## 4. Create iPhone Shortcut
In Shortcuts app, build this flow:

1. `Dictate Text`
2. `Text` action with JSON template:
   ```json
   {
     "text": "[Dictated Text]",
     "languageHint": "en-US",
     "appStyle": "natural concise tone"
   }
   ```
3. `Get Contents of URL`
   - URL: `http://<MAC_LAN_IP>:8787/v1/text-clean`
   - Method: `POST`
   - Headers:
     - `Content-Type: application/json`
     - `x-relay-token: <TOKEN_FROM_RELAY>`
   - Request Body: the JSON text from step 2
4. `Get Dictionary Value` for key `text`
5. `Copy to Clipboard`
6. `Show Result`

Now run this Shortcut anywhere on iPhone. It gives cleaned text and copies it for paste.

## 5. Add quick trigger on iPhone
- Settings > Accessibility > Touch > Back Tap
- Assign your Shortcut to Double Tap or Triple Tap

This gives near-instant dictation cleanup workflow without exposing the Gemini key on the phone.

## Privacy notes
- Prefer local Wi-Fi only (same trusted network).
- Keep `x-relay-token` secret.
- Do not hardcode Gemini key in iPhone Shortcut.
- If exposed, rotate Gemini key immediately.
