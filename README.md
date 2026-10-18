# AI Video Editor Pro — Flutter starter

This is a prototype starter project, not a finished production video editor or ready-made APK.

## Included in this starter
- Dark professional-style Flutter UI
- Local video selection and playback
- Voice input with selectable Hindi, Bengali, and English locale IDs (device speech support varies)
- Basic command demo for brightness/saturation/blur toggle/playback
- Color grading controls that currently affect preview parameters only

## Not yet included
- Actual rendered video export with effects baked in
- AI cloud command understanding
- Subject-aware background blur / segmentation
- Auto subtitles, music generation, full timeline, LUT import, or 4K export
- A secure AI backend/API integration

## Build
Install Flutter SDK and Android build tools on a computer or use a trusted cloud CI service. From this project directory:

```bash
flutter pub get
flutter build apk --release
```

The APK will normally be at `build/app/outputs/flutter-apk/app-release.apk`.

## Important
Do not put private AI API keys inside the Android app. Route requests through a secure backend you control. Test all generated APKs before installing them.
