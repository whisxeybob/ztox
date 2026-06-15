// ztox web — Node.js + Express + ws.
// Single-process server: serves the static SPA and a WebSocket relay.
//
// The relay protocol is intentionally minimal — clients connect with a
// chosen name, server keeps a registry, broadcasts text messages to
// everyone in the same room. This is NOT the Tox protocol; real Tox
// integration via c-toxcore napi bindings is tracked separately and
// will replace the relay() handler. Until then the WS surface is
// API-shaped so the frontend doesn't need to change.

'use strict';

const path = require('path');
const http = require('http');
const express = require('express');
const { WebSocketServer } = require('ws');

const PORT = Number(process.env.PORT) || 8787;
const HOST = process.env.HOST || '0.0.0.0';
const PUBLIC_DIR = path.join(__dirname, '..', 'public');

const app = express();
app.disable('x-powered-by');

// Cache-bust the SPA shell on every request, leave hashed assets alone.
app.use((req, res, next) => {
  if (req.path === '/' || req.path.endsWith('.html')) {
    res.set('Cache-Control', 'no-store');
  }
  next();
});

app.use(express.static(PUBLIC_DIR, { extensions: ['html'] }));

app.get('/healthz', (_req, res) => res.json({ ok: true, version: '0.1.0' }));

const server = http.createServer(app);
const wss = new WebSocketServer({ server, path: '/ws' });

// In-memory room registry. Process-local — restart drops state.
// Future: persist to SQLite if uptime matters before Tox is wired.
const rooms = new Map(); // roomId -> Set<{ ws, name, id }>
let connectionCounter = 0;

function broadcast(room, payload, exceptId = null) {
  const peers = rooms.get(room);
  if (!peers) return;
  const data = JSON.stringify(payload);
  for (const peer of peers) {
    if (peer.id === exceptId) continue;
    if (peer.ws.readyState === peer.ws.OPEN) peer.ws.send(data);
  }
}

function rosterFor(room) {
  const peers = rooms.get(room);
  if (!peers) return [];
  return Array.from(peers).map(p => ({ id: p.id, name: p.name }));
}

wss.on('connection', (ws, req) => {
  const peer = {
    id: ++connectionCounter,
    name: null,
    room: null,
    ws,
  };

  ws.on('message', (buf) => {
    let msg;
    try { msg = JSON.parse(buf.toString()); } catch { return; }
    if (!msg || typeof msg.t !== 'string') return;

    switch (msg.t) {
      case 'hello': {
        peer.name = String(msg.name || 'anon').slice(0, 32);
        peer.room = String(msg.room || 'lobby').slice(0, 64);
        let set = rooms.get(peer.room);
        if (!set) { set = new Set(); rooms.set(peer.room, set); }
        set.add(peer);
        ws.send(JSON.stringify({ t: 'welcome', id: peer.id, room: peer.room, roster: rosterFor(peer.room) }));
        broadcast(peer.room, { t: 'join', id: peer.id, name: peer.name }, peer.id);
        break;
      }
      case 'msg': {
        if (!peer.room) return;
        const body = String(msg.body || '').slice(0, 4000);
        if (!body) return;
        broadcast(peer.room, {
          t: 'msg',
          fromId: peer.id,
          fromName: peer.name,
          body,
          ts: Date.now(),
        });
        break;
      }
      case 'ping':
        ws.send(JSON.stringify({ t: 'pong', ts: Date.now() }));
        break;
    }
  });

  ws.on('close', () => {
    if (peer.room) {
      const set = rooms.get(peer.room);
      if (set) {
        set.delete(peer);
        if (set.size === 0) rooms.delete(peer.room);
        else broadcast(peer.room, { t: 'leave', id: peer.id, name: peer.name });
      }
    }
  });
});

server.listen(PORT, HOST, () => {
  console.log(`ztox web listening on http://${HOST}:${PORT}  (ws path: /ws)`);
});

process.on('SIGTERM', () => server.close(() => process.exit(0)));
process.on('SIGINT', () => server.close(() => process.exit(0)));
