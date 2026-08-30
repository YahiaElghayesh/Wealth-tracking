package com.yahiaelghayesh.wealth_tracker

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import java.io.File

/**
 * Backs Settings > App updates' "Install" step -- the Dart side
 * (lib/core/update/app_update_service.dart) downloads the new APK straight
 * into the app's own cache dir via Dio, then hands the file path here to
 * launch the system package installer. A downloaded file can't be installed
 * with a raw `file://` URI on API 24+ (StrictMode blocks exposing it to
 * another app); it has to go through this app's own [FileProvider] (see
 * res/xml/file_paths.xml and the matching <provider> in AndroidManifest.xml)
 * to get a `content://` URI the installer is actually allowed to read.
 */
object AppUpdater {
    /** True once the user has granted "Install unknown apps" for this app --
     * a per-app toggle Android requires before `ACTION_VIEW` on an APK does
     * anything but silently fail. Always true below API 26, where this
     * permission didn't exist yet (installing from any source was allowed by
     * a single system-wide setting instead). */
    fun canInstall(activity: Activity): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            activity.packageManager.canRequestPackageInstalls()
        } else {
            true
        }
    }

    /** Sends the user to the system screen where they flip "Install unknown
     * apps" on for this app -- there's no runtime permission dialog for
     * this one, only a full Settings screen. */
    fun requestInstallPermission(activity: Activity) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val intent = Intent(android.provider.Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
            data = Uri.parse("package:${activity.packageName}")
        }
        activity.startActivity(intent)
    }

    /** Launches the system installer for the APK at [path]. Caller (Dart
     * side) is expected to have already confirmed [canInstall] -- if it
     * hasn't been granted, Android shows its own "blocked" screen instead of
     * this silently doing nothing, so this doesn't re-check here. */
    fun install(activity: Activity, path: String) {
        val file = File(path)
        val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.fileprovider", file)
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        activity.startActivity(intent)
    }
}
