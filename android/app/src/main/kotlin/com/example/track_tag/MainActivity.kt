package com.example.track_tag

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "flutter_bluetooth"
    private val PERMISSION_REQUEST_CODE = 2
    private val ENABLE_BLUETOOTH_REQUEST_CODE = 1

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestEnableBluetooth" -> checkAndRequestPermissions(result)
                "checkLocationServices" -> checkLocationServices(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun checkAndRequestPermissions(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Android 12+ (API 31+)
            val permissionsToRequest = mutableListOf<String>()

            if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN) != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(Manifest.permission.BLUETOOTH_SCAN)
            }
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(Manifest.permission.BLUETOOTH_CONNECT)
            }

            if (permissionsToRequest.isNotEmpty()) {
                ActivityCompat.requestPermissions(this, permissionsToRequest.toTypedArray(), PERMISSION_REQUEST_CODE)
            } else {
                enableBluetooth(result)
            }
        } else {
            // Android 11 and below (API 30 and below)
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.ACCESS_FINE_LOCATION), PERMISSION_REQUEST_CODE)
            } else {
                enableBluetooth(result)
            }
        }
    }

    private fun enableBluetooth(result: MethodChannel.Result) {
        val bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val bluetoothAdapter: BluetoothAdapter? = bluetoothManager.adapter

        if (bluetoothAdapter == null) {
            result.error("UNAVAILABLE", "Bluetooth not available on this device", null)
            return
        }

        if (!bluetoothAdapter.isEnabled) {
            if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.R) {
                // Directly enable Bluetooth on Android 11 and below
                bluetoothAdapter.enable()
                result.success(null)
            } else {
                // Android 12+ requires user interaction
                val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
                startActivityForResult(enableBtIntent, ENABLE_BLUETOOTH_REQUEST_CODE)
                result.success(null)
            }
        } else {
            result.success(null)
        }
    }

    private fun checkLocationServices(result: MethodChannel.Result) {
        val locationMode: Int
        try {
            locationMode = android.provider.Settings.Secure.getInt(contentResolver, android.provider.Settings.Secure.LOCATION_MODE)
        } catch (e: Exception) {
            result.error("ERROR", "Failed to check location services: ${e.message}", null)
            return
        }

        if (locationMode == android.provider.Settings.Secure.LOCATION_MODE_OFF) {
            result.success(false)
        } else {
            result.success(true)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == ENABLE_BLUETOOTH_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
                    .invokeMethod("onBluetoothEnabled", null)
            } else {
                MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
                    .invokeMethod("onBluetoothDenied", null)
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            if (grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
                MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
                    .invokeMethod("onPermissionsGranted", null)
            } else {
                MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
                    .invokeMethod("onPermissionsDenied", null)
            }
        }
    }
}
