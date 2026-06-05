package com.example.fe_food_go_driver.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.location.Location
import android.os.Build
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.fe_food_go_driver.MainActivity
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority

class LocationForegroundService : Service() {

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationCallback: LocationCallback

    private var locationUpdateListener: LocationUpdateListener? = null

    interface LocationUpdateListener {
        fun onLocationUpdate(lat: Double, lng: Double, heading: Float, speed: Float)
    }

    companion object {
        private const val TAG = "LocationFgService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "location_tracking_channel"
        private const val CHANNEL_NAME = "Location Tracking"

        @Volatile
        var isRunning = false
            private set

        private var instance: LocationForegroundService? = null

        fun setListener(listener: LocationUpdateListener?) {
            instance?.locationUpdateListener = listener
        }

        fun start(context: Context) {
            val intent = Intent(context, LocationForegroundService::class.java)
            context.startForegroundService(intent)
        }

        fun stop(context: Context) {
            val intent = Intent(context, LocationForegroundService::class.java)
            context.stopService(intent)
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        createNotificationChannel()
        setupLocationCallback()
        Log.d(TAG, "Service onCreate")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service onStartCommand")

        val notification = buildNotification()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        isRunning = true
        startLocationUpdates()

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        Log.d(TAG, "Service onDestroy")
        isRunning = false
        instance = null
        locationUpdateListener = null
        stopLocationUpdates()
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Tracking driver location during active delivery"
            setShowBadge(false)
        }

        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.createNotificationChannel(channel)
    }

    private fun buildNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Driver Go")
            .setContentText("Dang giao hang - Cap nhat vi tri")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    private fun setupLocationCallback() {
        locationCallback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                result.lastLocation?.let { location ->
                    Log.d(TAG, "Location update: ${location.latitude}, ${location.longitude}")
                    locationUpdateListener?.onLocationUpdate(
                        location.latitude,
                        location.longitude,
                        if (location.hasBearing()) location.bearing else 0f,
                        if (location.hasSpeed()) location.speed else 0f
                    )
                    broadcastLocation(location)
                }
            }
        }
    }

    private fun broadcastLocation(location: Location) {
        val intent = Intent("com.example.fe_food_go_driver.LOCATION_UPDATE")
        intent.putExtra("lat", location.latitude)
        intent.putExtra("lng", location.longitude)
        intent.putExtra("heading", if (location.hasBearing()) location.bearing else 0f)
        intent.putExtra("speed", if (location.hasSpeed()) location.speed else 0f)
        sendBroadcast(intent)
    }

    private fun startLocationUpdates() {
        val locationRequest = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            10000L
        ).apply {
            setMinUpdateIntervalMillis(5000L)
            setMinUpdateDistanceMeters(5f)
        }.build()

        try {
            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback,
                Looper.getMainLooper()
            )
            Log.d(TAG, "Location updates started")
        } catch (e: SecurityException) {
            Log.e(TAG, "Location permission denied", e)
        }
    }

    private fun stopLocationUpdates() {
        fusedLocationClient.removeLocationUpdates(locationCallback)
        Log.d(TAG, "Location updates stopped")
    }
}
