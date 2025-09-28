package com.safty_gadgate.safty_app

import android.Manifest
import android.bluetooth.*
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.database.Cursor
import android.os.Build
import android.provider.ContactsContract
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.*

class MainActivity : FlutterActivity() {

    private val CONTACTS_CHANNEL = "com.safty_gadgate.safty_app/contacts"
    private val BLUETOOTH_CHANNEL = "com.safty_gadgate.safty_app/bluetooth"
    private val BLUETOOTH_EVENT_CHANNEL = "com.safty_gadgate.safty_app/bluetooth_events"
    private val PERMISSION_REQUEST_CODE = 101

    private var bluetoothAdapter: BluetoothAdapter? = null
    private var eventSink: EventChannel.EventSink? = null

    private val bluetoothReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val action = intent?.action
            if (BluetoothDevice.ACTION_FOUND == action) {
                val device: BluetoothDevice? =
                    intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                device?.let {
                    eventSink?.success(
                        mapOf("name" to (it.name ?: "Unknown"), "address" to it.address)
                    )
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()

        // ---------------- Contacts ----------------
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CONTACTS_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getContacts") {
                    if (!hasContactsPermission()) {
                        requestContactsPermission()
                        result.error("PERMISSION_DENIED", "Contacts permission denied", null)
                    } else {
                        result.success(getAllContacts())
                    }
                } else {
                    result.notImplemented()
                }
            }

        // ---------------- Bluetooth ----------------
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BLUETOOTH_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkBluetooth" -> result.success(bluetoothAdapter?.isEnabled == true)

                    "enableBluetooth" -> {
                        if (bluetoothAdapter != null && !bluetoothAdapter!!.isEnabled) {
                            val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
                            startActivity(enableBtIntent)
                        }
                        result.success(true)
                    }

                    "connectDevice" -> {
                        val address = call.argument<String>("address") ?: ""
                        val device = bluetoothAdapter?.getRemoteDevice(address)
                        if (device != null) {
                            connectToClassicDevice(device, result)
                        } else {
                            result.success(false)
                        }
                    }

                    else -> result.notImplemented()
                }
            }

        // ---------------- Bluetooth EventChannel ----------------
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, BLUETOOTH_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    startDiscovery()
                }

                override fun onCancel(arguments: Any?) {
                    stopDiscovery()
                    eventSink = null
                }
            })
    }

    // ---------------- Contacts ----------------
    private fun hasContactsPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.READ_CONTACTS
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestContactsPermission() {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.READ_CONTACTS),
            PERMISSION_REQUEST_CODE
        )
    }

    private fun getAllContacts(): List<Map<String, String>> {
        val contactsList = mutableListOf<Map<String, String>>()
        val cursor: Cursor? = contentResolver.query(
            ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
            null,
            null,
            null,
            "${ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME} ASC"
        )
        cursor?.use { c ->
            val nameIndex = c.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
            val phoneIndex = c.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)
            while (c.moveToNext()) {
                val name = c.getString(nameIndex)
                val phone = c.getString(phoneIndex)
                contactsList.add(mapOf("name" to name, "phone" to phone))
            }
        }
        return contactsList
    }

    // ---------------- Bluetooth ----------------
    private fun hasBluetoothPermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED &&
                    ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED &&
                    ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        } else {
            ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH) == PackageManager.PERMISSION_GRANTED &&
                    ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestBluetoothPermissions() {
        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.ACCESS_FINE_LOCATION
            )
        } else {
            arrayOf(
                Manifest.permission.BLUETOOTH,
                Manifest.permission.ACCESS_FINE_LOCATION
            )
        }
        ActivityCompat.requestPermissions(this, permissions, PERMISSION_REQUEST_CODE)
    }

    private fun startDiscovery() {
        if (!hasBluetoothPermissions()) {
            requestBluetoothPermissions()
            return
        }

        val filter = IntentFilter(BluetoothDevice.ACTION_FOUND)
        registerReceiver(bluetoothReceiver, filter)

        // Send paired devices first
        bluetoothAdapter?.bondedDevices?.forEach { device ->
            eventSink?.success(
                mapOf("name" to (device.name ?: "Unknown"), "address" to device.address)
            )
        }

        bluetoothAdapter?.startDiscovery()
    }

    private fun stopDiscovery() {
        bluetoothAdapter?.cancelDiscovery()
        try {
            unregisterReceiver(bluetoothReceiver)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    // ---------------- Connect SPP ----------------
    private fun connectToClassicDevice(device: BluetoothDevice, result: MethodChannel.Result) {
        Thread {
            try {
                bluetoothAdapter?.cancelDiscovery()
                Thread.sleep(500)

                // Pair if not bonded
                if (device.bondState != BluetoothDevice.BOND_BONDED) {
                    val method = device.javaClass.getMethod("createBond")
                    method.invoke(device)

                    var attempts = 0
                    while (device.bondState != BluetoothDevice.BOND_BONDED && attempts < 25) {
                        Thread.sleep(1000)
                        attempts++
                    }
                    Thread.sleep(1500) // extra wait
                    if (device.bondState != BluetoothDevice.BOND_BONDED) {
                        runOnUiThread { result.success(false) }
                        return@Thread
                    }
                }

                // Retry SPP connection
                val uuid = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
                var socket: BluetoothSocket? = null
                var connected = false
                var retries = 0

                while (!connected && retries < 3) {
                    try {
                        socket = device.createRfcommSocketToServiceRecord(uuid)
                        socket.connect()
                        connected = true
                    } catch (e: IOException) {
                        e.printStackTrace()
                        socket?.close()
                        socket = device.javaClass.getMethod("createRfcommSocket", Int::class.java)
                            .invoke(device, 1) as BluetoothSocket
                        socket.connect()
                        connected = true
                    } finally {
                        retries++
                    }
                }

                runOnUiThread { result.success(connected) }

            } catch (e: Exception) {
                e.printStackTrace()
                runOnUiThread { result.success(false) }
            }
        }.start()
    }

    override fun onDestroy() {
        super.onDestroy()
        stopDiscovery()
    }
}
