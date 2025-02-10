package com.example.track_tag

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.*
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log

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

        val scanSettings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY) // High-performance mode
            .setReportDelay(0) // Get results instantly
            .build()

        val scanFilters = listOf<ScanFilter>() // No filters, scanning all devices
        
        scanCallback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                super.onScanResult(callbackType, result)
                Log.d("BleScanManager", "Found device: ${result.device.address}")
            }
        }

        bleScanner?.startScan(scanFilters, scanSettings, scanCallback!!)
        
        // Schedule restart to prevent scanning from stopping
        handler.postDelayed({
            stopScan()
            startScan()
        }, SCAN_PERIOD)
    }

    @SuppressLint("MissingPermission")
    fun stopScan() {
        scanCallback?.let { bleScanner?.stopScan(it) }
        scanCallback = null
    }
}
