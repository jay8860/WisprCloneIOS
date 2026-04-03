import http from 'node:http';
import crypto from 'node:crypto';

const PORT = Number(process.env.PORT || 8787);
const GEMINI_API_KEY = (process.env.GEMINI_API_KEY || '').trim();
const DEFAULT_MODEL = (process.env.GEMINI_MODEL || 'gemini-2.5-flash-lite').trim();
const BEARER_TOKEN = (process.env.PROXY_BEARER_TOKEN || '').trim();
const REQUEST_TIMEOUT_MS = Number(process.env.REQUEST_TIMEOUT_MS || 25000);
const MAX_BODY_BYTES = Number(process.env.MAX_BODY_BYTES || 12 * 1024 * 1024);
const IS_PRODUCTION = (process.env.NODE_ENV || '').toLowerCase() === 'production';

if (!GEMINI_API_KEY) {
  console.error('Missing GEMINI_API_KEY environment variable');
  process.exit(1);
}

if (IS_PRODUCTION && !BEARER_TOKEN) {
  console.error('Missing PROXY_BEARER_TOKEN in production. Refusing to start an open proxy.');
  process.exit(1);
}

if (IS_PRODUCTION && BEARER_TOKEN.length < 16) {
  console.error('PROXY_BEARER_TOKEN is too short. Use at least 16 characters.');
  process.exit(1);
}

function sendJSON(res, statusCode, payload) {
  if (res.headersSent) {
    return;
  }
  const text = JSON.stringify(payload);
  res.writeHead(statusCode, {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(text),
  });
  res.end(text);
}

function languageInstruction(mode) {
  switch ((mode || '').toLowerCase()) {
    case 'english':
      return 'Output strictly in English only. Do not translate to Hindi.';
    case 'hindi':
      return 'Output strictly in Hindi only. Do not translate to English.';
    case 'mixed':
      return 'Keep mixed language exactly as spoken; do not force translation.';
    default:
      return 'Detect language automatically and preserve the spoken language.';
  }
}

function buildPrompt(body) {
  const lines = [
    'Task: Transcribe the provided speech audio into plain text only.',
    'Do not add explanations or labels.',
    'If speaker self-corrects (e.g. 5:00 no 5:30), keep the corrected value only.',
    languageInstruction(body.languageMode),
  ];

  if (body.formatSpokenLists === true) {
    lines.push('If clearly dictating a list (first/second/third etc.), format as bullet list with one item per line.');
  }
  return lines.join('\n');
}

async function transcribeWithGemini(body) {
  const model = (body.model || DEFAULT_MODEL).trim() || DEFAULT_MODEL;
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${GEMINI_API_KEY}`;

  const requestBody = {
    contents: [
      {
        parts: [
          { text: buildPrompt(body) },
          {
            inline_data: {
              mime_type: body.mimeType || 'audio/wav',
              data: body.audioBase64,
            },
          },
        ],
      },
    ],
  };

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

  let response;
  let raw;
  try {
    response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(requestBody),
      signal: controller.signal,
    });
    raw = await response.text();
  } catch (error) {
    if (error && error.name === 'AbortError') {
      throw new Error(`Gemini API timeout after ${REQUEST_TIMEOUT_MS} ms`);
    }
    throw error;
  } finally {
    clearTimeout(timeout);
  }

  if (!response.ok) {
    const brief = (raw || '').replace(/\s+/g, ' ').slice(0, 300);
    throw new Error(`Gemini API failed: ${response.status}${brief ? ` ${brief}` : ''}`);
  }

  const json = JSON.parse(raw);
  const text = json?.candidates?.[0]?.content?.parts
    ?.map((part) => part?.text)
    ?.filter(Boolean)
    ?.join('\n')
    ?.trim();

  if (!text) {
    throw new Error('Empty Gemini transcription response');
  }

  return text;
}

function pathFromURL(rawURL) {
  try {
    return new URL(rawURL || '/', 'http://localhost').pathname;
  } catch {
    return '/';
  }
}

function bearerMatches(authHeader, expectedToken) {
  if (!expectedToken) {
    return true;
  }
  const prefix = 'Bearer ';
  if (!authHeader || !authHeader.startsWith(prefix)) {
    return false;
  }
  const provided = authHeader.slice(prefix.length);
  const expectedBuffer = Buffer.from(expectedToken);
  const providedBuffer = Buffer.from(provided);
  if (expectedBuffer.length !== providedBuffer.length) {
    return false;
  }
  return crypto.timingSafeEqual(expectedBuffer, providedBuffer);
}

const server = http.createServer(async (req, res) => {
  const path = pathFromURL(req.url);

  if (req.method === 'GET' && path === '/healthz') {
    return sendJSON(res, 200, { ok: true });
  }

  if (req.method !== 'POST' || path !== '/v1/transcribe') {
    return sendJSON(res, 404, { error: 'Not found' });
  }

  if (BEARER_TOKEN && !bearerMatches(req.headers.authorization || '', BEARER_TOKEN)) {
    return sendJSON(res, 401, { error: 'Unauthorized' });
  }

  const contentType = req.headers['content-type'] || '';
  if (!String(contentType).toLowerCase().startsWith('application/json')) {
    return sendJSON(res, 415, { error: 'Content-Type must be application/json' });
  }

  try {
    req.setEncoding('utf8');
    let incoming = '';
    let rejected = false;

    req.on('data', (chunk) => {
      if (rejected) {
        return;
      }
      incoming += chunk;
      if (Buffer.byteLength(incoming, 'utf8') > MAX_BODY_BYTES) {
        rejected = true;
        sendJSON(res, 413, { error: 'Payload too large' });
        req.destroy();
      }
    });

    req.on('end', async () => {
      if (rejected) {
        return;
      }

      let body;
      try {
        body = JSON.parse(incoming || '{}');
      } catch {
        return sendJSON(res, 400, { error: 'Invalid JSON body' });
      }

      if (!body.audioBase64) {
        return sendJSON(res, 400, { error: 'audioBase64 is required' });
      }

      try {
        const text = await transcribeWithGemini(body);
        return sendJSON(res, 200, { text });
      } catch (error) {
        const message = error instanceof Error ? error.message : 'Unknown error';
        return sendJSON(res, 500, { error: message });
      }
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    return sendJSON(res, 500, { error: message });
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Wispr iOS proxy listening on http://0.0.0.0:${PORT}`);
  console.log(`Model default: ${DEFAULT_MODEL}`);
  console.log(`Bearer token: ${BEARER_TOKEN ? 'enabled' : 'disabled'}`);
  if (IS_PRODUCTION && !BEARER_TOKEN) {
    console.log('Warning: open proxy in production mode.');
  }
});
