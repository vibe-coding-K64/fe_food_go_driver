package com.example.fe_food_go_driver

import android.content.BroadcastReceiver
import com.example.fe_food_go_driver.service.LocationServiceHelper
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private val methodChannelName = "com.example.fe_food_go_driver/background_location_control"
    private val eventChannelName = "com.example.fe_food_go_driver/background_location"

    private var eventSink: EventChannel.EventSink? = null
    private var locationReceiver: BroadcastReceiver? = null
    private var receiverRegistered = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startForegroundService" -> {
                        startBgService()
                        result.success(null)
                    }
                    "stopForegroundService" -> {
                        stopBgService()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    registerLocationReceiver()
                }

                override fun onCancel(arguments: Any?) {
                    unregisterLocationReceiver()
                    eventSink = null
                }
            })
    }

    private fun registerLocationReceiver() {
        if (receiverRegistered) return

        locationReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == "com.example.fe_food_go_driver.LOCATION_UPDATE" && eventSink != null) {
                    val lat = intent.getDoubleExtra("lat", 0.0)
                    val lng = intent.getDoubleExtra("lng", 0.0)
                    val heading = intent.getFloatExtra("heading", 0f)
                    val speed = intent.getFloatExtra("speed", 0f)

                    Handler(Looper.getMainLooper()).post {
                        eventSink?.success(mapOf(
                            "lat" to lat,
                            "lng" to lng,
                            "heading" to heading,
                            "speed" to speed
                        ))
                    }
                }
            }
        }

        val filter = IntentFilter("com.example.fe_food_go_driver.LOCATION_UPDATE")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(locationReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(locationReceiver, filter)
        }
        receiverRegistered = true
    }

    private fun unregisterLocationReceiver() {
        if (!receiverRegistered || locationReceiver == null) return
        try {
            unregisterReceiver(locationReceiver)
        } catch (_: Exception) {}
        locationReceiver = null
        receiverRegistered = false
    }

    private fun startBgService() {
        LocationServiceHelper.start(this)
    }

    private fun stopBgService() {
        LocationServiceHelper.stop(this)
    }

    override fun onDestroy() {
        unregisterLocationReceiver()
        super.onDestroy()
    }
}
