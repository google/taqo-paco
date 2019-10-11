String snakeCaseToCamelCase(String string) {
  var wordList = string?.split('_');
  return wordList == null
      ? null
      : wordList[0].toLowerCase() +
          wordList.sublist(1).map(sentenceCase).join();
}

String sentenceCase(String string) => (string == null || string == '')
    ? string
    : string[0].toUpperCase() + string.substring(1).toLowerCase();
