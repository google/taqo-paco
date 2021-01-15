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

import com.pacoapp.intellij.PacoApplicationComponent;
import org.codehaus.jackson.JsonGenerationException;
import org.codehaus.jackson.map.JsonMappingException;
import org.codehaus.jackson.map.ObjectMapper;
import org.joda.time.DateTime;

import java.io.IOException;

public class PacoEventUtil {

  public static final String SENSOR_GROUP_NAME = "**IntelliJLoggerProcess";
    
  public static PacoEvent createEvent() {
    PacoEvent event = new PacoEvent();
    event.setExperimentGroupName(SENSOR_GROUP_NAME);
    event.setResponseTime(new DateTime());
    return event;
  }

  //TODO move to JsonConverter
  public static String jsonify(Object event) {
      ObjectMapper mapper = JsonConverter.getObjectMapper();
      try {
        return mapper.writeValueAsString(event);
      } catch (JsonGenerationException e) {
        PacoApplicationComponent.log.severe("Json generation error: " + e);
      } catch (JsonMappingException e) {
        PacoApplicationComponent.log.severe("JsonMapping error: " + e.getMessage());
      } catch (IOException e) {
        PacoApplicationComponent.log.severe("IO error: " + e.getMessage());
      }
      return null;
    }
}

