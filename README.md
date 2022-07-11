# ACMS

## Getting Started

1. Make sure you're using next versions:
* Java — 1.8.0_321 (install JDK, not JRE)
* Flutter — 1.22.6
* Dart — 2.10.5
* Kotlin — 1.3.50
* Gradle — 3.5.0

2. Apply patches:
* `./patches/latlng_bounds.dart` — copy that file to `<your-flutter-directory>/.pub-cache/hosted/pub.dartlang.org/flutter_map-0.1.4/lib/src/geo/latlng_bounds.dart`.

```bash
% java -v
java version "1.8.0_321"
Java(TM) SE Runtime Environment (build 1.8.0_321-b07)
Java HotSpot(TM) 64-Bit Server VM (build 25.321-b07, mixed mode)

% flutter --version
Flutter 1.22.6 • channel unknown • unknown source
Framework • revision 9b2d32b605 (1 year, 2 months ago) • 2021-01-22 14:36:39
-0800
Engine • revision 2f0af37152
Tools • Dart 2.10.5
```

2. Execute `flutter create --project-name=acms_mobile_client .` to create/update `./android` directory.
3. Execute `flutter pub get` to install Flutter packages.
4. Update `org.gradle.java.home` value in `./android/gradle.properties`. It should contain path to your JDK directory.
5. Launch Android device in emulator. Execute `flutter devices` to get list of available devices. Copy device ID from there.
6. Execute `flutter run -d emulator-5554`, where `emulator-5554` would be your emulator's device ID from previous step.

For help getting started with Flutter, view online [documentation](https://flutter.io/).

