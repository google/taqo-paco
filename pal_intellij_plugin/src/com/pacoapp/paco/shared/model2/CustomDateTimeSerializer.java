package com.pacoapp.paco.shared.model2;

import org.codehaus.jackson.JsonGenerator;
import org.codehaus.jackson.JsonProcessingException;
import org.codehaus.jackson.map.JsonSerializer;
import org.codehaus.jackson.map.SerializerProvider;
import org.joda.time.DateTime;
import org.joda.time.format.DateTimeFormat;
import org.joda.time.format.DateTimeFormatter;
import org.joda.time.format.ISODateTimeFormat;

import java.io.IOException;

public class CustomDateTimeSerializer extends JsonSerializer<DateTime> {

  private static final DateTimeFormatter dtFormatter = ISODateTimeFormat.dateTime();
  private static final DateTimeFormatter zoneFormatter = DateTimeFormat.forPattern("ZZ");

  @Override
  public void serialize(DateTime value, JsonGenerator gen, SerializerProvider arg2)
          throws IOException, JsonProcessingException {
    gen.writeString(dtFormatter.print(value) + zoneFormatter.withZone(value.getZone()).print(0));
  }
}
