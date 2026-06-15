# ztox web

Drop-in chat for FastPanel (or any Node.js host). Nord-styled SPA + a
Node.js Express + WebSocket relay. Single folder, no build step.

> Honest scope: this is **not the Tox protocol yet** — the WebSocket
> relay does its own simple messaging. Bridging to real `c-toxcore`
> happens in a follow-up by swapping the `wss.on('connection', ...)`
> handler in `server/server.js`. Frontend stays the same.

## Deploy on FastPanel

1. **Zip the `web/` folder** (or upload the contents directly).
2. In FastPanel: *Websites → your site → Applications → Add → Node.js*.
3. Settings:
    - **Application root:** the path where you uploaded the folder
    - **Application startup file:** `server/server.js`
    - **Node version:** 18 or newer
    - **Environment variables:** optional — `PORT=8787`, `HOST=127.0.0.1`
4. FastPanel calls `npm install` itself the first time you start it
   (so `package.json` is enough).
5. Start the app. FastPanel auto-proxies your site domain to the Node
   port and adds TLS via Let's Encrypt if you've enabled SSL.

Verify:

```sh
curl https://your.domain/healthz
# {"ok":true,"version":"0.1.0"}
```

Open `https://your.domain/` — login screen appears, pick a name + room,
hit Join. A second browser tab joining the same room sees your messages
in real time.

## Local dev

```sh
cd web
npm install
npm start           # http://127.0.0.1:8787
```

`npm run dev` enables `node --watch` so server reloads on edits.

## File layout

```
web/
├── package.json            deps: express, ws
├── server/
│   └── server.js           Express static + WS relay on /ws
├── public/
│   ├── index.html          SPA shell + view templates
│   ├── style.css           Nord palette + layout (mirrors desktop)
│   └── app.js              ES module: login, chat, ws client
└── README.md
```

## Wiring up real Tox (next step)

The relay protocol uses these WS message types (server → client):

| `t`     | payload                                |
| ------- | -------------------------------------- |
| welcome | `{ id, room, roster }`                 |
| join    | `{ id, name }`                         |
| leave   | `{ id, name }`                         |
| msg     | `{ fromId, fromName, body, ts }`       |

To switch to Tox, replace the in-memory `rooms` registry with a
`c-toxcore` binding (`@toxchat/toxcore-napi` or similar). For each
connected WebSocket:

1. Spawn / attach a Tox handle (saved per user session).
2. Call `tox_iterate` in the Node event loop.
3. Forward `tox_friend_message` events to the WS as `t: 'msg'`.
4. Forward `t: 'msg'` from WS to `tox_friend_send_message`.

The frontend doesn't need to change — same message shape.

## What's NOT here yet

- File transfer
- Voice / video calls
- E2E encryption (currently relay is plain — TLS to browser, but server
  sees plaintext). Adding libsodium.js E2E is a follow-up.
- Persistence (process restart wipes rooms — fine for chat, not for
  history). Drop-in: SQLite via `better-sqlite3`.
- Auth (anyone can join any room). Drop-in: signed cookies or one-time
  invite tokens.

## License

GPL-3.0-or-later (same as ztox desktop).
