# Build the IntelliJ plugin for multiple versions of the IDE

This tool reads a list of IntelliJ versions (including Android Studio) from
`flutter-intellij/product-matrix.json` as the versions of the IDE we plan to 
support and then downloads each version of the IDE to compile Taqo's IntelliJ
plugin. To use,

1. Set `buildSpec` in `lib/builder.dart` to a proper version of 
   `flutter-intellij`.
   
2. (Optional) Edit `lib/patches.dart` to reflect the latest updates.

3. Run `bin/builder.dart` from the root directory of the plugin, with the 
   `--no-sound-null-safety` option.

4. (Optional) May need to repeat Step 2 to fix compilation errors, if there is 
   any.
