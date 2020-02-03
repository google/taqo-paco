// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.taqo.survey.timezonenotifier;

import android.content.Context;
import android.content.SharedPreferences;
import android.content.res.AssetManager;
import android.util.Log;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.dart.DartExecutor.DartCallback;
import io.flutter.embedding.engine.plugins.shim.ShimPluginRegistry;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback;
import io.flutter.view.FlutterCallbackInformation;
import io.flutter.view.FlutterMain;

import java.util.concurrent.atomic.AtomicBoolean;

/**
 * An background execution abstraction which handles initializing a background isolate running a
 * callback dispatcher, used to invoke Dart callbacks while backgrounded.
 */
public class FlutterBackgroundExecutor implements MethodCallHandler {
  private static final String TAG = "FlutterBGExecutor";
  private static final String BG_CALLBACK_HANDLE_KEY = "bg_callback_handle";
  private static final String CALLBACK_HANDLE_KEY = "callback_handle";
  private static PluginRegistrantCallback pluginRegistrantCallback;

  /**
   * The {@link MethodChannel} that connects the Android side of this plugin with the background
   * Dart isolate that was created by this plugin.
   */
  private MethodChannel backgroundChannel;

  private FlutterEngine backgroundFlutterEngine;

  private AtomicBoolean isCallbackDispatcherReady = new AtomicBoolean(false);

  /**
   * Sets the {@code PluginRegistrantCallback} used to register plugins with the newly spawned
   * isolate.
   *
   * <p>Note: this is only necessary for applications using the V1 engine embedding API as plugins
   * are automatically registered via reflection in the V2 engine embedding API. If not set, time
   * zone callbacks will not be able to utilize functionality from other plugins.
   */
  static void setPluginRegistrant(PluginRegistrantCallback callback) {
    pluginRegistrantCallback = callback;
  }

  /**
   * Sets the Dart callback handle for the Dart method that is responsible for initializing the
   * background Dart isolate, preparing it to receive Dart callback tasks requests.
   */
  static void setCallbackDispatcher(Context context, long bgCallbackHandle, long callbackHandle) {
    SharedPreferences prefs = context.getSharedPreferences(TimeZoneReceiver.SHARED_PREFERENCES_KEY, 0);
    prefs.edit().putLong(BG_CALLBACK_HANDLE_KEY, bgCallbackHandle).apply();
    prefs.edit().putLong(CALLBACK_HANDLE_KEY, callbackHandle).apply();
  }

  /** Returns true when the background isolate has started and is ready to handle time zone
   * changes.
   */
  private boolean isNotRunning() {
    return !isCallbackDispatcherReady.get();
  }

  private void onInitialized() {
    isCallbackDispatcherReady.set(true);
    TimeZoneReceiver.onInitialized();
  }

  @Override
  public void onMethodCall(MethodCall call, @NonNull Result result) {
    String method = call.method;
    //Object arguments = call.arguments;
    try {
      if (method.equals("TimeZoneNotifier.initialized")) {
        // This message is sent by the background method channel as soon as the background isolate
        // is running. From this point forward, the Android side of this plugin can send
        // callback handles through the background method channel, and the Dart side will execute
        // the Dart methods corresponding to those callback handles.
        onInitialized();
        result.success(true);
      } else {
        result.notImplemented();
      }
    } catch (PluginRegistrantException e) {
      result.error("error", "TimeZoneNotifier error: " + e.getMessage(), null);
    }
  }

  /**
   * Starts running a background Dart isolate within a new {@link FlutterEngine} using a previously
   * used entrypoint.
   *
   * <p>The isolate is configured as follows:
   *
   * <ul>
   *   <li>Bundle Path: {@code FlutterMain.findAppBundlePath(context)}.
   *   <li>Entrypoint: The Dart method used the last time this plugin was initialized in the
   *       foreground.
   *   <li>Run args: none.
   * </ul>
   *
   * <p>Preconditions:
   *
   * <ul>
   *   <li>The given callback must correspond to a registered Dart callback. If the handle does not
   *       resolve to a Dart callback then this method does nothing.
   *   <li>A static {@link #pluginRegistrantCallback} must exist, otherwise a {@link
   *       PluginRegistrantException} will be thrown.
   * </ul>
   */
  void startBackgroundIsolate(Context context) {
    if (isNotRunning()) {
      SharedPreferences p = context.getSharedPreferences(TimeZoneReceiver.SHARED_PREFERENCES_KEY, 0);
      long callbackHandle = p.getLong(BG_CALLBACK_HANDLE_KEY, 0);
      startBackgroundIsolate(context, callbackHandle);
    }
  }

