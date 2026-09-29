# ATLAS FRONT — Multiplayer Freeze

Status: **PASS / frozen**

## 1. V1 multiplayer product

V1 multiplayer is private **Direct Host / listen server** multiplayer.

- 2–5 human players in the public V1 lobby flow.
- No central ATLAS FRONT server required for ordinary private matches.
- No public server browser/random matchmaking/ranked/account requirement.
- No mixed human+AI lobby option initially; AI appears only as takeover after surrender/disconnect.
- TCP direct-host baseline remains port **43100** internally/advanced help.

The same GameState/rules/presentation are used as singleplayer; only the decision source may be LocalHuman, RemoteHuman or AI.

## 2. Multiplayer root

Actions:

- MATCH HOSTEN
- MATCH BEITRETEN
- ZURÜCK

If a valid local reconnect credential points to a still-running session, show a `LAUFENDE PARTIE / WIEDERVERBINDEN` card.

## 3. Host setup

Normal host setup includes:

- commander name;
- unique color;
- max players 2–5;
- turn timer;
- concise rules summary;
- private match.

Normal UI does not expose raw ports/protocol fields.

## 4. Invite model

Invite is presented as an opaque code with `CODE KOPIEREN`.

Full AF1/session/secret payload is implementation detail and must not remain permanently visible in the normal lobby.

Join parser may accept the full payload, compact code, copied whitespace/newlines, etc., but player experience is one invite input.

Advanced technical network help may explain TCP 43100, NAT/CGNAT and port forwarding.

## 5. Lobby

Premium prep screen containing:

- player cards;
- match rules/info;
- invite area;
- ready controls;
- host start action.

Player states use constrained badges:

- HOST
- BEREIT
- NICHT BEREIT
- VERBINDUNG VERLOREN

Host is implicitly ready.

Start enabled only when:

- at least 2 players;
- all non-host players are ready;
- setup is valid;
- versions/protocol compatibility is acceptable.

If host changes a match rule, all remote ready states reset and a `MATCHREGELN GEÄNDERT` banner explains that players must ready again.

Display names may duplicate. Colors remain unique.

Host may kick only in lobby and only after confirmation.

Host leaving lobby ends the lobby for everyone.

## 6. Join states

Join pending must be cancellable and not freeze the UI.

Player-facing error classes:

- invalid/expired invite;
- host unreachable;
- lobby full;
- match already started;
- version mismatch.

Direct-host/NAT warning is nonblocking: `DIREKTE VERBINDUNG MÖGLICHERWEISE EINGESCHRÄNKT`.

## 7. Authoritative match start

Host generates authoritatively:

- match seed;
- turn order;
- territory distribution;
- deck order.

Clients receive authoritative snapshot and acknowledge match start before gameplay proceeds.

## 8. Prematch disconnect boundary

During lobby/loading/initial setup, a client disconnect before irreversible match start receives a short recovery opportunity; if required player state cannot be safely preserved, roll back to lobby rather than silently creating AI ownership.

Irreversible `MATCH_STARTED` boundary is after initial deployment reveal completes and Round 1 begins.

Before that boundary, rollback-to-lobby is allowed.

After that boundary, live-match reconnect/takeover rules apply.

## 9. Secret initial deployment

Multiplayer initial deployment uses the same Simultaneous Planning → Visible Reveal model.

Public information before reveal:

- who is planning;
- who has committed/ready.

Private information:

- actual allocation contents.

Uncommitted plan may be client-local and lost on disconnect. Committed plan is authoritative/persisted for the session.

## 10. Pause/overlay semantics

Multiplayer never globally pauses because one client opens a menu/overlay.

Local menu explicitly says: `Die Partie läuft weiter.`

Turn timer continues while local player browses settings/rules/cards.

Mandatory responses, especially defense, take priority over lower overlays and may close/background them.

## 11. Public vs private interaction

Public semantic events include:

- committed reinforcement;
- selected meaningful attack source/target when intentionally broadcast;
- dice count/roll/result;
- conquest;
- fortification;
- elimination.

Private/local-only:

- hover;
- cursor;
- uncommitted reinforcement plan;
- uncommitted fortification plan;
- opponent card identities;
- secret initial deployment contents.

## 12. Host-authoritative timer

Host owns multiplayer timer truth. Clients only present synchronized countdown.

Small drift may smooth-correct. Large reconnect discrepancies snap to host value.

## 13. Disconnect: defending player

Connected human defense timeout is 10 seconds and chooses maximum legal defense dice.

A disconnected defender uses **immediate maximum legal defense** for each required defense decision so the match does not stall 10 seconds on every roll.

## 14. Disconnect: active player

When active player disconnects, begin **60-second reconnect grace**.

Normal turn timer is effectively not consumed as ordinary decision time during this reconnect grace.

All participants see connection-lost state/countdown.

