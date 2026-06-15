// ztox web client. Vanilla JS, no build step — drop into FastPanel as-is.
//
// State is intentionally simple: a Room model (name, roster, messages),
// a small WS client, and two views (login, chat) rendered from <template>
// elements in index.html.

const $ = (sel, root = document) => root.querySelector(sel);
const $$ = (sel, root = document) => Array.from(root.querySelectorAll(sel));

const App = (() => {
  const state = {
    me: null,          // { id, name }
    room: null,        // string
    roster: [],        // [{ id, name }]
    messages: [],      // [{ id, fromId, fromName, body, ts, kind }]
    ws: null,
    autoReconnect: true,
  };

  const root = $('#app');

  // ---- view: login ----
  function showLogin() {
    root.innerHTML = '';
    const tpl = $('#t-login').content.cloneNode(true);
    root.appendChild(tpl);
    const nameInput = $('#login-name');
    const roomInput = $('#login-room');
    const savedName = localStorage.getItem('ztox.name');
    const savedRoom = localStorage.getItem('ztox.room');
    if (savedName) nameInput.value = savedName;
    if (savedRoom) roomInput.value = savedRoom;
    nameInput.focus();
    $('#login-enter').addEventListener('click', () => {
      const name = nameInput.value.trim();
      const room = (roomInput.value.trim() || 'lobby');
      if (!name) { nameInput.focus(); return; }
      localStorage.setItem('ztox.name', name);
      localStorage.setItem('ztox.room', room);
      connect(name, room);
    });
    nameInput.addEventListener('keydown', e => { if (e.key === 'Enter') $('#login-enter').click(); });
    roomInput.addEventListener('keydown', e => { if (e.key === 'Enter') $('#login-enter').click(); });
  }

  // ---- view: chat ----
  function showChat() {
    root.innerHTML = '';
    const tpl = $('#t-chat').content.cloneNode(true);
    root.appendChild(tpl);
    renderSelf();
    renderRoster();
    renderRoom();
    renderMessages();
    bindComposer();
  }

  function renderSelf() {
    if (!state.me) return;
    $('#self-name').textContent = state.me.name;
    $('#self-avatar').textContent = initial(state.me.name);
  }
  function renderRoom() {
    $('#peer-name').textContent = '#' + state.room;
    $('#peer-sub').textContent = state.roster.length + ' online';
    $('#peer-avatar').textContent = '#';
  }
  function renderRoster() {
    const list = $('#roster');
    if (!list) return;
    list.innerHTML = '';
    for (const p of state.roster) {
      const li = document.createElement('li');
      const av = document.createElement('div'); av.className = 'avatar'; av.textContent = initial(p.name);
      const txt = document.createElement('div'); txt.className = 'roster-text';
      const n = document.createElement('div'); n.className = 'roster-name'; n.textContent = p.name;
      const s = document.createElement('div'); s.className = 'roster-sub'; s.textContent = p.id === state.me?.id ? 'you' : 'online';
      txt.appendChild(n); txt.appendChild(s);
      const dot = document.createElement('div'); dot.className = 'status-dot online';
      li.appendChild(av); li.appendChild(txt); li.appendChild(dot);
      list.appendChild(li);
    }
  }
  function renderMessages() {
    const ol = $('#messages');
    if (!ol) return;
    ol.innerHTML = '';
    for (const m of state.messages) ol.appendChild(buildMessageNode(m));
    ol.scrollTop = ol.scrollHeight;
  }
  function appendMessage(m) {
    state.messages.push(m);
    const ol = $('#messages');
    if (!ol) return;
    ol.appendChild(buildMessageNode(m));
    ol.scrollTop = ol.scrollHeight;
  }
  function buildMessageNode(m) {
    const li = document.createElement('li');
    if (m.kind === 'sys') {
      li.className = 'sys';
      li.textContent = m.body;
      return li;
    }
    const isMe = m.fromId === state.me?.id;
    li.className = isMe ? 'me' : 'peer';
    const bubble = document.createElement('div'); bubble.className = 'bubble';
    if (!isMe) {
      const meta = document.createElement('span'); meta.className = 'meta'; meta.textContent = m.fromName;
      bubble.appendChild(meta);
    }
    const text = document.createElement('span'); text.textContent = m.body;
    bubble.appendChild(text);
    li.appendChild(bubble);
    return li;
  }

  function bindComposer() {
    const input = $('#msg-input');
    const send  = $('#msg-send');
    const submit = () => {
      const body = input.value.trim();
      if (!body) return;
      sendMessage(body);
      input.value = '';
      input.focus();
    };
    send.addEventListener('click', submit);
    input.addEventListener('keydown', e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); submit(); } });
    input.focus();
  }

  function initial(name) {
    return (name || '?').trim().slice(0, 1).toUpperCase();
  }

  // ---- ws ----
  function connect(name, room) {
    const proto = location.protocol === 'https:' ? 'wss' : 'ws';
    const url = proto + '://' + location.host + '/ws';
    const ws = new WebSocket(url);
    state.ws = ws;
    state.room = room;
    state.messages = [];
    state.roster = [];
    state.me = null;

    ws.addEventListener('open', () => {
      ws.send(JSON.stringify({ t: 'hello', name, room }));
    });
    ws.addEventListener('message', (ev) => {
      let msg; try { msg = JSON.parse(ev.data); } catch { return; }
      onServer(msg, name);
    });
    ws.addEventListener('close', () => {
      if (state.autoReconnect) {
        appendSys('Disconnected, reconnecting…');
        setTimeout(() => connect(name, room), 1500);
      }
    });
    ws.addEventListener('error', () => {});
    showChat();
    appendSys('Connecting to room "' + room + '"…');
  }

  function appendSys(text) {
    appendMessage({ id: 's' + Date.now(), kind: 'sys', body: text });
  }

  function onServer(msg, myName) {
    switch (msg.t) {
      case 'welcome':
        state.me = { id: msg.id, name: myName };
        state.roster = msg.roster;
        renderSelf();
        renderRoster();
        renderRoom();
        appendSys('Joined #' + msg.room);
        break;
      case 'join':
        state.roster.push({ id: msg.id, name: msg.name });
        renderRoster();
        renderRoom();
        appendSys(msg.name + ' joined');
        break;
      case 'leave':
        state.roster = state.roster.filter(p => p.id !== msg.id);
        renderRoster();
        renderRoom();
        appendSys(msg.name + ' left');
        break;
      case 'msg':
        appendMessage({
          id: msg.fromId + ':' + msg.ts,
          fromId: msg.fromId,
          fromName: msg.fromName,
          body: msg.body,
          ts: msg.ts,
        });
        break;
    }
  }

  function sendMessage(body) {
    if (!state.ws || state.ws.readyState !== WebSocket.OPEN) return;
    state.ws.send(JSON.stringify({ t: 'msg', body }));
    // Optimistic local echo
    appendMessage({
      id: 'self:' + Date.now(),
      fromId: state.me?.id,
      fromName: state.me?.name,
      body,
      ts: Date.now(),
    });
  }

  return { start: showLogin };
})();

App.start();
