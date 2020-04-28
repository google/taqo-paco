import 'package:taqo_event_server_protocol/src/tesp_message.dart';
import 'package:test/test.dart';

class HasRuntimeType extends CustomMatcher {
  HasRuntimeType(matcher)
      : super('TespMessage with runtimeType that is', 'runtimeType', matcher);
  @override
  Object featureValueOf(actual) => (actual as TespMessage).runtimeType;
}

class HasPayload extends CustomMatcher {
  static const _featureDescription='TespMessage with payload that is';
  final Matcher _matcher;

  HasPayload(matcher)
      : _matcher=matcher, super(_featureDescription, 'payload', matcher);

  @override
  Object featureValueOf(actual) => (actual as Payload).payload;

  @override
  Description describe(Description description) {
    var matcherDesciption=StringDescription();
    _matcher.describe(matcherDesciption);
    return description.add(_featureDescription).add(' ').add(_truncateString(matcherDesciption.toString()));
  }
}

Matcher equalsTespMessage(TespMessage message) {
  if (message is Payload) {
    return allOf(HasRuntimeType(equals(message.runtimeType)),
        HasPayload(equals(message.payload)));
  } else {
    return HasRuntimeType(equals(message.runtimeType));
  }
}

String _truncateString(String string) => string.length <= 1000
    ? string
    : '${string.substring(0, 1000)}<... ${string.length - 1000} characters not displayed>';
