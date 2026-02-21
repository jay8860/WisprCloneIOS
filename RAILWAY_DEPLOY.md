# Railway Deploy Checklist

## 1) Create GitHub repo from this folder

```bash
cd "/Users/jayantnahata/Desktop/ChatGPT Codex Folder/wispr-clone-gemini-ios/proxy-example"
git init
git add .
git commit -m "Initial wispr gemini proxy"
git branch -M main
git remote add origin https://github.com/<YOUR_USERNAME>/<YOUR_NEW_REPO>.git
git push -u origin main
```

## 2) Deploy service in Railway
- New Project -> Deploy from GitHub Repo
- Select the repo
- Railway auto-detects Node and runs `npm start`

## 3) Set Railway environment variables
- `NODE_ENV=production`
- `GEMINI_API_KEY=<your gemini key>`
- `PROXY_BEARER_TOKEN=<long-random-secret>`
- `GEMINI_MODEL=gemini-2.5-flash-lite`
- `REQUEST_TIMEOUT_MS=25000`
- `MAX_BODY_BYTES=12582912`

## 4) Generate public domain
- Railway service -> Networking -> Generate Domain

## 5) Verify health endpoint

```bash
curl -s https://<YOUR-RAILWAY-DOMAIN>/healthz
```

Expected:

```json
{"ok":true}
```

## 6) Fill iPhone app settings
- Backend mode: `Proxy Server (recommended)`
- Proxy Base URL: `https://<YOUR-RAILWAY-DOMAIN>`
- Proxy Bearer Token: same as `PROXY_BEARER_TOKEN`
- Save settings
