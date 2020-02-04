// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.taqo.survey.timezonenotifier;

import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.view.FlutterNativeView;
import org.json.JSONArray;
import org.json.JSONException;

/**
 * Flutter plugin for running one-shot and periodic tasks sometime in the future on Android.
 *
 * <p>Plugin initialization goes through these steps:
 *
 * <ol>
 *   <li>Flutter app instructs this plugin to initialize() on the Dart side.
 *   <li>The Dart side of this plugin sends the Android side a "TimeZoneNotifier.start" message,
 *       along with a Dart callback handle for a Dart callback that should be immediately invoked by
 *       a background Dart isolate.
 *   <li>The Android side of this plugin spins up a background {@link FlutterNativeView}, which
 *       includes a background Dart isolate.
 *   <li>The Android side of this plugin instructs the new background Dart isolate to execute the
 *       callback that was received in the "TimeZoneNotifier.start" message.
 *   <li>The Dart side of this plugin, running within the new background isolate, executes the
 *       designated callback. This callback prepares the background isolate to then execute any
 *       given Dart callback from that point forward. Thus, at this moment the plugin is fully
 *       initialized and ready to execute arbitrary Dart tasks in the background. The Dart side of
 *       this plugin sends the Android side a "TimeZoneNotifier.initialized" message to signify that
 *       the Dart is ready to execute tasks.
 * </ol>
 */
public class TimeZoneNotifierPlugin implements FlutterPlugin, MethodCallHandler {
//  private static TimeZoneNotifierPlugin instance;
  private static final String TAG = "TZNotifierPlugin";
  private Context context;
  private final Object initializationLock = new Object();
  private MethodChannel timeZoneNotifierPluginChannel;

  /**
   * Registers this plugin with an associated Flutter execution context, represented by the given
   * {@link Registrar}.
   *
   * <p>Once this method is executed, an instance of {@code TimeZoneNotifierPlugin} will be
   * connected to, and running against, the associated Flutter execution context.
   */
//  public static void registerWith(Registrar registrar) {
//    if (instance == null) {
//      instance = new TimeZoneNotifierPlugin();
//    }
//    instance.onAttachedToEngine(registrar.context(), registrar.messenger());
//  }

  @Override
  public void onAttachedToEngine(FlutterPluginBinding binding) {
    onAttachedToEngine(binding.getApplicationContext(), binding.getBinaryMessenger());
  }

  private void onAttachedToEngine(Context applicationContext, BinaryMessenger messenger) {
    synchronized (initializationLock) {
      if (timeZoneNotifierPluginChannel != null) {
        return;
      }

      Log.i(TAG, "onAttachedToEngine");
      this.context = applicationContext;

      // timeZoneNotifierPluginChannel is the channel responsible for receiving the following messages
      // from the main Flutter app:
      // - "TimeZoneNotifier.start"
      // - "TimeZoneNotifier.cancel"
      timeZoneNotifierPluginChannel =
          new MethodChannel(
              messenger, "com.taqo.survey/time_zone_notifier", JSONMethodCodec.INSTANCE);

      // Instantiate a new TimeZoneNotifierPlugin and connect the primary method channel for
      // Android/Flutter communication.
      timeZoneNotifierPluginChannel.setMethodCallHandler(this);
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    Log.i(TAG, "onDetachedFromEngine");
    context = null;
    timeZoneNotifierPluginChannel.setMethodCallHandler(null);
    timeZoneNotifierPluginChannel = null;
  }

  public TimeZoneNotifierPlugin() {}

  /** Invoked when the Flutter side of this plugin sends a message to the Android side. */
  @Override
  public void onMethodCall(MethodCall call, @NonNull Result result) {
    String method = call.method;
    Object arguments = call.arguments;
    try {
      if (method.equals("TimeZoneNotifier.start")) {
        // This message is sent when the Dart side of this plugin is told to initialize.
        long bgCallbackHandle = ((JSONArray) arguments).getLong(0);
        long callbackHandle = ((JSONArray) arguments).getLong(1);
        // In response, this (native) side of the plugin needs to spin up a background
        // Dart isolate by using the given callbackHandle, and then setup a background
        // method channel to communicate with the new background isolate. Once completed,
        // this onMethodCall() method will receive messages from both the primary and background
        // method channels.
        TimeZoneReceiver.setCallbackDispatcher(context, bgCallbackHandle, callbackHandle);
        TimeZoneReceiver.startBackgroundIsolate(context, bgCallbackHandle);
        result.success(true);
      } else if (method.equals("TimeZoneNotifier.cancel")) {
        // This message indicates that the Flutter app would like to cancel a previously
        // registered callback
        TimeZoneReceiver.cancel(context);
        result.success(true);
      } else {
        result.notImplemented();
      }
    } catch (JSONException e) {
      result.error("error", "JSON error: " + e.getMessage(), null);
    } catch (PluginRegistrantException e) {
      result.error("error", "TimeZoneNotifier error: " + e.getMessage(), null);
    }
  }
}
