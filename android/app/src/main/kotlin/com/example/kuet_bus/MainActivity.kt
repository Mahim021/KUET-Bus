package com.example.kuet_bus

import android.Manifest
import android.accounts.AccountManager
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result

class MainActivity : FlutterActivity() {

    private val CHANNEL = "kuet_bus/accounts"
    private val GET_ACCOUNTS_REQUEST = 1001
    private var pendingResult: Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getGoogleAccounts") {
                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.GET_ACCOUNTS)
                        == PackageManager.PERMISSION_GRANTED) {
                        result.success(fetchAccounts())
                    } else {
                        pendingResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.GET_ACCOUNTS),
                            GET_ACCOUNTS_REQUEST
                        )
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == GET_ACCOUNTS_REQUEST) {
            // Return whatever accounts are accessible — empty list if denied.
            pendingResult?.success(fetchAccounts())
            pendingResult = null
        }
    }

    private fun fetchAccounts(): List<String> {
        return try {
            val accountManager = AccountManager.get(this)
            accountManager.getAccountsByType("com.google").map { it.name }
        } catch (_: Exception) {
            emptyList()
        }
    }
}
