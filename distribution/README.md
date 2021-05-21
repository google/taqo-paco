# Building distributable packages for Taqo

## Build .deb package for Linux

### Requirements

- debhelper (>=13) (debhelper 12 seems working, but not guaranteed)
- jq
- chrpath

### Build steps
To create a deb package under `distribution/build`, run the `create_deb_pkg.sh`
script.

## Build .dmg package for macOS

### Requirements

- Flutter 1.22.0-12.0.pre  
  Under Flutter installation directory:

  ```bash
  git checkout 1.22.0-12.0.pre
  flutter doctor
  ```

- Xcode 11.7
  (Xcode 12+ won't work)

- jq

- [create-dmg](https://github.com/sindresorhus/create-dmg)  by sindresorhu

### Build steps

1. Run the `create_macos_app.sh` script
2. Open the macOS project

   ```bash
   open <taqo-paco-root>/taqo_client/macos/Runner.xcworkspace
   ```

3. Follow steps in [Notarizing macOS Software Before Distribution](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)

4. Rename the generated app file to `Taqo.app` and create the dmg file

   ```bash
    create-dmg Taqo.app
   ```