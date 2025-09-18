package com.dexterous.flutterlocalnotifications;

import android.graphics.Bitmap;
import androidx.core.app.NotificationCompat.BigPictureStyle;

public class FlutterLocalNotificationsPatch {
    /**
     * This is a utility method to fix the ambiguous reference to bigLargeIcon
     * in the FlutterLocalNotificationsPlugin.
     * 
     * @param style The BigPictureStyle to modify
     */
    public static void setBigLargeIconToNull(BigPictureStyle style) {
        // Using the appropriate overload to avoid ambiguity
        Bitmap nullBitmap = null;
        style.bigLargeIcon(nullBitmap);
    }
}