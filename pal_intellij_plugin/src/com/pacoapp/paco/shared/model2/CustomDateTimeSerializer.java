package com.pacoapp.paco.shared.model2;

import org.codehaus.jackson.JsonGenerator;
import org.codehaus.jackson.map.JsonSerializer;
import org.codehaus.jackson.map.SerializerProvider;
import org.joda.time.DateTime;
import org.joda.time.format.DateTimeFormat;
import org.joda.time.format.DateTimeFormatter;

import java.io.IOException;

public class CustomDateTimeSerializer extends JsonSerializer<DateTime> {

  DateTimeFormatter df = DateTimeFormat.forPattern("yyyy/MM/dd HH:mm:ssZ");

  @Override
  public void serialize(DateTime value, JsonGenerator gen, SerializerProvider arg2)
          throws IOException {
    gen.writeString(df.print(value));
  }
}
