// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// @dart=2.9

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
