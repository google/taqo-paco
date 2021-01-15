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

package com.taqo.survey.taqo_time_plugin

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Context.MODE_PRIVATE
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.plugins.shim.ShimPluginRegistry
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.JSONMethodCodec
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.view.FlutterCallbackInformation
import io.flutter.view.FlutterMain
import java.util.concurrent.atomic.AtomicBoolean

private const val TAG = "TaqoTimePlugin"
private const val SHARED_PREF_KEY = "TaqoTimePlugin"
private const val CALLBACK_HANDLE = "callback"
private const val BG_CALLBACK_HANDLE = "background_callback"

private const val backgroundName = "com.taqo.survey/taqo_time_plugin_background"
private const val initialized = "initialized"
private const val bgCallbackMethod = "backgroundIsolateCallback"

class FlutterBackgroundExecutor {
    companion object {
        private val isCallbackDispatcherReady = AtomicBoolean(false)
        private var backgroundFlutterEngine : FlutterEngine? = null
        private var backgroundChannel : MethodChannel? = null
        var pluginRegistrantCallback : PluginRegistry.PluginRegistrantCallback? = null

        private val isNotRunning :  Boolean
            get() { return !isCallbackDispatcherReady.get() }

        private fun onInitialized() {
            isCallbackDispatcherReady.set(true)
        }

        fun setCallbackDispatcher(context: Context, bgCallbackHandle: Long, callbackHandle: Long) {
            val sharedPreferences = context.getSharedPreferences(SHARED_PREF_KEY, MODE_PRIVATE)
            sharedPreferences.edit()
                    .putLong(BG_CALLBACK_HANDLE, bgCallbackHandle)
                    .putLong(CALLBACK_HANDLE, callbackHandle)
                    .apply()
        }

        private fun initializeMethodChannel(isolate : BinaryMessenger) {
            backgroundChannel = MethodChannel(isolate, backgroundName, JSONMethodCodec.INSTANCE)
            backgroundChannel?.setMethodCallHandler { call, result ->
                when (call.method) {
                    initialized -> {
                        onInitialized()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    @Suppress("unused")
    fun startBackgroundIsolate(context : Context) {
        if (isNotRunning) {
            val sharedPreferences = context.getSharedPreferences(SHARED_PREF_KEY, MODE_PRIVATE)
            val callbackHandle = sharedPreferences.getLong(BG_CALLBACK_HANDLE, 0)
            startBackgroundIsolate(context, callbackHandle)
        }
    }

    fun startBackgroundIsolate(context : Context, callbackHandle : Long) {
        if (backgroundFlutterEngine != null) {
            Log.d(TAG, "Background Isolate already started")
            return
        }

        Log.d(TAG, "Starting background Isolate")
        val appBundlePath = FlutterMain.findAppBundlePath()
        val assets = context.assets
        if (isNotRunning) {
            backgroundFlutterEngine = FlutterEngine(context)
            val flutterCallback = FlutterCallbackInformation.lookupCallbackInformation(callbackHandle)
            val executor = backgroundFlutterEngine?.dartExecutor
            if (executor != null) {
                initializeMethodChannel(executor)
                val dartCallback = DartExecutor.DartCallback(assets, appBundlePath, flutterCallback)
                executor.executeDartCallback(dartCallback)
            }

            pluginRegistrantCallback?.registerWith(ShimPluginRegistry(backgroundFlutterEngine!!))
        }
    }

    fun executeDartCallbackInBackgroundIsolate(context: Context) {
        val sharedPreferences = context.getSharedPreferences(SHARED_PREF_KEY, MODE_PRIVATE)
        val callbackHandle = sharedPreferences.getLong(CALLBACK_HANDLE, 0)
        backgroundChannel?.invokeMethod(bgCallbackMethod, arrayOf(callbackHandle as Any))
    }
}

class TimeChangedReceiver : BroadcastReceiver() {
    companion object {
        private var flutterBackgroundExecutor : FlutterBackgroundExecutor? = null

        fun startBackgroundIsolate(context: Context, callbackHandle: Long) {
            if (flutterBackgroundExecutor != null) {
                Log.d(TAG, "Background Isolate already started")
                return
            }
            flutterBackgroundExecutor = FlutterBackgroundExecutor()
            flutterBackgroundExecutor?.startBackgroundIsolate(context, callbackHandle)
        }

        fun cancel() {
            // Not implemented because it's unclear why we would want to cancel :)
        }
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        val app = context!!.applicationContext
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            Handler.createAsync(app.mainLooper).post {
                flutterBackgroundExecutor?.executeDartCallbackInBackgroundIsolate(app)
            }
        } else {
            Handler(app.mainLooper).post {
                flutterBackgroundExecutor?.executeDartCallbackInBackgroundIsolate(app)
            }
        }
    }
}
