package com.dotrackr.dotrackr

import android.content.Context
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.PrintWriter
import java.io.StringWriter

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.dotrackr.crash"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        val defaultHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, exception ->
            try {
                val sw = StringWriter()
                exception.printStackTrace(PrintWriter(sw))
                val prefs = getSharedPreferences("CrashPrefs", Context.MODE_PRIVATE)
                prefs.edit().putString("native_crash_log", sw.toString()).commit()
            } catch (e: Exception) {}
            
            defaultHandler?.uncaughtException(thread, exception)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getCrashLog") {
                val prefs = getSharedPreferences("CrashPrefs", Context.MODE_PRIVATE)
                val log = prefs.getString("native_crash_log", null)
                prefs.edit().remove("native_crash_log").apply()
                result.success(log)
            } else {
                result.notImplemented()
            }
        }
    }
}

