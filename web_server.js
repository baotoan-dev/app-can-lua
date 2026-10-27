// Production static server for Can Lua Web App with Gzip and HTTP Caching
const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const PORT = 8085;
const WEB_DIR = path.join(__dirname, 'build', 'web');

// In-memory cache for synthesized voice phrases
const ttsCache = new Map();

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.wasm': 'application/wasm',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.ico': 'image/x-icon',
};

const server = http.createServer((req, res) => {
  // Normalize URL
  const parsedUrl = new URL(req.url, `http://localhost:${PORT}`);
  let reqPath = decodeURI(parsedUrl.pathname);

  // High-Quality Vietnamese Text-to-Speech API
  if (reqPath === '/api/tts') {
    const text = (parsedUrl.searchParams.get('text') || '').trim();
    if (!text) {
      res.writeHead(400, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('Thiếu tham số text');
      return;
    }

    // Serve from in-memory cache if available
    if (ttsCache.has(text)) {
      const cached = ttsCache.get(text);
      res.writeHead(200, {
        'Content-Type': 'audio/mpeg',
        'Content-Length': cached.length,
        'Cache-Control': 'public, max-age=604800, immutable',
        'Access-Control-Allow-Origin': '*',
      });
      res.end(cached);
      return;
    }

    // Fetch crystal-clear Vietnamese voice from Google Translate TTS
    const ttsUrl = `https://translate.google.com/translate_tts?ie=UTF-8&q=${encodeURIComponent(text)}&tl=vi&client=tw-ob`;
    https.get(ttsUrl, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      }
    }, (googleRes) => {
      if (googleRes.statusCode !== 200) {
        res.writeHead(googleRes.statusCode || 500, { 'Content-Type': 'text/plain' });
        res.end('Google TTS service unavailable');
        return;
      }

      const chunks = [];
      googleRes.on('data', chunk => chunks.push(chunk));
      googleRes.on('end', () => {
        const audioBuffer = Buffer.concat(chunks);
        // Retain up to 400 audio phrases in memory
        if (ttsCache.size > 400) {
          const firstKey = ttsCache.keys().next().value;
          ttsCache.delete(firstKey);
        }
        ttsCache.set(text, audioBuffer);

        res.writeHead(200, {
          'Content-Type': 'audio/mpeg',
          'Content-Length': audioBuffer.length,
          'Cache-Control': 'public, max-age=604800, immutable',
          'Access-Control-Allow-Origin': '*',
        });
        res.end(audioBuffer);
      });
    }).on('error', (err) => {
      res.writeHead(500, { 'Content-Type': 'text/plain' });
      res.end('Lỗi mạng khi tải giọng đọc');
    });
    return;
  }

  if (reqPath === '/' || reqPath === '') {
    reqPath = '/index.html';
  }

  let filePath = path.join(WEB_DIR, reqPath);

  // Security check: ensure path stays within WEB_DIR
  if (!filePath.startsWith(WEB_DIR)) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }

  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      // Fallback to index.html for SPA routing
      filePath = path.join(WEB_DIR, 'index.html');
      try {
        stats = fs.statSync(filePath);
      } catch (e) {
        res.writeHead(404);
        res.end('Not Found');
        return;
      }
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';
    const acceptEncoding = req.headers['accept-encoding'] || '';

    // Cache-Control strategy:
    // HTML is revalidated (no-cache); JS, WASM, CSS, fonts are cached aggressively
    const isHtml = ext === '.html';
    const cacheControl = isHtml 
      ? 'no-cache, must-revalidate' 
      : 'public, max-age=604800, immutable';

    const lastModified = stats.mtime.toUTCString();
    if (req.headers['if-modified-since'] === lastModified) {
      res.writeHead(304, {
        'Cache-Control': cacheControl,
        'Last-Modified': lastModified,
      });
      res.end();
      return;
    }

    const headers = {
      'Content-Type': contentType,
      'Cache-Control': cacheControl,
      'Last-Modified': lastModified,
      'Access-Control-Allow-Origin': '*',
    };

    // Compress text/js/json/wasm with Gzip
    const compressible = /text|javascript|json|wasm/.test(contentType);
    if (compressible && acceptEncoding.includes('gzip')) {
      headers['Content-Encoding'] = 'gzip';
      res.writeHead(200, headers);
      const rawStream = fs.createReadStream(filePath);
      const gzip = zlib.createGzip({ level: 6 });
      rawStream.pipe(gzip).pipe(res);
    } else {
      headers['Content-Length'] = stats.size;
      res.writeHead(200, headers);
      fs.createReadStream(filePath).pipe(res);
    }
  });
});

server.listen(PORT, 'localhost', () => {
  console.log(`Cân Lúa Web App (Release Mode) running at http://localhost:${PORT}`);
  console.log(`Serving directory: ${WEB_DIR}`);
});
