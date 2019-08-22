//import "package:test/test.dart";
import 'package:flutter_test/flutter_test.dart';
import 'package:taqo_survey/model/experiment_core.dart';
import 'dart:convert';
import 'package:taqo_survey/model/experiment.dart';

void main() {

  test("generate json for ExperimentCore", () {

    String jsonString = "{"+
        "\"title\": \"Everything Demo New\","+
        " \"description\": \"\","+
        "\"creator\": \"user1@example.com\","+
        "  \"contactEmail\": \"user1@example.com\","+
        "  \"id\": 1"+ "}";

    Map experimentMap = jsonDecode(jsonString);
    var experiment = ExperimentCore.fromJson(experimentMap);
    expect(experiment.title, equals("Everything Demo New"));
  });


  test("generate json for Experiment (subclass of ExperimentCore", () {

    String jsonString = "{"+
        "\"title\": \"Everything Demo New\","+
        " \"description\": \"\","+
        "\"creator\": \"user1@example.com\","+
        "  \"contactEmail\": \"user1@example.com\","+
        "  \"id\": 1," +
        " \"published\":true " +
        "}";

    Map experimentMap = jsonDecode(jsonString);
    var experiment = Experiment.fromJson(experimentMap);
    expect(experiment.title, equals("Everything Demo New"));
    expect(experiment.published, equals(true));
  });

  test("generate json for List of Experiments", () {

    String jsonString = "[{"+
        "\"title\": \"Everything Demo New\","+
        " \"description\": \"\","+
        "\"creator\": \"user1@example.com\","+
        "  \"contactEmail\": \"user1@example.com\","+
        "  \"id\": 1," +
        " \"published\":true " +
        "}]";

    List experimentListMap = jsonDecode(jsonString);
    var experiment = Experiment.fromJson(experimentListMap.elementAt(0));
    expect(experiment.title, equals("Everything Demo New"));
    expect(experiment.published, equals(true));
  });
}