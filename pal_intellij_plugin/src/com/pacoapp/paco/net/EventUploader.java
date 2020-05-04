package com.pacoapp.paco.net;

import com.pacoapp.paco.shared.comm.Outcome;
import com.pacoapp.paco.shared.model2.EventStore;
import com.pacoapp.paco.shared.model2.JsonConverter;
import com.pacoapp.paco.shared.model2.PacoEvent;
import org.codehaus.jackson.JsonGenerationException;
import org.codehaus.jackson.JsonParseException;
import org.codehaus.jackson.map.JsonMappingException;
import org.codehaus.jackson.map.ObjectMapper;
import org.codehaus.jackson.type.TypeReference;

import java.io.IOException;
import java.io.StringWriter;
import java.util.List;
import java.util.logging.Logger;

public class EventUploader {

  private static final int UPLOAD_EVENT_GROUP_SIZE = 50;

  private Logger Log =  Logger.getLogger(EventUploader.class.getName());

  private EventStore eventStore;
  private String serverAddress;


  public EventUploader(String serverAddress, EventStore eventStore) {
    this.eventStore = eventStore;
    this.serverAddress = serverAddress;
  }

  public void uploadEvents(List<PacoEvent> allEvents) {
    if (allEvents.size() == 0) {
      Log.info("Nothing to sync");
      return;
    }

    Log.info("Tasks (" + allEvents.size() + ") found in db");

    sendToPaco(allEvents);
  }

  public void markEventsAccordingToOutcomes(List<PacoEvent> events, final List<Outcome> outcomes) {
    for (int i = 0; i < outcomes.size(); i++) {
      Outcome currentOutcome = outcomes.get(i);
      if (currentOutcome.succeeded()) {
        PacoEvent correspondingEvent = events.get((int) currentOutcome.getEventId());
        correspondingEvent.setUploaded(true);
        eventStore.updateEvent(correspondingEvent);
      }
    }
  }

  private static class ResponsePair {
    int overallCode;
    List<Outcome> outcomes;
  }

  private void sendToPaco(List<PacoEvent> events) {
    String json = toJson(events);

    NetworkClient networkClient = new NetworkClient() {
      boolean hasErrorOcurred = false;
      int uploadGroupSize = UPLOAD_EVENT_GROUP_SIZE;
      int uploaded = 0;

      @Override
      public void onSuccess(String response) {
        ResponsePair responsePair = new ResponsePair();
        if (response != null) {
          readOutcomesFromJson(responsePair, response);
        }
        if (responsePair.overallCode != 200) {
          hasErrorOcurred = true;
        }
        while (uploaded < events.size() && !hasErrorOcurred && NetworkUtil.isConnected()) {
          int groupSize = Math.min(events.size() - uploaded, uploadGroupSize);
          int end = uploaded + groupSize;
          List<PacoEvent> subsetOfEvents = events.subList(uploaded, end);
          _sendToPacoOverHttp(toJson(subsetOfEvents), this);
          final List<Outcome> outcomes = responsePair.outcomes;
          markEventsAccordingToOutcomes(events, outcomes);
          uploaded = end;
        }

//        if (!hasErrorOcurred) {
//          Log.debug("syncing complete");
//        } else {
//          Log.debug("could not complete upload of events");
//        }
      }

      @Override
      public void onException(Exception Exception) {
        hasErrorOcurred = true;
      }

      @Override
      public void onError(String message, Exception exception) {
        hasErrorOcurred = true;
      }
    };

    _sendToPacoOverHttp(json, networkClient);
  }

  private void _sendToPacoOverHttp(String json, NetworkClient networkClient) {
    Log.info("Preparing to post.");
    final String completeServerUrl = ServerAddressBuilder.createServerUrl(serverAddress, "/pubexperiments");
    new HttpUtility().doRequest(HttpUtility.POST, completeServerUrl, json, networkClient);
  }

  private void readOutcomesFromJson(ResponsePair responsePair, String contentAsString) {
    if (contentAsString != null) {
      ObjectMapper mapper2 = JsonConverter.getObjectMapper();
      try {
        responsePair.outcomes = mapper2.readValue(contentAsString, new TypeReference<List<Outcome>>() {});
      } catch (JsonParseException e) {
        Log.severe(e.getMessage());
        responsePair.overallCode = 500;
      } catch (JsonMappingException e) {
        Log.severe(e.getMessage());
        responsePair.overallCode = 500;
      } catch (IOException e) {
        Log.severe(e.getMessage());
        responsePair.overallCode = 500;
      }
    }
  }

  private String toJson(List<PacoEvent> events) {
    ObjectMapper mapper = JsonConverter.getObjectMapper();
    //mapper.setDateFormat(DateTimeFormat.forPattern("yyyy/MM/dd HH:mm:ssZ")).withOffsetParsed();
    StringWriter stringWriter = new StringWriter();
    Log.info("syncing events");
    try {
      mapper.writeValue(stringWriter, events);
    } catch (JsonGenerationException e) {
      Log.severe(e.getMessage());

    } catch (JsonMappingException e) {
      Log.severe(e.getMessage());

    } catch (IOException e) {
      Log.severe(e.getMessage());

    }
    return stringWriter.toString();
  }

}
