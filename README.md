# KID COMM 3000

Futuristisches Walkie-Talkie als Progressive Web App für Kinder. Zwei Smartphones, ein QR-Code, echte Echtzeit-Sprachübertragung über WebRTC — und sechs komplett unterschiedliche Modi mit jeweils eigenem UI, Sound-Design und Transmit-Signal.

## Features

- **6 Modi mit eigenem UI** — POLIZEI, FEUERWEHR, RETTUNG, ASTRONAUT, PIRATEN, NINJA. Beim Kanalwechsel ändern sich Farben, Hintergrund-Animationen (Blaulicht-Strobes, Glut, EKG, Sternenfeld, Anker-Deck, Scanline + Shuriken), Icons und Sound-Profil. Der Modus wird zwischen beiden Geräten synchronisiert.
- **Tap-to-Talk (Toggle)** — kinderfreundlich: einmal tippen zum Sprechen, nochmal tippen zum Stoppen. Kein Dauerdrücken nötig.
- **Power-Off-Button** — sauberes Herunterfahren mit Sound-Sequenz und kompletter WebRTC-Trennung.
- **Fullscreen HUD-Design** — Orbitron-Font, Neon-Glow, kein Geräterahmen, bildschirmfüllend.
- **Live Audio-Visualizer** — radiales Spektrum aus der `AnalyserNode`, färbt sich beim Senden rot.
- **Stimmen-Verzerrer** — NORMAL / ROBOTER (Ring-Modulation) / TIEF (Low-Pass + Saturation) / HOCH (Bandpass hoch) / ALIEN (Tremolo + Distortion). Wirkt auf den ausgehenden Audio-Track.
- **Radio-Sound-Verarbeitung** — eingehende Sprache läuft durch Highpass → Bandpass → Tanh-Distortion mit pro Modus unterschiedlichen Parametern. Dauerhaftes Hintergrund-Rauschen (Pink Noise, Highpass).
- **Mode-spezifische Ruf-Töne** — Polizei-Sirene, Airhorn, Ambulance-Beep, Space-Sweep mit Delay-Feedback, Schiffsglocke, Ninja-Strike.
- **SOS-Button** — sendet Morse-SOS (· · · − − − · · ·) an das andere Gerät und vibriert.
- **QR-Code Pairing** — beide Geräte können Code anzeigen *oder* scannen. PeerJS Free-Broker als Signaling. Kein Backend, kein Account, kein API-Key.
- **PWA** — installierbar über "Zum Home-Bildschirm hinzufügen", offline-fähig per Service Worker (Cache-First für die App-Shell).

## Stack

- **Vanilla HTML / CSS / JS** — keine Build-Tools nötig, alles liegt als Quelltext im Repo.
- **[PeerJS](https://peerjs.com)** — WebRTC-Wrapper + kostenloser Signaling-Broker.
- **[qrcode.js](https://github.com/soldair/node-qrcode)** — QR-Code generieren.
- **[html5-qrcode](https://github.com/mebjas/html5-qrcode)** — QR-Code scannen (Rückkamera).
- **Web Audio API** — Rauschen, Filter, Distortion, Visualizer, Effekte.

## Dateistruktur

```
kid-comm-3000/
├── index.html          Die komplette App (HTML + CSS + JS inline)
├── manifest.webmanifest PWA-Manifest
├── sw.js               Service Worker (Offline-Cache)
├── icons/              App-Icons (SVG)
│   ├── icon-192.svg
│   ├── icon-512.svg
│   └── icon-maskable-512.svg
├── .nojekyll           Sagt GitHub Pages: nicht durch Jekyll schleusen
├── .gitignore
└── README.md
```

## Auf GitHub Pages veröffentlichen

Die App ist eine rein statische Seite — jeder statische Host funktioniert. Anleitung für GitHub Pages:

1. **Repo anlegen**

   Auf GitHub einen neuen, öffentlichen oder privaten Repo anlegen, z. B. `kid-comm-3000`.

2. **Code pushen**

   Im Projektordner (`~/Documents/kid-comm-3000`):

   ```bash
   cd ~/Documents/kid-comm-3000
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin https://github.com/<DEIN-USERNAME>/kid-comm-3000.git
   git push -u origin main
   ```

3. **Pages aktivieren**

   Repo auf GitHub öffnen → **Settings** → **Pages** → unter **Source** `Deploy from a branch` wählen → Branch `main`, Ordner `/ (root)` → **Save**.

   Nach ~1 Minute ist die Seite live unter `https://<dein-username>.github.io/kid-comm-3000/`.

4. **Auf dem Handy öffnen**

   Die URL auf beiden Handys im Browser öffnen (Chrome oder Safari). HTTPS ist automatisch gegeben — wichtig, weil WebRTC und Mikrofon-Zugriff HTTPS voraussetzen. Auf "EINSCHALTEN" tippen, Mikrofon erlauben, Kamera erlauben (für QR-Scanner).

5. **Zum Homescreen hinzufügen** (optional, für Fullscreen-App ohne Browser-UI)

   - **iOS Safari:** Teilen-Icon → *Zum Home-Bildschirm*
   - **Android Chrome:** Menü (⋮) → *Zum Startbildschirm hinzufügen* / *App installieren*

## Benutzung

1. Beide Kinder tippen auf **EINSCHALTEN** und erlauben Mikrofon + Kamera.
2. Ein Kind tippt auf **📡 CODE** — es erscheint ein QR-Code.
3. Das andere Kind tippt auf **📷 SCAN** und scannt den QR-Code.
4. Verbunden! Der kleine Punkt oben rechts wird grün.
5. Auf den großen **TIPPEN** Button drücken zum Sprechen, nochmal drücken zum Stoppen.
6. Mit **◀** und **▶** zwischen den 6 Modi wechseln (das komplette Interface morpht dann).
7. **📢 RUF** sendet den Mode-spezifischen Alarm-Ton an das andere Gerät.
8. **🎭 NORMAL** wechselt den Stimmen-Effekt (Roboter, Alien, …).
9. **🆘 SOS** sendet ein Morse-SOS und lässt das andere Handy vibrieren.
10. **⏻** links oben schaltet das Funkgerät aus.

## Infrastruktur & Limits

- **Signaling:** PeerJS Free-Broker (`0.peerjs.com`). Keine Garantie, aber sehr stabil im Alltag.
- **STUN:** über PeerJS / browser default.
- **TURN:** *nicht enthalten*. In ~10–15 % der Fälle (z. B. Mobilfunk-CGNAT, sehr strikte Firmen-Firewalls) scheitert die direkte P2P-Verbindung. Im gleichen WLAN klappt es praktisch immer.

  Wenn das ein Problem wird: TURN-Server einbinden. Zwei einfache Optionen:

  - **[Metered.ca](https://www.metered.ca/stun-turn)** — Free-Tier mit 500 MB/Monat. Credentials eintragen und `new Peer(undefined, { config: { iceServers: [...] }})` ergänzen.
  - **Eigener coturn-Server** auf einem 5-€-VPS (Hetzner, Netcup, …).

- **Browser:** getestet auf iOS Safari 16+ und Android Chrome. Firefox sollte auch funktionieren.

## Lizenz

MIT — benutz es, teile es, bau es um.
