// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.taqo.survey.timezonenotifier;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Handler;
import android.util.Log;

import io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback;

public class TimeZoneReceiver extends BroadcastReceiver {
  private static final String TAG = "TZNotifier";
  public static final String SHARED_PREFERENCES_KEY = "TZNotifier";

  /** Background Dart execution context. */
  private static FlutterBackgroundExecutor flutterBackgroundExecutor;

  /**
   * Starts the background isolate for the {@link TimeZoneReceiver}.
   *
   * <p>Preconditions:
   *
   * <ul>
   *   <li>The given {@code callbackHandle} must correspond to a registered Dart callback. If the
   *       handle does not resolve to a Dart callback then this method does nothing.
   *   <li>A static pluginRegistrantCallback must exist, otherwise a {@link
   *       PluginRegistrantException} will be thrown.
   * </ul>
   */
  public static void startBackgroundIsolate(Context context, long bgCallbackHandle) {
    if (flutterBackgroundExecutor != null) {
      Log.w(TAG, "Attempted to start a duplicate background isolate. Returning...");
      return;
    }
    flutterBackgroundExecutor = new FlutterBackgroundExecutor();
    flutterBackgroundExecutor.startBackgroundIsolate(context, bgCallbackHandle);
  }

  /**
   * Called once the Dart isolate ({@code flutterBackgroundExecutor}) has finished initializing.
   *
   * <p>Invoked by {@link TimeZoneNotifierPlugin} when it receives the {@code
   * TimeZoneNotifier.initialized} message.
   */
  static void onInitialized() {
    Log.i(TAG, "TimeZoneNotifier started!");
  }

  /**
   * Sets the Dart callback handle for the Dart method that is responsible for initializing the
   * background Dart isolate, preparing it to receive Dart callback tasks requests.
   */
  public static void setCallbackDispatcher(Context context, long bgCallbackHandle, long callbackHandle) {
    FlutterBackgroundExecutor.setCallbackDispatcher(context, bgCallbackHandle, callbackHandle);
  }

  /**
   * Sets the {@link PluginRegistrantCallback} used to register the plugins used by an application
   * with the newly spawned background isolate.
   *
   * <p>This should be invoked in Application.onCreate with GeneratedPluginRegistrant in
   * applications using the V1 embedding API in order to use other plugins in the background
   * isolate. For applications using the V2 embedding API, it is not necessary to set a
   * {@link PluginRegistrantCallback} as plugins are registered automatically.
   */
  public static void setPluginRegistrant(PluginRegistrantCallback callback) {
    // Indirectly set in FlutterBackgroundExecutor for backwards compatibility.
    FlutterBackgroundExecutor.setPluginRegistrant(callback);
  }

  /** Cancels callbacks. */
  public static void cancel(Context context) {
  }

  @Override
  public void onReceive(Context context, Intent intent) {
    final Context app = context.getApplicationContext();
    new Handler(app.getMainLooper())
            .post(() ->
                    flutterBackgroundExecutor.executeDartCallbackInBackgroundIsolate(app));
  }
}
