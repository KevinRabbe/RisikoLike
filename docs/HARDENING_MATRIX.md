# ATLAS // FRONT — M15 Hardening Matrix

M15 keeps the game host-authoritative and exercises rejection paths before release packaging.

## Covered in the repository

- malformed `NetworkMessage` and `CommandEnvelope` payloads
- unknown commands, null envelopes, stale revisions, duplicate action IDs
- repeated disconnect/reconnect cycles and already-connected rejection
- minimum turn-timer and reconnect-window validation
- one-shot timer warnings and lifecycle transitions
- player-scoped snapshot restoration and fingerprint equality
- five-player snapshot coverage and hidden-information boundaries
- backend version mismatch, token binding/rotation/replay, rate limits, TTL, lobby-full, host/client quit, oversized signaling messages, and TURN credential expiry
- WebRTC reconnect generations through the existing M10/M11 harnesses

## Deliberately release-gated outside this local suite

Real internet routing, an externally forced TURN relay, and backend-process restart persistence remain M16 release-candidate checks. The backend intentionally keeps only short-lived rendezvous metadata; it does not persist authoritative game state.
