# ztox

A privacy-first Tox messenger, derived from [qTox](https://github.com/TokTok/qTox).
Nord-styled desktop, an upcoming iOS companion, and stronger defaults for anonymity
and group-chat persistence.

> Status: early scaffolding. The desktop tree is a clean hard fork of qTox at the
> commit imported on the date of the first commit. iOS is roadmap only.

## Goals

1. **Nord aesthetic by default.** A coherent Nord palette across every surface —
   chat list, message bubbles, settings, login, file transfers.
2. **Anonymity by default.** Force SOCKS5/Tor, disable UDP and LAN discovery,
   strip telemetry, hide IP from peers. Opt-out, not opt-in.
3. **Don't lose group dialogs.** Archive every NGC message locally on receipt
   so leaving and rejoining a group does not erase the timeline. Surface clearly
   that the protocol still can't deliver offline messages to peers — we keep
   what we saw, we don't fabricate what we didn't.
4. **iOS companion.** A SwiftUI client that shares the Nord palette and
   protocol assumptions. Foreground-only at first; push-relay is a separate
   discussion (it trades anonymity for delivery).

## Repository layout

```
ztox/
├── desktop/        Hard fork of qTox (C++ / Qt5). Builds with the upstream
│                   instructions in desktop/INSTALL.md.
├── ios/            SwiftUI client. Roadmap only — see ios/README.md.
├── shared/
│   ├── nord/       Canonical Nord palette (palette.ini). Both clients derive
│   │               their concrete palettes from this one.
│   └── branding/   Logos, app icons, marketing assets.
└── docs/           Design notes, threat model, anonymity defaults.
```

## Relationship to qTox

`desktop/` started as a copy of TokTok/qTox. We track upstream via a git remote
named `upstream` and periodically rebase bug fixes from it. We are not
attempting to upstream ztox-specific changes — they are deliberate divergences
in defaults and aesthetic.

License: GPL-3.0, inherited from qTox. See `desktop/LICENSE`.

## Quick start (desktop)

```sh
cd desktop
# follow desktop/INSTALL.md — same toolchain as qTox
```

## Privacy posture (honest version)

ztox is a Tox client. Tox is end-to-end encrypted, peer-to-peer, and has
no central server — that is automatic and ztox does not change it.

What Tox does NOT hide on its own: **your IP address is visible to any
peer you connect to directly**. ztox does not change this by default.

If you want to hide your IP from peers, turn on a SOCKS5 proxy in
*Settings → Advanced → Proxy* (typical setup: Tor on `127.0.0.1:9050`,
plus *Force TCP*). This is opt-in, not the default — forcing a SOCKS5
proxy as the default breaks first-run for users who don't run Tor.

## Roadmap

- [x] Hard-fork qTox into `desktop/`
- [x] Nord palette in `shared/nord/` and `desktop/themes/nord/`
- [ ] Surface Nord in the desktop theme picker (`desktop/src/widget/style.cpp`)
- [ ] Anonymity-by-default settings preset (SOCKS5, no UDP, no LAN)
- [ ] Local NGC message archive (so group history survives rejoin)
- [ ] iOS client scaffold (SwiftUI + c-toxcore xcframework)
