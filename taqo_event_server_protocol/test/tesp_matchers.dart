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

import 'package:taqo_event_server_protocol/src/tesp_message.dart';
import 'package:test/test.dart';

class HasRuntimeType extends CustomMatcher {
  HasRuntimeType(matcher)
      : super('TespMessage with runtimeType that is', 'runtimeType', matcher);
  @override
  Object featureValueOf(actual) => (actual as TespMessage).runtimeType;
}

class HasPayload extends CustomMatcher {
  static const _featureDescription = 'TespMessage with payload that is';
  final Matcher _matcher;

  HasPayload(matcher)
      : _matcher = matcher,
        super(_featureDescription, 'payload', matcher);

  @override
  Object featureValueOf(actual) => (actual as Payload).payload;

  @override
  Description describe(Description description) {
    var matcherDesciption = StringDescription();
    _matcher.describe(matcherDesciption);
    return description
        .add(_featureDescription)
        .add(' ')
        .add(_truncateString(matcherDesciption.toString()));
  }
}

class HasEncodedPayload extends CustomMatcher {
  static const _featureDescription = 'TespMessage with encoded payload that is';
  final Matcher _matcher;

  HasEncodedPayload(matcher)
      : _matcher = matcher,
        super(_featureDescription, 'encodedPayload', matcher);

  @override
  Object featureValueOf(actual) => (actual as Payload).encodedPayload;

  @override
  Description describe(Description description) {
    // Omit the actual payload to avoiding hanging caused by large payload.
    return description.add(_featureDescription).add(' <omitted>');
  }
}

Matcher equalsTespMessage(TespMessage message) {
  if (message is Payload<String>) {
    return allOf(HasRuntimeType(equals(message.runtimeType)),
        HasPayload(equals(message.payload)));
  } else if (message is Payload) {
    return allOf(HasRuntimeType(equals(message.runtimeType)),
        HasEncodedPayload(equals(message.encodedPayload)));
  } else {
    return HasRuntimeType(equals(message.runtimeType));
  }
}

String _truncateString(String string) => string.length <= 1000
    ? string
    : '${string.substring(0, 1000)}<... ${string.length - 1000} characters not displayed>';
