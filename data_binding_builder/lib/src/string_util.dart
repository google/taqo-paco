String snakeCaseToCamelCase(String string) {
  if (string == null) {
    return null;
  }
  var wordList = string.split('_').skipWhile((s) => s.isEmpty);
  return wordList.isEmpty
      ? ''
      : wordList.first.toLowerCase() +
          wordList.skip(1).map(toSentenceCase).join();
}

String toSentenceCase(String string) => (string == null || string == '')
    ? string
    : string[0].toUpperCase() + string.substring(1).toLowerCase();

String templateFormat(String template, Map<String, String> map) =>
    template?.replaceAllMapped(
        RegExp('\{\{([^{}]+)\}\}'),
        (Match m) =>
            ((map ?? {})['${m[1]}']) ??
            (throw ArgumentError(
                'The replacement for placeholder ${m[1]} is not specified.')));
