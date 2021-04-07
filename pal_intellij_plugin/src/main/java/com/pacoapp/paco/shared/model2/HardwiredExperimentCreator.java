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

package com.pacoapp.paco.shared.model2;

public class HardwiredExperimentCreator {
  public static ExperimentDAO loadExperiment() {
    String experimentJson = "{\"title\":\"Developer Logging Test 1\"," +
            "\"creator\":\"bobevans@google.com\"," +
            "\"contactEmail\":\"bobevans@google.com\"," +
            "\"id\":4651223384326144," +
            "\"recordPhoneDetails\":false," +
            "\"extraDataCollectionDeclarations\":[]," +
            "\"deleted\":false," +
            "\"modifyDate\":\"2018/02/21\"," +
            "\"published\":true," +
            "\"admins\":[\"bobevans@google.com\"]," +
            "\"publishedUsers\":[]," +
            "\"version\":11," +
            "\"groups\":[{\"name\":\"Survey\"," +
            "\"customRendering\":false," +
            "\"fixedDuration\":false," +
            "\"logActions\":false," +
            "\"logShutdown\":false," +
            "\"backgroundListen\":false," +
            "\"accessibilityListen\":false," +
            "\"actionTriggers\":[]," +
            "\"inputs\":[{\"name\":\"input1\",\"required\":false,\"conditional\":false,\"responseType\":\"open text\",\"text\":\"question 1\",\"likertSteps\":5,\"multiselect\":false,\"invisible\":false,\"numeric\":false,\"nameOfClass\":\"com.pacoapp.paco.shared.model2.Input2\"}]," +
            "\"endOfDayGroup\":false," +
            "\"feedback\":{\"text\":\"Thanks for Participating!\",\"type\":0,\"nameOfClass\":\"com.pacoapp.paco.shared.model2.Feedback\"}," +
            "\"feedbackType\":0," +
            "\"rawDataAccess\":true," +
            "\"logNotificationEvents\":false,\"nameOfClass\":\"com.pacoapp.paco.shared.model2.ExperimentGroup\"}," +
            "{\"name\":\"AppLog\",\"customRendering\":false,\"fixedDuration\":false,\"logActions\":false,\"logShutdown\":false,\"backgroundListen\":false,\"accessibilityListen\":false,\"actionTriggers\":[]," +
            "\"inputs\":[{\"name\":\"input1\",\"required\":false,\"conditional\":false,\"responseType\":\"open text\",\"text\":\"asdasd\",\"likertSteps\":5,\"multiselect\":false,\"invisible\":false,\"numeric\":false,\"nameOfClass\":\"com.pacoapp.paco.shared.model2.Input2\"}]," +
            "\"endOfDayGroup\":false,\"feedback\":{\"text\":\"Thanks for Participating!\",\"type\":0,\"nameOfClass\":\"com.pacoapp.paco.shared.model2.Feedback\"}," +
            "\"feedbackType\":0,\"rawDataAccess\":true,\"logNotificationEvents\":false,\"nameOfClass\":\"com.pacoapp.paco.shared.model2.ExperimentGroup\"}," +
            "{\"name\":\"DevLog\",\"customRendering\":false,\"fixedDuration\":false,\"logActions\":false,\"logShutdown\":false," +
            "\"backgroundListen\":false,\"accessibilityListen\":false,\"actionTriggers\":[],\"inputs\":[]," +
            "\"endOfDayGroup\":false,\"feedback\":{\"text\":\"Thanks for Participating!\",\"type\":0,\"nameOfClass\":\"com.pacoapp.paco.shared.model2.Feedback\"}," +
            "\"feedbackType\":0," +
            "\"rawDataAccess\":true,\"logNotificationEvents\":false,\"nameOfClass\":\"com.pacoapp.paco.shared.model2.ExperimentGroup\"}]," +
            "\"ringtoneUri\":\"/assets/ringtone/Paco Bark\"," +
            "\"postInstallInstructions\":\"<b>You have successfully joined the experiment!</b><br/><br/>\\nNo need to do anything else for now.<br/><" +
            "br/>\\nPaco will send you a notification when it is time to participate.<br/><br/>\\nBe sure your ringer/buzzer is on so you will hear the notification.\"," +
            "\"anonymousPublic\":true,\"visualizations\":[],\"nameOfClass\":\"com.pacoapp.paco.shared.model2.ExperimentDAO\"}";
    return JsonConverter.fromSingleEntityJson(experimentJson);
  }
}
