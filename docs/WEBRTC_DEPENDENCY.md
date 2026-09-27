# WebRTC-Dependency für M8

## Auswahl

Verwendet wird `godotengine/webrtc-native`, Release `1.1.0-stable` (Commit `b45d3a3`). Die offizielle Release-Dokumentation nennt die GDExtension als kompatibel mit Godot 4.1+; das Projekt ist auf Godot 4.7.2 festgelegt. Die Release enthält Windows-x86_64-Debug- und Release-Binaries.

- Quelle: [godotengine/webrtc-native Releases](https://github.com/godotengine/webrtc-native/releases)
- Release-Asset: `godot-extension-webrtc.zip`
- Geprüfte SHA-256 der verwendeten ZIP: `5A0B01B279A1D04B36DDE7273469FCF00839D6CDB1F274A32960D94ACF347C77`
- Plugin-Lizenz: MIT
- Drittanbieter-Lizenzen: im Repository unter `third_party/webrtc_native/LICENSE.*`; laut Upstream insbesondere MPL-2.0 für libdatachannel/libjuice, BSD-3-Clause für libsrtp/usrsctp und Apache-2.0 für mbedTLS.

Ins Repository wurden nur `webrtc.gdextension`, die Windows-x86_64-Debug-/Release-DLLs und die mitgelieferten Lizenzdateien übernommen. Nicht benötigte Android-, Linux-, macOS- oder iOS-Binaries wurden nicht übernommen.

## Integration

`WebRTCNetworkTransport` verwendet die vorhandene `NetworkTransport`-Grenze. Signaling läuft über `BackendClient`/WebSocket; Game Messages laufen ausschließlich über den zuverlässigen, geordneten Data Channel `reliable`. Die Domain kennt weder WebRTC noch das Backend.

## STUN/TURN

ICE-Server werden vom Backend als `ice_servers` geliefert und nicht im Game-Code hartcodiert. TURN kann über `/v1/lobbies/{lobby_id}/turn-credentials` mit kurzlebigen coturn-kompatiblen Credentials bereitgestellt werden; echte Secrets werden nur über Environment-Variablen gesetzt.

Die verwendete GDExtension stellt in ihrer Godot-API keinen verlässlich erzwingbaren `relay-only`-Schalter bereit. Deshalb ist TURN vorbereitet und konfigurierbar, aber in diesem Checkout nicht als tatsächlich ausgewählter Relay-Pfad behauptet. Eine erzwungene TURN-Abnahme bleibt **MANUAL VALIDATION REQUIRED**.
