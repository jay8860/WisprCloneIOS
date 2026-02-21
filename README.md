# Proxy Example (Recommended for Security)

Use this to keep your Gemini API key on a server instead of storing it in the iPhone app.

## Option A: Railway (best for your setup)

### 1) Push this folder to a new GitHub repo

```bash
cd "/Users/jayantnahata/Desktop/ChatGPT Codex Folder/wispr-clone-gemini-ios/proxy-example"
git init
git add .
git commit -m "Initial wispr gemini proxy"
git branch -M main
git remote add origin https://github.com/<YOUR_USERNAME>/<YOUR_NEW_REPO>.git
git push -u origin main
```

### 2) Deploy on Railway
1. Railway dashboard -> `New Project` -> `Deploy from GitHub repo`.
2. Select the repo you just created.
3. Railway will detect Node.js and run `npm start` automatically from `package.json`.

### 3) Add environment variables in Railway
- `NODE_ENV=production`
- `GEMINI_API_KEY=<your real key>`
- `PROXY_BEARER_TOKEN=<long random secret>`
- `GEMINI_MODEL=gemini-2.5-flash-lite`
- `REQUEST_TIMEOUT_MS=25000`
- `MAX_BODY_BYTES=12582912`

### 4) Generate a public HTTPS domain
In the Railway service, open `Networking` and generate a domain.

### 5) Test the deployed proxy
Use these in a terminal:

```bash
curl -s https://<YOUR-RAILWAY-DOMAIN>/healthz
```

Expected response:

```json
{"ok":true}
```

## Option B: Run locally on Mac (same Wi-Fi only)

```bash
cd proxy-example
export GEMINI_API_KEY="YOUR_KEY"
export GEMINI_MODEL="gemini-2.5-flash-lite"
export PROXY_BEARER_TOKEN="choose_a_secret_token"
node server.mjs
```

Local server:
- `http://localhost:8787`
- health check: `GET /healthz`
- transcription: `POST /v1/transcribe`

## iPhone app settings (same for cloud/local)
In `WisprCloneGeminiiOS` app:
- Backend mode: `Proxy Server (recommended)`
- Proxy Base URL: your server base URL (no `/v1/transcribe` suffix)
  - cloud example: `https://<YOUR-RAILWAY-DOMAIN>`
  - local example: `http://<YOUR-MAC-IP>:8787`
- Proxy Bearer Token: exact same value as `PROXY_BEARER_TOKEN`

## Important
- For cloud use, keep `PROXY_BEARER_TOKEN` enabled.
- Never commit real API keys or tokens to GitHub.
- Use HTTPS for non-local deployments.
