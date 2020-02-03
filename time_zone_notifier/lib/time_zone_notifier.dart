// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const String _backgroundName = 'com.taqo.survey/time_zone_notifier_background';

// This is the entry point for the background isolate. Since we can only enter
// an isolate once, we setup a MethodChannel to listen for method invocations
// from the native portion of the plugin. This allows for the plugin to perform
// any necessary processing in Dart (e.g., populating a custom object) before
// invoking the provided callback.
void _timeZoneCallbackDispatcher() {
  // Initialize state necessary for MethodChannels.
  WidgetsFlutterBinding.ensureInitialized();

  const MethodChannel _channel =
      MethodChannel(_backgroundName, JSONMethodCodec());
  // This is where the magic happens and we handle background events from the
  // native portion of the plugin.
  _channel.setMethodCallHandler((MethodCall call) async {
    final dynamic args = call.arguments;
    final CallbackHandle handle = CallbackHandle.fromRawHandle(args[0]);

    // PluginUtilities.getCallbackFromHandle performs a lookup based on the
    // callback handle and returns a tear-off of the original callback.
    final Function closure = PluginUtilities.getCallbackFromHandle(handle);

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
  _channel.invokeMethod<void>('TimeZoneNotifier.initialized');
}

// A lambda that gets the handle for the given [callback].
typedef CallbackHandle _GetCallbackHandle(Function callback);

/// A Flutter plugin for registering Dart callbacks for time zone changes.
///
/// See the example/ directory in this package for sample usage.
class TimeZoneNotifier {
  static const String _channelName = 'com.taqo.survey/time_zone_notifier';
  static MethodChannel _channel =
      const MethodChannel(_channelName, JSONMethodCodec());
  // Callback used to get the handle for a callback. It's
  // [PluginUtilities.getCallbackHandle] by default.
  static _GetCallbackHandle _getCallbackHandle =
      (Function callback) => PluginUtilities.getCallbackHandle(callback);

  /// This is exposed for the unit tests. It should not be accessed by users of
  /// the plugin.
  @visibleForTesting
  static void setTestOverrides({_GetCallbackHandle getCallbackHandle}) {
    _getCallbackHandle = (getCallbackHandle ?? _getCallbackHandle);
  }

  /// Starts the [TimeZoneNotifier] service. This must be called before
  /// getting any callbacks
  ///
  /// Returns a [Future] that resolves to `true` on success and `false` on
  /// failure.
  static Future<bool> initialize(Function callback) async {
    final CallbackHandle bgHandle =
        _getCallbackHandle(_timeZoneCallbackDispatcher);
    if (bgHandle == null) {
      return false;
    }
    final CallbackHandle handle = _getCallbackHandle(callback);
    if (handle == null) {
      return false;
    }
    return await _channel.invokeMethod<bool>(
        'TimeZoneNotifier.start', <dynamic>[bgHandle.toRawHandle(), handle.toRawHandle()]) ??
        false;
  }

  /// Cancels callbacks
  ///
  /// Returns a [Future] that resolves to `true` on success and `false` on
  /// failure.
  static Future<bool> cancel() async {
    final bool r =
        await _channel.invokeMethod<bool>('TimeZoneNotifier.cancel');
    return (r == null) ? false : r;
  }
}
