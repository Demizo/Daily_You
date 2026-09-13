# App Screenshot Generation

## Run

```bash
./tool/screenshots/generate_screenshots.sh
```

To iterate quickly on layout without waiting on every locale, restrict the run to one ARB code:

```bash
SCREENSHOT_LOCALE=en ./tool/screenshots/generate_screenshots.sh
```

Output lands in `build/screenshots_staging/<fastlane-locale>/images/phoneScreenshots/`.

Prompt the screenshots to the fastlane metadata with, or accept the promotion prompt after generating the screenshots:

```bash
dart run tool/promote_screenshots.dart
```

