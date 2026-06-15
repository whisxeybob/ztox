# ztox iOS

SwiftUI client. Status: **scaffold** — UI is wired up against a stubbed
`ToxRuntime`. The real `c-toxcore` backend gets wired in after running
`scripts/build-toxcore-xcframework.sh` (requires Xcode).

## Quick start (when Xcode is installed)

```sh
brew install xcodegen
cd ios
xcodegen          # generates ZtoxiOS.xcodeproj from project.yml
open ZtoxiOS.xcodeproj
# Cmd+R to run in the iOS simulator
```

The first launch shows **Create profile** → username field → tap. After
that you see an empty contact list with `+` in the top right to add a
friend by Tox ID (76 hex chars).

## Wiring up the real Tox backend

The current scaffold runs entirely in Swift with no network — friend
requests don't actually go out, messages stay local. To make it real:

1. **Install Xcode** from the App Store (~15 GB, 30–60 min download).
2. **Build the toxcore xcframework:**
   ```sh
   bash ios/scripts/build-toxcore-xcframework.sh
   ```
   Produces `ios/Frameworks/CToxcore.xcframework` from the upstream
   TokTok/c-toxcore for arm64-device + arm64-simulator + x86_64-simulator.
3. **Edit `project.yml`:** uncomment the `FRAMEWORK_SEARCH_PATHS` and
   `dependencies:` block so XcodeGen links the xcframework.
4. **Replace the stub in `ZtoxiOS/Models/ToxRuntime.swift`** — every
   method has a `STUB` / `Real impl:` comment showing the equivalent
   `tox_*` C call. The Swift surface (`@Published var connection`,
   `addFriend`, `send`) stays the same, so views don't change.
5. `xcodegen && open ZtoxiOS.xcodeproj` and run.

## Architecture (v1)

**Foreground-only.** The app is online while the user has it open. iOS
suspends background sockets within ~30 s, so any background-presence
story needs a push-relay server, which trades anonymity for delivery
and is intentionally out of scope for v1. See the project root README
for the trade-off.

That means:
- No push notifications. Messages arrive when you open the app.
- 1:1 chat works fully (text first; AV is a follow-up).
- Group chats (NGC) follow the same constraint as desktop — history is
  whatever the client saw while online.

## File layout

```
ios/
├── project.yml                          XcodeGen spec — single source of truth
├── ZtoxiOS/
│   ├── App.swift                        @main, owns ToxRuntime
│   ├── Theme/
│   │   └── Nord.swift                   Color tokens, mirrors shared/nord/palette.ini
│   ├── Models/
│   │   ├── ToxRuntime.swift             ObservableObject — stub today, real Tox tomorrow
│   │   └── Friend.swift                 Friend + Message structs
│   └── Views/
│       ├── RootView.swift               Profile-setup gate
│       ├── ProfileSetupView.swift       First-run username screen
│       ├── ContactListView.swift        Friend list + nav
│       ├── ContactRow                   (in same file)
│       ├── AddFriendSheet.swift         Tox ID + greeting form
│       ├── ProfileSheet.swift           Self profile + Tox ID copy
│       └── ChatView.swift               Messages + composer
├── scripts/
│   └── build-toxcore-xcframework.sh     Cross-compiles c-toxcore for iOS
└── README.md                            This file.
```

## Min deployment

iOS 16. SwiftUI features below 16 are too painful to backport for the
gain.

## What this scaffold does NOT do

- **Voice / video calls.** Requires `toxav` + AVFoundation pipeline.
  Separate ~30–50 h of work; placeholders are in `ChatView.swift`.
- **File transfers.** Requires `tox_file_*` + Files app integration.
- **Push delivery.** Needs a relay server architecture decision first.
- **App Store submission.** Needs an Apple Developer account ($99/yr)
  and code signing setup; out of scope.
