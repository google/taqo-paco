package com.taqo.survey.taqo_email_plugin

import android.content.Context
import android.content.Intent
import androidx.annotation.NonNull
import de.cketti.mailto.EmailIntentBuilder
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

private const val CHANNEL_NAME : String = "taqo_email_plugin"
private const val SEND_EMAIL : String = "send_email"
private const val TO_ARG : String = "to"
private const val SUBJ_ARG : String = "subject"

/** TaqoEmailPlugin */
class TaqoEmailPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  private lateinit var context : Context

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      SEND_EMAIL -> {
        val to : String?
        val subject : String?
        try {
          to = call.argument<String>(TO_ARG)
          subject = call.argument<String>(SUBJ_ARG)
        } catch (e : ClassCastException) {
          return result.error("Failed", "Must specify 'to' and 'subject' args", "")
        }

        if (to == null || subject == null) {
          return result.error("Failed", "Must specify 'to' and 'subject' args", "")
        }

        val intent = createEmailIntent(to, subject).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        val chooserIntent = Intent.createChooser(intent, "Choose your email client").addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK)

        context.startActivity(chooserIntent)
        result.success("Success")
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  private fun createEmailIntent(to : String, subject : String) : Intent {
    return EmailIntentBuilder.from(context)
            .sendTo(to)
            .subject(subject)
            .build()
  }
}

/// Because "to" is an operator in the Kotlin stdlib, we need to extend a method to set the "to"
// field. Since that Set in EmailIntentBuilder is private, we need to use reflection to set it :\
private fun EmailIntentBuilder.sendTo(who : String) : EmailIntentBuilder {
  EmailIntentBuilder::class.java.getDeclaredField("to").let {
    it.isAccessible = true
    val toObj = it.get(this)
    if (toObj != null && toObj is java.util.LinkedHashSet<*>) {
      @Suppress("UNCHECKED_CAST")
      val toSet = it.get(this) as java.util.LinkedHashSet<Any>
      toSet.add(who)
    }
  }
  return this
}
