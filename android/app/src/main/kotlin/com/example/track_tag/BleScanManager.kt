package com.example.track_tag

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.*
import android.content.Context
import android.os.Build // Add this import
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat // Import for ContextCompat
import android.Manifest // Import for Manifest
import android.content.pm.PackageManager // Import for PackageManager

class BleScanManager(private val context: Context) {
    private val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter? = bluetoothManager.adapter
    private val bleScanner: BluetoothLeScanner? = bluetoothAdapter?.bluetoothLeScanner
    private var scanCallback: ScanCallback? = null
    private val handler = Handler(Looper.getMainLooper())
    
    private val SCAN_PERIOD: Long = 8000  // Restart scanning every 8 seconds

    @SuppressLint("MissingPermission")
    fun startScan() {
        if (bluetoothAdapter == null || !bluetoothAdapter.isEnabled) {
            Log.e("BleScanManager", "Bluetooth is disabled or not available.")
            return
        }
        if (!hasRequiredPermissions()) {
            Log.e("BleScanManager", "Required Bluetooth permissions not granted.")
            return
        }

        val scanSettings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .setReportDelay(0)
            .build()

        val scanFilters = listOf<ScanFilter>()
        
        scanCallback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                super.onScanResult(callbackType, result)
                Log.d("BleScanManager", "Found device: ${result.device.address}")
            }
        }

        bleScanner?.startScan(scanFilters, scanSettings, scanCallback!!)
        
        handler.postDelayed({
            stopScan()
            startScan()
        }, SCAN_PERIOD)
    }

    private fun hasRequiredPermissions(): Boolean {
        val context = this.context
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
        } else {
            ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        }
    }

    @SuppressLint("MissingPermission")
    fun stopScan() {
        scanCallback?.let { bleScanner?.stopScan(it) }
        scanCallback = null
    }
}