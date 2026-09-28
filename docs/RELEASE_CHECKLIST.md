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
- [x] Windows x86_64 release export generated and started outside the editor
- [x] Release ZIP and SHA-256 generated from the final export

## External release gates

- [ ] Real-network WebRTC from two independent networks
- [ ] Forced TURN relay with public coturn and evidence from ICE candidate/connection state
- [ ] Production TLS endpoint and certificate validation
- [ ] Clean Windows machine/install test
- [ ] Windows Defender/SmartScreen behavior recorded
- [x] ZIP/SHA256 package generated from the final export

Status: **CONDITIONAL GO** for a local release candidate. Public release is blocked until every external gate above is evidenced; no release/tag/publish action is automated by this repository.

## Local evidence — 2026-09-28

- Godot `4.7.2.stable` Windows x86_64 release export completed successfully.
- `builds/windows/ATLAS_FRONT.exe` started from the exported folder with exit code `0`.
- `builds/AtlasFront-0.1.0-windows-x86_64.zip` contains only `ATLAS_FRONT.exe` and `libwebrtc_native.windows.template_release.x86_64.dll`.
- SHA-256: `B6E71B7AE3360B813F98DF2ABC21011F576B05252CEC2E57C3040EB9D30DC256`.
- The same two-file package started successfully from an isolated clean folder. This is local smoke evidence, not a substitute for a separate Windows machine or VM.
