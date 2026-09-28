# ATLAS // FRONT — M16 Release Candidate Checklist

## Local release candidate

- [x] Windows Desktop export preset (`ATLAS FRONT // Windows`)
- [x] Embedded PCK / x86_64 metadata
- [x] App identity `ATLAS // FRONT`
- [x] README with controls, source run, backend configuration, and export command
- [x] Audio and WebRTC license records present
- [x] Godot headless/editor validation
- [x] Full domain, map, UI, audio, and hardening suites green
- [x] TCP integration and two-process local WebRTC smoke green

## External release gates

- [ ] Real-network WebRTC from two independent networks
- [ ] Forced TURN relay with public coturn and evidence from ICE candidate/connection state
- [ ] Production TLS endpoint and certificate validation
- [ ] Clean Windows machine/install test
- [ ] Windows Defender/SmartScreen behavior recorded
- [ ] ZIP/SHA256 package generated from the final export

Status: **CONDITIONAL GO** for a local release candidate. Public release is blocked until every external gate above is evidenced; no release/tag/publish action is automated by this repository.
