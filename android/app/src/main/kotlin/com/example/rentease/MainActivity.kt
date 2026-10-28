package com.example.rentease

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val EMAIL_CHANNEL = "com.example.rentease/email_app"
    private val APP_CHANNEL = "com.example.rentease/app"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EMAIL_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openEmailApp") {
                try {
                    val gmailIntent = packageManager.getLaunchIntentForPackage("com.google.android.gm")
                    if (gmailIntent != null) {
                        gmailIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(gmailIntent)
                        result.success(true)
                    } else {
                        val emailIntent = Intent(Intent.ACTION_MAIN).apply {
                            addCategory(Intent.CATEGORY_APP_EMAIL)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        if (emailIntent.resolveActivity(packageManager) != null) {
                            startActivity(emailIntent)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }
                } catch (e: Exception) {
                    result.success(false)
                }
            } else {
                result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "moveToBackground") {
                moveTaskToBack(true)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }
}
