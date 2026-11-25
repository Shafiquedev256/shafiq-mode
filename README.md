# Shafiq mode

Offline-first, privacy-first Flutter music player (Android).

- Plays local audio (app downloads + `Music`/`Download` folders), including with the screen locked (media notification + lock-screen controls).
- With internet: search YouTube (or paste a link) and download **audio-only** streams at low / balanced / high quality, or any specific stream.
- **Internet kill switch** (Control tab) blocks every network call in the app.
- Shuffle, repeat, speed, sleep timer, search/sort, accent colors, motion animations.

## Honest notes
- Downloads are saved as `.m4a` (AAC) or `.webm` (Opus) — the native YouTube audio streams. Real MP3 conversion needs FFmpeg; not included to keep the app small and dependency-light. Add it behind `YoutubeService.download` if needed.
- YouTube's Terms of Service restrict downloading, and copyright applies. Use only for content you have rights to. `youtube_explode_dart` can break when YouTube changes; update the package when it does.
- Not compiled by the author's tooling; first CI run may need small fixes.

## Supported audio
MP3, AAC/M4A/M4B, FLAC, WAV, OGG/OGA, Opus, WebM, MKA, AMR, 3GP, MIDI, AC3/E-AC3 (what Android's decoders support; see `kAudioExtensions`). Unplayable files are skipped automatically. WMA, APE, AIFF and DSD are not supported by Android natively; adding them requires an FFmpeg-based engine such as `media_kit`.

## Privacy design
No analytics/ads/accounts; `allowBackup=false`; cleartext HTTP disabled; no thumbnails fetched; all network access goes through `lib/core/network_guard.dart`; deleting only touches files the app created.

## Build
Local: `bash tool/bootstrap_android.sh && flutter pub get && dart run flutter_launcher_icons && flutter run`
GitHub: push to `main`; `.github/workflows/build.yml` produces APKs as an artifact. (Release builds are debug-signed until you add a keystore via GitHub Secrets.)

## Structure
```
lib/core    theme, NetworkGuard (single network choke point)
lib/data    models, settings, library scan, YouTube service, downloads
lib/audio   PlayerController (just_audio + background)
lib/ui      pages and widgets
platform/android  manifest + MainActivity applied by tool/bootstrap_android.sh
```
Replace the icon by overwriting `assets/icon/icon.png` and `icon_fg.png`.