On successful reconnect:

- apply filtered authoritative snapshot;
- restore remaining host-authoritative turn time;
- discard stale local hover/preview/selection caches;
- normalize uncommitted attack selection to a safe state such as `ATTACK_IDLE`.

If a combat roll had already committed, host resolves it exactly once. Reconnect receives resolved state; no reroll.

## 15. Grace expiry

If active-player grace expires:

- mandatory forced trade/reinforcement/conquest states auto-complete safely;
- Attack ends;
- Fortification is skipped;
- normal end-turn/card behavior completes as required;
- player remains marked disconnected.

If still disconnected when **their next own turn begins**, convert that player slot permanently to AI decision source.

## 16. Voluntary leave/surrender

Remote human leaving an active multiplayer match does **not** distribute/delete their position.

Atomically change decision source:

`RemoteHuman → AI`

The slot retains:

- territories;
- armies;
- cards;
- color;
- symbol;
- name;
- turn-order position.

This is permanent. The human cannot later reclaim the active slot after voluntary surrender/leave.

Player card badge: `KI ÜBERNOMMEN`.

AI-controlled surrendered slot remains a valid participant and can win.

## 17. Host special case

No host migration in V1.

If host intentionally leaves or the host process/session is finally lost, the match ends for all clients with `HOST NICHT MEHR VERFÜGBAR`.

The host cannot be replaced by an AI as network host.

If host is eliminated through gameplay, they remain connected as spectator while continuing to host the network session. If that spectator host leaves, match ends.

## 18. Atomic leave behavior

Surrender/leave requested during an atomic committed gameplay action is queued until the action reaches a safe end.

If it occurs before an uncommitted mandatory decision, the new AI decision source completes the decision using normal AI behavior.

## 19. Spectator after elimination

Public arbitrary spectator join is not V1.

An eliminated connected human becomes spectator by default.

They may:

- watch board/camera;
- view public history;
- open rules/settings;
- see player cards/counts.

They may not issue gameplay commands or view private hands.

Transferred cards become private to the new owner immediately, even though the eliminated spectator may have known those cards previously.

## 20. Reconnect identity and privacy

Reconnect identity uses hidden session/player/reconnect credential, never display name.

Player-filtered snapshots:

- local active player receives own card details;
- opponents receive only counts/public info;
- spectator receives only public information;
- private initial placement never leaks before reveal.

No frame may render secret data before filtering.

## 21. Command ordering and idempotency

Network commands use stable `action_id`/revision architecture internally.

Duplicate repeated commands are deduplicated.

Stale commands are rejected and user sees:

`Die Spielsituation hat sich geändert. Bitte wähle erneut.`

Technical revision/action IDs are never shown in normal UI.

Presentation must not display event N+1 before missing N. Buffer/resync on sequence gaps.

## 22. Prediction policy

No aggressive gameplay prediction.

Normal pattern:

`local preview → commit → busy/host wait if necessary → host confirmation → authoritative presentation`

If host response is slow, show `WARTE AUF HOST...` only after a noticeable delay (~1–2 s), not for every normal action.

## 23. Network-busy input spam

Once a commit button has sent an action to host, repeated mouse/keyboard activation of that same command is ignored until host responds or connection state changes.

Do not auto-resend gameplay commands merely because a UI/network timeout elapsed.

## 24. Connection loss exactly at commit

Two valid outcomes:

- host had not accepted command → reconnect snapshot shows old state;
- host accepted command → reconnect snapshot shows new state.

Client never infers authoritative truth from its local animation.

## 25. Host loss terminal state

After short determination/reconnect attempt if used, final host loss is terminal for the session.

No persistent multiplayer save/resume after host ends.

## 26. Post-match/rematch

After normal match completion:

- winner gets ATLAS SECURED variant;
- others/spectators get MATCH BEENDET + winner;
- `ZUR LOBBY` may retain host session;
- ready states reset;
- names/colors/timer/player limit remain where valid;
- replay/rematch uses a new seed/distribution;
- host ending session always overrides remote rematch preference.

## 27. Explicitly out of V1

- public server browser;
- random matchmaking;
- ranked;
- accounts/leaderboards;
- integrated chat/voice;
- Discord integration beyond external invite sharing;
- dedicated-server productization;
- host migration;
- public late spectator join;
- persistent multiplayer save after host session ends;
- tournament/clan systems;
- mixed human+AI lobby setup as a public feature.

## 28. Multiplayer invariants

- exactly one authoritative host;
- connected active user maps to at most one player slot;
- each active slot has exactly one decision source: LocalHuman, RemoteHuman or AI;
- takeover is atomic and revisioned;
- reconnect of active slot is allowed only while it remains a disconnected remote-human slot, not after final AI takeover;
- secret state is player-filtered;
- lobby rules are locked after match start;
- host loss is terminal in V1.