package com.beratarpa.carkeep

import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * Arabanin Bluetooth'una baglanma/kopma (07 4). Manifest receiver: uygulama
 * olu olsa da calisir; Flutter motorunu uyandirmaz (K-03).
 *
 * `onReceive` 5 sn'yi gecmemeli (CLAUDE.md): butun is prefs okuma/yazma ve
 * bildirim basma, hepsi senkron ve kisa.
 */
class BtReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action != BluetoothDevice.ACTION_ACL_CONNECTED &&
            action != BluetoothDevice.ACTION_ACL_DISCONNECTED
        ) {
            return
        }

        // `address` okumak izin istemez; `name` ister, kullanilmiyor.
        val address = deviceAddress(intent) ?: return
        val prefs = EnginePrefs(context)
        if (!ReminderEngine.matchesCar(prefs, address)) {
            Log.d(TAG, "ignoring $action from $address")
            return
        }

        val now = System.currentTimeMillis()
        when (action) {
            BluetoothDevice.ACTION_ACL_CONNECTED -> ReminderEngine.onConnected(context, prefs, now)
            BluetoothDevice.ACTION_ACL_DISCONNECTED ->
                ReminderEngine.onDisconnected(context, prefs, now)
        }
    }

    private fun deviceAddress(intent: Intent): String? {
        val device: BluetoothDevice? = if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
        }
        return device?.address
    }

    companion object {
        private const val TAG = "CarKeep"
    }
}
