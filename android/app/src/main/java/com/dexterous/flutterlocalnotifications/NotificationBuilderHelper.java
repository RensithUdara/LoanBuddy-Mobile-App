package com.dexterous.flutterlocalnotifications;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationChannelGroup;
import android.app.NotificationManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.os.Build;
import androidx.annotation.Keep;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import java.util.ArrayList;

/**
 * This is a patched version of part of the FlutterLocalNotificationsPlugin
 * class
 * to fix the ambiguous reference to bigLargeIcon method.
 */
@Keep
public class NotificationBuilderHelper {

    /**
     * Explicitly specifying the Bitmap version of bigLargeIcon to fix the ambiguous
     * method reference.
     */
    public static void setBigPictureStyleBigLargeIconToNull(NotificationCompat.BigPictureStyle bigPictureStyle) {
        // Using the Bitmap version of the method to avoid ambiguity
        Bitmap nullBitmap = null;
        bigPictureStyle.bigLargeIcon(nullBitmap);
    }
}