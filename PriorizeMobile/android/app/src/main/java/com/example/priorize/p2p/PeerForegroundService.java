package com.example.priorize.p2p;

import android.app.*;
import android.content.Intent;
import android.os.IBinder;
import androidx.annotation.Nullable;
import com.example.priorize.MainActivity;
import com.example.priorize.R;

public class PeerForegroundService extends Service {
    public static final String ACTION_STOP = "com.example.priorize.STOP_P2P";
    private static final String CHANNEL_ID = "priorize_p2p";
    private static final int NOTIFICATION_ID = 7301;

    @Override
    public void onCreate() {
        super.onCreate();
        NotificationManager manager = getSystemService(NotificationManager.class);
        manager.createNotificationChannel(new NotificationChannel(
                CHANNEL_ID, "Compartilhamento P2P", NotificationManager.IMPORTANCE_LOW));
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null && ACTION_STOP.equals(intent.getAction())) {
            PeerRuntime.server().stop();
            stopForeground(STOP_FOREGROUND_REMOVE);
            stopSelf();
            return START_NOT_STICKY;
        }
        Intent openApp = new Intent(this, MainActivity.class);
        PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, openApp,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        Notification notification = new Notification.Builder(this, CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("Priorize P2P ativo")
                .setContentText("Este aparelho pode enviar arquivos mesmo com o app minimizado")
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .build();
        startForeground(NOTIFICATION_ID, notification);
        return START_STICKY;
    }

    @Override public void onDestroy() { PeerRuntime.server().stop(); super.onDestroy(); }
    @Nullable @Override public IBinder onBind(Intent intent) { return null; }
}
