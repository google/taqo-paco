package com.pacoapp.paco.shared.model2;

import com.pacoapp.intellij.PacoApplicationComponent;
import org.codehaus.jackson.JsonGenerationException;
import org.codehaus.jackson.map.JsonMappingException;
import org.codehaus.jackson.map.ObjectMapper;
import org.joda.time.DateTime;

import java.io.IOException;

public class PacoEventUtil {

  public static PacoEvent createEvent(ExperimentDAO experiment, String experimentGroup, Long actionTriggerId,
                                      Long actionId, Long actionTriggerSpecId, Long scheduledTime) {
    PacoEvent event = new PacoEvent();
    event.setExperimentId(experiment.getId());
    event.setExperimentName(experiment.getTitle());
    if (scheduledTime != null && scheduledTime != 0L) {
      event.setScheduledTime(new DateTime(scheduledTime));
    }
    event.setExperimentVersion(experiment.getVersion());
    event.setExperimentGroupName(experimentGroup);
    event.setActionId(actionId);
    event.setActionTriggerId(actionTriggerId);
    event.setActionTriggerSpecId(actionTriggerSpecId);

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