package com.taqo.survey.taqo_time_plugin

import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONArray

private const val channelName = "taqo_time_plugin"
private const val initialize = "initialize"
private const val cancel = "cancel"

/** TaqoTimePlugin */
class TaqoTimePlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var context: Context
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, channelName)
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      initialize -> {
        val args = JSONArray(call.arguments as Collection<*>)
        val bgCallbackHandle = args.getLong(0)
        val callbackHandle = args.getLong(1)
        FlutterBackgroundExecutor.setCallbackDispatcher(context, bgCallbackHandle, callbackHandle)
        TimeChangedReceiver.startBackgroundIsolate(context, bgCallbackHandle)
        result.success(true)
      }
      cancel -> {
        TimeChangedReceiver.cancel()
        result.success(true)
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
