package com.taqo.survey.taqosurvey

import android.content.Intent
import android.net.Uri
import androidx.annotation.NonNull
import androidx.annotation.UiThread
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    private val channel = "com.taqo.survey.taqosurvey/email"
    private val sendEmailMethod = "send_email"
    private val toArg = "to"
    private val subjectArg = "subject"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        //GeneratedPluginRegistrant.registerWith(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
                .setMethodCallHandler { call, result ->
                    if (sendEmailMethod == call.method) {
                        val to = call.argument<String>(toArg)
                        val subject = call.argument<String>(subjectArg)
                        if (to != null && subject != null) {
                            sendEmail(to, subject)
                        }
                    } else {
                        result.notImplemented()
                    }
                }
    }

    @UiThread
    private fun sendEmail(to: String, subject: String) {
        val intent = Intent(Intent.ACTION_SENDTO)
        intent.type = "text/html"
        intent.data = Uri.parse("mailto:$to?subject=${Uri.encode(subject)}")
        startActivity(Intent.createChooser(intent, "Choose your email client"))
    }
}
