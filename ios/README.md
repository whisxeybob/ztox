# ztox iOS — roadmap

The iOS client does not exist yet. This file exists so the trade-offs are
written down before code is.

## Why this is hard

Tox is a P2P protocol with no central server. iOS is hostile to long-lived
P2P sockets on three independent levels:

1. **Background networking.** iOS suspends apps within ~30 seconds of
   backgrounding. A suspended app has no socket and no DHT presence.
2. **No push without a server.** APNS requires a sender. Tox has no sender.
   To get a push when a message arrives, *something* online must observe
   the message and call APNS — which is a relay, which is the centralization
   the protocol exists to avoid.
3. **App Store review.** Apps that "act as a server" or use unconventional
   network behavior get extra scrutiny. Possible but non-zero friction.

Every prior iOS Tox client (Antidote was the most serious attempt) shipped
and then went dormant. None of them solved the above.

## Architecture options

### Option A — foreground-only client
The app is online only when the user is in it. No push. No background
delivery. Honest about what the protocol can and cannot do.
- **Pro:** Zero centralization. No new infrastructure. Matches the Tox
  threat model.
- **Con:** Useless as a primary messenger. Fine as a companion to the
  desktop client.

### Option B — push-relay node
ztox operates a relay node (or the user runs their own) that stays online,
receives messages on behalf of the user, and triggers APNS to wake the app.
The app then connects, downloads the queued messages from the relay, and
the relay forgets them.
- **Pro:** Real-time delivery, works like a normal messenger.
- **Con:** The relay sees ciphertext metadata (who messages whom, when,
  how big). This is the same trade-off Signal makes — and the same one
  Tox was designed to avoid. Must be opt-in, never the default.

### Option C — friend-as-relay
A trusted contact's desktop client acts as the user's relay. No
infrastructure, but only works for users who have a friend running ztox
desktop 24/7.

We start with A. B and C are tracked as separate proposals.

## Tech stack (when we start)

- **Language:** Swift 5.9, SwiftUI for the UI layer.
- **Tox core:** `c-toxcore` cross-compiled as a static xcframework for
  arm64 device + arm64/x86_64 simulator. Wrapped in a thin Swift API
  layer that mirrors the surface used by `desktop/src/core`.
- **Persistence:** GRDB (SQLite). NGC archive in the same schema as the
  desktop archive to make a future sync feature cheap.
- **Theming:** A `NordPalette.swift` generated from `shared/nord/palette.ini`.
- **Min target:** iOS 16. SwiftUI before iOS 16 is too painful for the gain.

## What needs to exist before writing Swift

1. Decision on Option A vs B vs C as the v1 default.
2. A working `c-toxcore.xcframework` build pipeline (script in
   `ios/scripts/build-toxcore.sh`, not yet written).
3. The NGC local-archive design from the desktop side — so iOS inherits
   it instead of reinventing it.

Open this file again when (1)-(3) are done.
