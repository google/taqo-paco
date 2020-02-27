import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('taqo_time_plugin');
const _backgroundName = 'com.taqo.survey/taqo_time_plugin_background';
const _initialize = 'initialize';
const _initialized = 'initialized';
const _cancel = 'cancel';

// This is the entry point for the background isolate. Since we can only enter
// an isolate once, we setup a MethodChannel to listen for method invocations
// from the native portion of the plugin. This allows for the plugin to perform
// any necessary processing in Dart (e.g., populating a custom object) before
// invoking the provided callback.
void _timeChangedCallbackDispatcher() {
  // Initialize state necessary for MethodChannels.
  WidgetsFlutterBinding.ensureInitialized();

  const bgChannel = MethodChannel(_backgroundName, JSONMethodCodec());
  // This is where the magic happens and we handle background events from the
  // native portion of the plugin.
  bgChannel.setMethodCallHandler((MethodCall call) async {
    final args = call.arguments;
    final handle = CallbackHandle.fromRawHandle(args[0]);

    // PluginUtilities.getCallbackFromHandle performs a lookup based on the
    // callback handle and returns a tear-off of the original callback.
    final closure = PluginUtilities.getCallbackFromHandle(handle);

    if (closure == null) {
      print('Fatal: could not find callback');
      exit(-1);
    }

    // ignore: inference_failure_on_function_return_type
    if (closure is Function()) {
      closure();
      // ignore: inference_failure_on_function_return_type
    } else if (closure is Function(int)) {
      final int id = args[1];
      closure(id);
    }
  });

  // Once we've finished initializing, let the native portion of the plugin
  // know that it can start making callbacks
  bgChannel.invokeMethod<void>(_initialized);
}

typedef CallbackHandle _GetCallbackHandle(Function callback);
// Callback used to get the handle for a callback. It's [PluginUtilities.getCallbackHandle]
// by default. A lambda that gets the handle for the given [callback].
_GetCallbackHandle _getCallbackHandle =
    (Function callback) => PluginUtilities.getCallbackHandle(callback);

/// Starts the callbacks
/// Returns a [Future] that resolves to `true` on success and `false` on failure.
Future<bool> initialize(Function callback) async {
  final bgHandle = _getCallbackHandle(_timeChangedCallbackDispatcher);
  if (bgHandle == null) {
    return false;
  }
  final handle = _getCallbackHandle(callback);
  if (handle == null) {
    return false;
  }
  return await _channel.invokeMethod<bool>(
      _initialize, [bgHandle.toRawHandle(), handle.toRawHandle()]) ?? false;
}

/// Cancels callbacks
/// Returns a [Future] that resolves to `true` on success and `false` on failure.
Future<bool> cancel() async {
  final r = await _channel.invokeMethod<bool>(_cancel);
  return (r == null) ? false : r;
}
