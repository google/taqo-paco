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

