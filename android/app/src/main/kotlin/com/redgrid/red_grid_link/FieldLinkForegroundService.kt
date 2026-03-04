package com.redgrid.red_grid_link

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class FieldLinkForegroundService : Service() {
    companion object {
        const val CHANNEL_ID = "field_link_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_STOP = "com.redgrid.link.STOP_SERVICE"
        const val EXTRA_PEER_COUNT = "peer_count"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }

        val peerCount = intent?.getIntExtra(EXTRA_PEER_COUNT, 0) ?: 0
        val notification = buildNotification(peerCount)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Field Link",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Field Link proximity sync status"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(peerCount: Int): Notification {
        val stopIntent = Intent(this, FieldLinkForegroundService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Launch app when notification tapped
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val launchPendingIntent = PendingIntent.getActivity(
            this, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val contentText = if (peerCount > 0) {
            "Field Link Active — $peerCount peer${if (peerCount != 1) "s" else ""} connected"
        } else {
            "Field Link Active — Scanning for peers"
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Red Grid Link")
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setOngoing(true)
            .setContentIntent(launchPendingIntent)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Stop",
                stopPendingIntent
            )
            .build()
    }

    fun updatePeerCount(peerCount: Int) {
        val notification = buildNotification(peerCount)
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, notification)
    }
}
