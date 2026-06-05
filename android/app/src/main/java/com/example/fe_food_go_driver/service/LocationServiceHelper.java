package com.example.fe_food_go_driver.service;

import android.content.Context;
import android.content.Intent;

public class LocationServiceHelper {

    public static void start(Context context) {
        Intent intent = new Intent(context, LocationForegroundService.class);
        context.startForegroundService(intent);
    }

    public static void stop(Context context) {
        Intent intent = new Intent(context, LocationForegroundService.class);
        context.stopService(intent);
    }
}
