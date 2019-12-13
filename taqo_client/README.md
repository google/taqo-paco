# taqo_client

The main Flutter project of Taqo.

## How to launch the client on macOS?
To enable macOS support, one need to switch to `dev` channel of Flutter by
```
flutter channel dev
```
And then run
```
flutter config --enable-macos-desktop
```
Then the macOS option will appear in the IntelliJ drop-down menu (may need to restart IntelliJ).

## How to run the code generators?
This project depends on code generators from `json_serializable` and `data_binding_builder`. In case that regeneration is needed, one can run them by
```
flutter pub run build_runner build
```