  /**
   * Starts running a background Dart isolate within a new {@link FlutterEngine}.
   *
   * <p>The isolate is configured as follows:
   *
   * <ul>
   *   <li>Bundle Path: {@code FlutterMain.findAppBundlePath(context)}.
   *   <li>Entrypoint: The Dart method represented by {@code bgCallbackHandle}.
   *   <li>Run args: none.
   * </ul>
   *
   * <p>Preconditions:
   *
   * <ul>
   *   <li>The given {@code bgCallbackHandle} must correspond to a registered Dart callback. If the
   *       handle does not resolve to a Dart callback then this method does nothing.
   *   <li>A static {@link #pluginRegistrantCallback} must exist, otherwise a {@link
   *       PluginRegistrantException} will be thrown.
   * </ul>
   */
  void startBackgroundIsolate(Context context, long bgCallbackHandle) {
    if (backgroundFlutterEngine != null) {
      Log.e(TAG, "Background isolate already started");
      return;
    }

    Log.i(TAG, "Starting TimeZoneNotifier...");
    String appBundlePath = FlutterMain.findAppBundlePath(context);
    AssetManager assets = context.getAssets();
    if (appBundlePath != null && isNotRunning()) {
      backgroundFlutterEngine = new FlutterEngine(context);

      // We need to create an instance of `FlutterEngine` before looking up the
      // callback. If we don't, the callback cache won't be initialized and the
      // lookup will fail.
      FlutterCallbackInformation flutterCallback =
          FlutterCallbackInformation.lookupCallbackInformation(bgCallbackHandle);

      DartExecutor executor = backgroundFlutterEngine.getDartExecutor();
      initializeMethodChannel(executor);
      DartCallback dartCallback = new DartCallback(assets, appBundlePath, flutterCallback);

      executor.executeDartCallback(dartCallback);

      // The pluginRegistrantCallback should only be set in the V1 embedding as
      // plugin registration is done via reflection in the V2 embedding.
      if (pluginRegistrantCallback != null) {
        pluginRegistrantCallback.registerWith(new ShimPluginRegistry(backgroundFlutterEngine));
      }
    }
  }

  /**
   * Executes the desired Dart callback in a background Dart isolate.
   *
   * <p>The given {@code intent} should contain a {@code long} extra called "callbackHandle", which
   * corresponds to a callback registered with the Dart VM.
   */
  void executeDartCallbackInBackgroundIsolate(Context context) {
    // Grab the handle for the callback. Pay close attention to the type of the callback handle as
    // storing this value in a variable of the wrong size will cause the callback lookup to fail.
    SharedPreferences p = context.getSharedPreferences(TimeZoneReceiver.SHARED_PREFERENCES_KEY, 0);
    long callbackHandle = p.getLong(CALLBACK_HANDLE_KEY, 0);

    // Handle the time zone event in Dart. Note that for this plugin, we don't
    // care about the method name as we simply lookup and invoke the callback
    // provided.
    backgroundChannel.invokeMethod(
        "invokeTimeZoneNotifierCallback",
        new Object[] {callbackHandle, },
        null);
  }

  private void initializeMethodChannel(BinaryMessenger isolate) {
    // backgroundChannel is the channel responsible for receiving the following messages from
    // the background isolate that was setup by this plugin:
    // - "TimeZoneNotifier.initialized"
    //
    // This channel is also responsible for sending requests from Android to Dart to execute Dart
    // callbacks in the background isolate.
    backgroundChannel =
        new MethodChannel(
            isolate,
            "com.taqo.survey/time_zone_notifier_background",
            JSONMethodCodec.INSTANCE);
    backgroundChannel.setMethodCallHandler(this);
  }
}
