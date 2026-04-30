#!/usr/bin/env node

const http = require('node:http');
const crypto = require('node:crypto');

const apiKey = process.env.GEMINI_API_KEY;
if (!apiKey) {
  console.error('Missing GEMINI_API_KEY. Set it before starting relay.');
  process.exit(1);
}

const host = process.env.RELAY_HOST || '0.0.0.0';
const port = Number(process.env.RELAY_PORT || 8787);
const relayToken = process.env.RELAY_TOKEN || crypto.randomBytes(24).toString('hex');
const model = process.env.GEMINI_MODEL || 'gemini-2.0-flash';
const maxBodyBytes = 256 * 1024;

if (!process.env.RELAY_TOKEN) {
  console.log('Generated RELAY_TOKEN for this session:');
  console.log(relayToken);
}

function sendJson(res, status, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body),
    'Cache-Control': 'no-store',
  });
  res.end(body);
}

function parseBody(req) {
  return new Promise((resolve, reject) => {
    let received = 0;
    const chunks = [];

    req.on('data', (chunk) => {
      received += chunk.length;
      if (received > maxBodyBytes) {
        reject(new Error('Payload too large'));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });

    req.on('end', () => {
      try {
        const text = Buffer.concat(chunks).toString('utf8');
        resolve(text ? JSON.parse(text) : {});
      } catch {
        reject(new Error('Invalid JSON'));
      }
    });

    req.on('error', reject);
  });
}

function buildPrompt(input) {
  const languageHint = typeof input.languageHint === 'string' && input.languageHint.trim()
    ? input.languageHint.trim()
    : 'en-US';

  const appStyle = typeof input.appStyle === 'string' ? input.appStyle.trim() : '';
  const styleLine = appStyle
    ? `Style preference: ${appStyle}`
    : 'Style preference: keep tone natural and concise.';

  return [
    'You are a dictation cleanup engine.',
    'Task: lightly clean the provided transcribed text.',
    'Do not change facts, names, or intent.',
    'Return only the final cleaned text. No markdown and no quotes.',
    `Language hint: ${languageHint}.`,
    styleLine,
  ].join('\n');
}

async function cleanTextWithGemini(inputText, input) {
  const prompt = buildPrompt(input);
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(apiKey)}`;

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [
        {
          role: 'user',
          parts: [
            { text: `${prompt}\n\nInput text:\n${inputText}` },
          ],
        },
      ],
      generationConfig: {
        temperature: 0,
        maxOutputTokens: 512,
      },
    }),
  });

  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    const message = payload?.error?.message || `Gemini HTTP ${response.status}`;
    throw new Error(message);
  }

  const candidates = Array.isArray(payload?.candidates) ? payload.candidates : [];
  for (const candidate of candidates) {
    const parts = candidate?.content?.parts;
    if (!Array.isArray(parts)) continue;
    const text = parts
      .map((part) => (typeof part?.text === 'string' ? part.text : ''))
      .join('')
      .trim();
    if (text) return text;
  }

  throw new Error('Gemini returned empty text');
}

const server = http.createServer(async (req, res) => {
  try {
    if (req.method === 'GET' && req.url === '/health') {
      return sendJson(res, 200, { ok: true });
    }

    if (req.method !== 'POST' || req.url !== '/v1/text-clean') {
      return sendJson(res, 404, { error: 'Not found' });
    }

    const token = req.headers['x-relay-token'];
    if (token !== relayToken) {
      return sendJson(res, 401, { error: 'Unauthorized' });
    }

    const body = await parseBody(req);
    const inputText = typeof body.text === 'string' ? body.text.trim() : '';
    if (!inputText) {
      return sendJson(res, 400, { error: 'Field "text" is required' });
    }
    if (inputText.length > 4000) {
      return sendJson(res, 400, { error: 'Text too long (max 4000 chars)' });
    }

    const outputText = await cleanTextWithGemini(inputText, body);
    return sendJson(res, 200, { text: outputText });
  } catch (error) {
    return sendJson(res, 500, { error: error instanceof Error ? error.message : 'Unknown error' });
  }
});

server.listen(port, host, () => {
  console.log(`Gemini relay listening on http://${host}:${port}`);
  console.log('Use this token in iPhone Shortcut header x-relay-token:');
  console.log(relayToken);
});
