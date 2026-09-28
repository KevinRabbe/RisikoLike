# ATLAS // FRONT — V1 Direct-Host Release Checklist

## Mandatory local gates

- [x] Windows Desktop x86_64 export and embedded PCK
- [x] App identity `ATLAS // FRONT` and version metadata `0.1.0`
- [x] Asset, audio, and WebRTC license records present
- [x] Domain, map, UI, audio, and hardening suites green
- [x] Existing TCP and optional WebRTC regression paths green
- [x] Direct invite codec: version, endpoint, session, join secret, checksum
- [x] Create Lobby works with FastAPI stopped
- [x] Direct two-process Join / Ready / Match / Reinforcement
- [x] Direct reconnect with rotated host-issued credential
- [x] Direct host loss becomes `HOST_UNAVAILABLE` / `TERMINATED`
- [x] Malformed invite and checksum rejection
- [x] Port conflict returns a controlled error
- [x] Three-player direct lobby smoke
- [x] Release package and SHA-256 generated

## Manual/local machine gates

- [ ] Full interactive release EXE smoke from the packaged folder
- [ ] Clean Windows machine or VM test
- [ ] Windows Defender/SmartScreen behavior recorded
- [ ] LAN test using an actual non-loopback address
- [ ] Manual port-forwarding test, if Internet hosting is offered

## Not V1 requirements unless the service is explicitly offered

- FastAPI production deployment
- HTTPS/WSS for the normal direct TCP flow
- TURN relay operation
- Central lobby lookup, accounts, matchmaking, ranked services

The retained FastAPI/WebRTC service remains an optional development/future
prototype. Direct private hosting does not contact `127.0.0.1:8000` by default.

## External Internet gate

`REAL INTERNET DIRECT = MANUAL VALIDATION REQUIRED`.

Only a test with two PCs on two independent networks may mark Internet direct
hosting as passed. CGNAT, restrictive routers, UPnP failure, and the need for
manual port forwarding remain valid V1 limitations.

Status: **TECHNICAL RC PENDING MANUAL MACHINE/LAN GATES**. No tag, release, or
public distribution is created automatically.
