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
