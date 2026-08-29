package de.huluvu.taugts

import android.content.Intent
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        configureAppInfoChannel(flutterEngine)
        configureExternalUrlChannel(flutterEngine)
    }

    private fun configureAppInfoChannel(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "taugts/app_info"
        ).setMethodCallHandler { call, result ->
            if (call.method != "getAppInfo") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            try {
                @Suppress("DEPRECATION")
                val packageInfo = packageManager.getPackageInfo(packageName, 0)
                val buildNumber = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    packageInfo.longVersionCode.toString()
                } else {
                    @Suppress("DEPRECATION")
                    packageInfo.versionCode.toString()
                }
                result.success(
                    mapOf(
                        "version" to packageInfo.versionName.orEmpty(),
                        "buildNumber" to buildNumber
                    )
                )
            } catch (error: Exception) {
                result.error("app_info_failed", error.message, null)
            }
        }
    }

    private fun configureExternalUrlChannel(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "taugts/external_url"
        ).setMethodCallHandler { call, result ->
            if (call.method != "open") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val url = call.argument<String>("url")
            if (url.isNullOrBlank()) {
                result.error("invalid_url", "URL fehlt.", null)
                return@setMethodCallHandler
            }
            try {
                startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                result.success(null)
            } catch (error: Exception) {
                result.error("open_failed", error.message, null)
            }
        }
    }
}
