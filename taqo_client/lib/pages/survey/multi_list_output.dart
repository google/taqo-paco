class MultiListOutput {
  List<String> listChoices;
  var answers;

  MultiListOutput(List<String> listChoices)
      : this.allParameters(listChoices, {});

  MultiListOutput.allParameters(
      List<String> listChoices, Map<String, bool> answers) {
    this.answers = answers;
    this.listChoices = listChoices;
    listChoices.forEach((choice) {
      if (answers[choice] == null) {
        answers[choice] = false;
      }
    });
  }

  String stringifyAnswers() {
    List<int> selected = [];
    var i = 1;
    for (var value in listChoices) {
      if (answers[value]) {
        selected.add(i);
      }
      i++;
    }
    return selected.join(",");
  }

  int countSelected() {
    return listChoices.where((choice) => answers[choice]).toList().length;
  }
}
