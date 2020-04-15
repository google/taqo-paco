import 'package:taqo_event_server_protocol/src/tesp_message.dart';
import 'package:test/test.dart';

class HasRuntimeType extends CustomMatcher {
  HasRuntimeType(matcher)
      : super('TespMessage with runtimeType that is', 'runtimeType', matcher);
  @override
  Object featureValueOf(actual) => (actual as TespMessage).runtimeType;
}

class HasPayload extends CustomMatcher {
  HasPayload(matcher)
      : super('TespMessage with payload that is', 'payload', matcher);
  @override
  Object featureValueOf(actual) => (actual as Payload).payload;
}

Matcher equalsTespMessage(TespMessage message) {
  if (message is Payload) {
    return allOf(HasRuntimeType(equals(message.runtimeType)),
        HasPayload(equals(message.payload)));
  } else {
    return HasRuntimeType(equals(message.runtimeType));
  }
}
