package com.example.fe_food_go_driver;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import androidx.annotation.NonNull;
import com.example.fe_food_go_driver.service.LocationServiceHelper;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {

    private static final String METHOD_CHANNEL = "com.example.fe_food_go_driver/background_location_control";
    private static final String EVENT_CHANNEL = "com.example.fe_food_go_driver/background_location";

    private EventChannel.EventSink eventSink;
    private BroadcastReceiver locationReceiver;
    private boolean receiverRegistered = false;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // Method channel: Flutter calls to start/stop service
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), METHOD_CHANNEL)
            .setMethodCallHandler((call, result) -> {
                if ("startForegroundService".equals(call.method)) {
                    startBgService();
                    result.success(null);
                } else if ("stopForegroundService".equals(call.method)) {
                    stopBgService();
                    result.success(null);
                } else {
                    result.notImplemented();
                }
            });

        // Event channel: Service broadcasts location to Flutter
        new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), EVENT_CHANNEL)
            .setStreamHandler(new EventChannel.StreamHandler() {
                @Override
                public void onListen(Object arguments, EventChannel.EventSink events) {
                    eventSink = events;
                    registerLocationReceiver();
                }

                @Override
                public void onCancel(Object arguments) {
                    unregisterLocationReceiver();
                    eventSink = null;
                }
            });
    }

    private void registerLocationReceiver() {
        if (receiverRegistered) return;

        locationReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                if ("com.example.fe_food_go_driver.LOCATION_UPDATE".equals(intent.getAction()) && eventSink != null) {
                    double lat = intent.getDoubleExtra("lat", 0);
                    double lng = intent.getDoubleExtra("lng", 0);
                    float heading = intent.getFloatExtra("heading", 0f);
                    float speed = intent.getFloatExtra("speed", 0f);

                    Handler mainHandler = new Handler(Looper.getMainLooper());
                    mainHandler.post(() -> {
                        if (eventSink != null) {
                            eventSink.success(java.util.Map.of(
                                "lat", lat,
                                "lng", lng,
                                "heading", heading,
                                "speed", speed
                            ));
                        }
                    });
                }
            }
        };

        IntentFilter filter = new IntentFilter("com.example.fe_food_go_driver.LOCATION_UPDATE");
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(locationReceiver, filter, Context.RECEIVER_NOT_EXPORTED);
        } else {
            registerReceiver(locationReceiver, filter);
        }
        receiverRegistered = true;
    }

    private void unregisterLocationReceiver() {
        if (!receiverRegistered || locationReceiver == null) return;
        try {
            unregisterReceiver(locationReceiver);
        } catch (Exception ignored) {}
        locationReceiver = null;
        receiverRegistered = false;
    }

    private void startBgService() {
        LocationServiceHelper.start(this);
    }

    private void stopBgService() {
        LocationServiceHelper.stop(this);
    }

    @Override
    protected void onDestroy() {
        unregisterLocationReceiver();
        super.onDestroy();
    }
}
