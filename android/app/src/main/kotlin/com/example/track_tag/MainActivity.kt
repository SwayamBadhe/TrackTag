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
import android.provider.Settings
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "flutter_bluetooth"
    private val PERMISSION_REQUEST_CODE = 2
    private val ENABLE_BLUETOOTH_REQUEST_CODE = 1

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Start Foreground Service for BLE scanning
        val serviceIntent = Intent(this, MyForegroundService::class.java)
        startService(serviceIntent)

        // Check and request permissions on app start
        checkAndRequestPermissions()
    }

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

    /**
     * Request necessary permissions before enabling Bluetooth or BLE scanning.
     */
    private fun checkAndRequestPermissions(result: MethodChannel.Result? = null) {
        val permissionsToRequest = mutableListOf<String>()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Android 12+ requires BLUETOOTH_SCAN and BLUETOOTH_CONNECT permissions
            if (!isPermissionGranted(Manifest.permission.BLUETOOTH_SCAN)) {
                permissionsToRequest.add(Manifest.permission.BLUETOOTH_SCAN)
            }
            if (!isPermissionGranted(Manifest.permission.BLUETOOTH_CONNECT)) {
                permissionsToRequest.add(Manifest.permission.BLUETOOTH_CONNECT)
            }
        } else {
            // Android 11 and below require location permissions for BLE scanning
            if (!isPermissionGranted(Manifest.permission.ACCESS_FINE_LOCATION)) {
                permissionsToRequest.add(Manifest.permission.ACCESS_FINE_LOCATION)
            }
        }

        if (permissionsToRequest.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, permissionsToRequest.toTypedArray(), PERMISSION_REQUEST_CODE)
        } else {
            enableBluetooth(result)
        }
    }

    /**
     * Checks if a given permission is granted.
     */
    private fun isPermissionGranted(permission: String): Boolean {
        return ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
    }

    /**
     * Enables Bluetooth, requesting user permission if required.
     */
    private fun enableBluetooth(result: MethodChannel.Result?) {
        val bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val bluetoothAdapter: BluetoothAdapter? = bluetoothManager.adapter

        if (bluetoothAdapter == null) {
            result?.error("UNAVAILABLE", "Bluetooth not available on this device", null)
            return
        }

        if (!bluetoothAdapter.isEnabled) {
            if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.R) {
                // Directly enable Bluetooth on Android 11 and below (not recommended)
                bluetoothAdapter.enable()
                result?.success(null)
            } else {
                // Android 12+ requires user interaction
                val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
                startActivityForResult(enableBtIntent, ENABLE_BLUETOOTH_REQUEST_CODE)
            }
        } else {
            result?.success(null)
        }
    }

    /**
     * Checks if location services are enabled.
     */
    private fun checkLocationServices(result: MethodChannel.Result) {
        val locationMode: Int
        try {
            locationMode = Settings.Secure.getInt(contentResolver, Settings.Secure.LOCATION_MODE)
        } catch (e: Exception) {
            result.error("ERROR", "Failed to check location services: ${e.message}", null)
            return
        }

        result.success(locationMode != Settings.Secure.LOCATION_MODE_OFF)
    }

    /**
     * Handles the result of enabling Bluetooth.
     */
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == ENABLE_BLUETOOTH_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                sendFlutterMessage("onBluetoothEnabled")
            } else {
                sendFlutterMessage("onBluetoothDenied")
            }
        }
    }

    /**
     * Handles the result of permission requests.
     */
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            if (grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
                sendFlutterMessage("onPermissionsGranted")
            } else {
                sendFlutterMessage("onPermissionsDenied")
                Toast.makeText(this, "Permissions denied. Some features may not work.", Toast.LENGTH_LONG).show()
            }
        }
    }

    /**
     * Sends a message to Flutter via MethodChannel.
     */
    private fun sendFlutterMessage(method: String) {
        flutterEngine?.dartExecutor?.binaryMessenger?.let {
            MethodChannel(it, CHANNEL).invokeMethod(method, null)
        }
    }
}
