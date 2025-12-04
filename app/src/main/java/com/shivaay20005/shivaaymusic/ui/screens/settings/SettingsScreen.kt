package com.shivaay20005.shivaaymusic.ui.screens.settings

import android.annotation.SuppressLint
import android.app.DownloadManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.annotation.RequiresApi
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarScrollBehavior
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.platform.UriHandler
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.core.content.FileProvider
import androidx.core.net.toUri
import androidx.navigation.NavController
import coil.compose.AsyncImage
import coil.request.ImageRequest
import com.shivaay20005.innertube.utils.parseCookieString
import com.shivaay20005.shivaaymusic.BuildConfig
import com.shivaay20005.shivaaymusic.LocalPlayerAwareWindowInsets
import com.shivaay20005.shivaaymusic.R
import com.shivaay20005.shivaaymusic.constants.AccountNameKey
import com.shivaay20005.shivaaymusic.constants.InnerTubeCookieKey
import com.shivaay20005.shivaaymusic.constants.IsUserLoggedInKey
import com.shivaay20005.shivaaymusic.constants.LoggedInUserEmailKey
import com.shivaay20005.shivaaymusic.constants.LoggedInUserNameKey
import com.shivaay20005.shivaaymusic.ui.component.ChangelogButton
import com.shivaay20005.shivaaymusic.ui.component.IconButton
import com.shivaay20005.shivaaymusic.ui.component.PreferenceEntry
import com.shivaay20005.shivaaymusic.ui.utils.backToMain
import com.shivaay20005.shivaaymusic.utils.rememberPreference
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.File
import java.net.URL


@SuppressLint("ObsoleteSdkInt")
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
fun getAppVersion(context: Context): String {
    return try {
        val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.packageManager.getPackageInfo(
                context.packageName,
                PackageManager.PackageInfoFlags.of(0) // ✅ Only on Android 13+
            )
        } else {
            @Suppress("DEPRECATION") // Avoid compilation warnings
            context.packageManager.getPackageInfo(
                context.packageName,
                0 // ✅ Compatible with Android 12 and earlier versions
            )
        }
        packageInfo.versionName ?: "Unknown" // If versionName is null, return "Unknown"
    } catch (e: PackageManager.NameNotFoundException) {
        "Unknown" // If an error occurs, return "Unknown"
    }
}

@RequiresApi(Build.VERSION_CODES.TIRAMISU)
@Composable
fun VersionCard(uriHandler: UriHandler) {
    val context = LocalContext.current
    val appVersion = remember { getAppVersion(context) }


    Spacer(Modifier.height(25.dp))
    ElevatedCard(
        elevation = CardDefaults.cardElevation(
            defaultElevation = 6.dp
        ),
        modifier = Modifier
//            .clip(RoundedCornerShape(38.dp))
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .height(85.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface,

            ),
        shape = RoundedCornerShape(38.dp),
        onClick = { uriHandler.openUri("https://github.com/shivaay20005/shivaaymusic/releases/latest") }
    ) {
        Column(
            modifier = Modifier
                .clip(RoundedCornerShape(38.dp))
                .padding(20.dp),
            verticalArrangement = Arrangement.Center
        ) {
            Spacer(Modifier.height(3.dp))
            Text(
                text = "${stringResource(R.string.Version)} $appVersion",
                style = MaterialTheme.typography.bodyLarge.copy(
                    fontSize = 17.sp,
                    fontFamily = FontFamily.Monospace
                ),
                color = MaterialTheme.colorScheme.secondary,
                modifier = Modifier.align(Alignment.CenterHorizontally),


                )
        }
    }
}


@Composable
fun UpdateCard(latestVersion: String = "") {
    val context = LocalContext.current
    var showUpdateCard by remember { mutableStateOf(false) }
    var currentLatestVersion by remember { mutableStateOf(latestVersion) }
    var showDownloadDialog by remember { mutableStateOf(false) }


    // Check for updates at startup
    LaunchedEffect(Unit) {
        val newVersion = checkForUpdates()
        if (newVersion != null && isNewerVersion(newVersion, BuildConfig.VERSION_NAME)) {
            showUpdateCard = true
            currentLatestVersion = newVersion
        }
    }

    // Download dialog
    if (showDownloadDialog) {
        UpdateDownloadDialog(
            latestVersion = currentLatestVersion,
            onDismiss = { showDownloadDialog = false }
        )
    }

    // Available update card
    if (showUpdateCard) {
        Spacer(Modifier.height(25.dp))
        ElevatedCard(
            elevation = CardDefaults.cardElevation(
                defaultElevation = 6.dp
            ),
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
                .height(170.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceContainerHigh,
            ),
            shape = RoundedCornerShape(38.dp),
            onClick = {
                showDownloadDialog = true
            }
        ) {
            Column(
                modifier = Modifier
                    .padding(20.dp),
                verticalArrangement = Arrangement.Center
            ) {
                Spacer(Modifier.height(3.dp))

                val newVersion = stringResource(R.string.NewVersion)
                val tapToUpdate = stringResource(R.string.tap_to_update)
                val warn = stringResource(R.string.warn)

                // Main line: "NewVersion: currentLatestVersion"
                Text(
                    text = "$newVersion: $currentLatestVersion",
                    style = MaterialTheme.typography.bodyLarge.copy(
                        fontSize = 18.sp,
                        fontFamily = FontFamily.Monospace
                    ),
                    color = MaterialTheme.colorScheme.secondary,
                )

                Spacer(Modifier.height(8.dp))

                // Warning
                Text(
                    text = "$warn ",
                    style = MaterialTheme.typography.bodyMedium.copy(
                        fontSize = 16.sp,
                        fontFamily = FontFamily.Monospace
                    ),
                    color = MaterialTheme.colorScheme.error,
                )

                Spacer(Modifier.height(8.dp))

                // Tap to update (action)
                Text(
                    text = tapToUpdate,
                    style = MaterialTheme.typography.bodyMedium.copy(
                        fontSize = 16.sp
                    ),
                    color = MaterialTheme.colorScheme.primary,
                )
            }

        }
    }
}

@Composable
fun UpdateDownloadDialog(
    latestVersion: String,
    onDismiss: () -> Unit
) {
    val context = LocalContext.current
    var downloadProgress by remember { mutableStateOf(0f) }
    var downloadStatus by remember { mutableStateOf(DownloadStatus.NOT_STARTED) }
    var downloadedApkUri by remember { mutableStateOf<Uri?>(null) }
    val downloadScope = rememberCoroutineScope()

    val installPermissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.StartActivityForResult()
    ) {
        // When returning from the permissions screen, we check again if we can install
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (context.packageManager.canRequestPackageInstalls() && downloadedApkUri != null) {
                // Now that we have permission, we proceed with installation
                installApk(context, downloadedApkUri!!)
            }
        }
    }

    // Dialog to show progress and options
    Dialog(onDismissRequest = {
        if (downloadStatus != DownloadStatus.DOWNLOADING) {
            onDismiss()
        }
    }) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            shape = RoundedCornerShape(28.dp),
        ) {
            Column(
                modifier = Modifier
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = stringResource(id = R.string.update_version, latestVersion),
                    style = MaterialTheme.typography.headlineSmall
                )

                Spacer(modifier = Modifier.height(16.dp))

                when (downloadStatus) {
                    DownloadStatus.NOT_STARTED -> {
                        Text(stringResource(R.string.download_question))
                        Spacer(modifier = Modifier.height(16.dp))
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            TextButton(onClick = onDismiss) {
                                Text(stringResource(R.string.cancel))
                            }
                            Button(onClick = {
                                downloadStatus = DownloadStatus.DOWNLOADING
                                downloadScope.launch {
                                    downloadedApkUri =
                                        downloadApk(context, latestVersion) { progress ->
                                            downloadProgress = progress
                                            if (progress >= 1f) {
                                                downloadStatus = DownloadStatus.COMPLETED
                                            }
                                        }
                                }
                            }) {
                                Text(stringResource(R.string.download))
                            }
                        }
                    }

                    DownloadStatus.DOWNLOADING -> {
                        Text(stringResource(R.string.downloadingup))
                        Spacer(modifier = Modifier.height(16.dp))
                        LinearProgressIndicator(
                            progress = { downloadProgress },
                            modifier = Modifier.fillMaxWidth()
                        )
                        Text(
                            text = "${(downloadProgress * 100).toInt()}%",
                            modifier = Modifier.padding(top = 8.dp)
                        )
                    }

                    DownloadStatus.COMPLETED -> {
                        Text(stringResource(R.string.download_completed))
                        Spacer(modifier = Modifier.height(16.dp))
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            TextButton(onClick = onDismiss) {
                                Text(stringResource(R.string.close))
                            }
                            // Modify only the install button part in the COMPLETED case
                            Button(onClick = {
                                if (downloadedApkUri != null) {
                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                        if (!context.packageManager.canRequestPackageInstalls()) {
                                            val intent =
                                                Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES)
                                                    .setData("package:${context.packageName}".toUri())

                                            installPermissionLauncher.launch(intent)
                                        } else {
                                            // Pass the Uri object directly, not a string
                                            installApk(context, downloadedApkUri!!)
                                        }
                                    } else {
                                        // Pass the Uri object directly, not a string
                                        installApk(context, downloadedApkUri!!)
                                    }
                                }
                            }) {
                                Text(stringResource(R.string.install))
                            }
                        }
                    }

                    DownloadStatus.ERROR -> {
                        Text(stringResource(R.string.download_errorup))
                        Spacer(modifier = Modifier.height(16.dp))
                        Button(onClick = onDismiss) {
                            Text(stringResource(R.string.close))
                        }
                    }
                }
            }
        }
    }
}


enum class DownloadStatus {
    NOT_STARTED,
    DOWNLOADING,
    COMPLETED,
    ERROR
}

suspend fun downloadApk(
    context: Context,
    version: String,
    onProgressUpdate: (Float) -> Unit
): Uri? = withContext(Dispatchers.IO) {
    try {
        // URL of the APK (adjust this URL according to where your APK files are hosted)
        val apkUrl =
            "https://github.com/shivaay20005/shivaaymusic/releases/download/$version/app-release.apk"

        // Create destination file
        val downloadDir = context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
        val apkFile = File(downloadDir, "app-release-$version.apk")

        // If it already exists, delete it
        if (apkFile.exists()) {
            apkFile.delete()
        }

        // Configure the DownloadManager
        val request = DownloadManager.Request(apkUrl.toUri())
            .setTitle("Downloading shivaaymusic v$version")
            .setDescription("Downloading update...")
            .setDestinationUri(Uri.fromFile(apkFile))
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE)

        val downloadManager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        val downloadId = downloadManager.enqueue(request)

        // Monitor progress
        var isDownloading = true
        while (isDownloading) {
            val query = DownloadManager.Query().setFilterById(downloadId)
            val cursor = downloadManager.query(query)

            if (cursor.moveToFirst()) {
                val statusColumn = cursor.getColumnIndex(DownloadManager.COLUMN_STATUS)
                val bytesDownloadedColumn =
                    cursor.getColumnIndex(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR)
                val bytesTotalColumn =
                    cursor.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES)

                if (statusColumn != -1 && bytesDownloadedColumn != -1 && bytesTotalColumn != -1) {
                    val status = cursor.getInt(statusColumn)
                    val bytesDownloaded = cursor.getLong(bytesDownloadedColumn)
                    val bytesTotal = cursor.getLong(bytesTotalColumn)

                    when (status) {
                        DownloadManager.STATUS_SUCCESSFUL -> {
                            isDownloading = false
                            onProgressUpdate(1f)
                        }

                        DownloadManager.STATUS_FAILED -> {
                            isDownloading = false
                            onProgressUpdate(0f)
                            return@withContext null
                        }

                        else -> {
                            if (bytesTotal > 0) {
                                val progress = bytesDownloaded.toFloat() / bytesTotal.toFloat()
                                onProgressUpdate(progress)
                            }
                        }
                    }
                }
            }
            cursor.close()
            delay(100) // Wait a bit before updating again
        }

        // Create Uri for installation with FileProvider
        return@withContext FileProvider.getUriForFile(
            context,
            "${context.packageName}.fileprovider",
            apkFile
        )
    } catch (e: Exception) {
        e.printStackTrace()
        return@withContext null
    }
}

// Corrected function to install APK using the URI directly
fun installApk(context: Context, apkUri: Uri) {
    // Verify and request permission to install APKs on Android 8+ (API 26+)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        val pm = context.packageManager
        val isAllowed = pm.canRequestPackageInstalls()
        if (!isAllowed) {
            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES)
                .setData("package:${context.packageName}".toUri())
            context.startActivity(intent)
            return // Exit so the user grants permission before continuing
        }
    }

    val installIntent = Intent(Intent.ACTION_VIEW).apply {
        setDataAndType(apkUri, "application/vnd.android.package-archive")
        flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK
    }

    context.startActivity(installIntent)
}

// These functions you already had
suspend fun checkForUpdates(): String? = withContext(Dispatchers.IO) {
    try {
        val url = URL("https://api.github.com/repos/shivaay20005/shivaaymusic/releases/latest")
        val connection = url.openConnection()
        connection.connect()
        val json = connection.getInputStream().bufferedReader().use { it.readText() }
        val jsonObject = JSONObject(json)
        return@withContext jsonObject.getString("tag_name")
    } catch (e: Exception) {
        e.printStackTrace()
        return@withContext null
    }
}

fun isNewerVersion(remoteVersion: String, currentVersion: String): Boolean {
    val remote = remoteVersion.removePrefix("v").split(".").map { it.toIntOrNull() ?: 0 }
    val current = currentVersion.removePrefix("v").split(".").map { it.toIntOrNull() ?: 0 }

    for (i in 0 until maxOf(remote.size, current.size)) {
        val r = remote.getOrNull(i) ?: 0
        val c = current.getOrNull(i) ?: 0
        if (r > c) return true
        if (r < c) return false
    }
    return false
}

@RequiresApi(Build.VERSION_CODES.TIRAMISU)
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    latestVersion: Long,
    navController: NavController,
    scrollBehavior: TopAppBarScrollBehavior,
) {


    val uriHandler = LocalUriHandler.current


//    var isBetaFunEnabled by remember { mutableStateOf(false) }


    Column(
        Modifier
            .windowInsetsPadding(LocalPlayerAwareWindowInsets.current.only(WindowInsetsSides.Horizontal + WindowInsetsSides.Bottom))
            .verticalScroll(rememberScrollState())
    ) {
        Spacer(
            Modifier.windowInsetsPadding(
                LocalPlayerAwareWindowInsets.current.only(
                    WindowInsetsSides.Top
                )
            )
        )
        val context = LocalContext.current
        val avatarManager = remember { AvatarPreferenceManager(context) }
        val customAvatarUri by avatarManager.getCustomAvatarUri.collectAsState(initial = null)
        val accountName by rememberPreference(AccountNameKey, "")
        val innerTubeCookie by rememberPreference(InnerTubeCookieKey, "")
        val isLoggedIn = remember(innerTubeCookie) {
            "SAPISID" in parseCookieString(innerTubeCookie)
        }

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            if (isLoggedIn) {
                var imageLoadError by remember { mutableStateOf(false) }
                var isImageLoading by remember { mutableStateOf(false) }

                // Avatar circular para usuario
                Box(
                    modifier = Modifier
                        .size(112.dp)
                        .clip(CircleShape)
                        .background(
                            brush = Brush.radialGradient(
                                colors = listOf(
                                    MaterialTheme.colorScheme.primary.copy(alpha = 0.1f),
                                    MaterialTheme.colorScheme.primary.copy(alpha = 0.3f)
                                )
                            )
                        )
                        .border(
                            width = 2.dp,
                            color = MaterialTheme.colorScheme.primary.copy(alpha = 0.5f),
                            shape = CircleShape
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    when {
                        // Mostrar avatar personalizado si existe y no hay error
                        customAvatarUri != null && !imageLoadError -> {
                            AsyncImage(
                                model = ImageRequest.Builder(LocalContext.current)
                                    .data(customAvatarUri!!.toUri())
                                    .crossfade(true)
                                    .listener(
                                        onStart = { isImageLoading = true },
                                        onSuccess = { _, _ ->
                                            isImageLoading = false
                                            imageLoadError = false
                                        },
                                        onError = { _, _ ->
                                            isImageLoading = false
                                            imageLoadError = true
                                        }
                                    )
                                    .build(),
                                contentDescription = "Avatar of $accountName",
                                modifier = Modifier
                                    .size(104.dp)
                                    .clip(CircleShape),
                                contentScale = ContentScale.Crop
                            )

                            // Loading overlay
                            if (isImageLoading) {
                                Box(
                                    modifier = Modifier
                                        .size(104.dp)
                                        .clip(CircleShape)
                                        .background(
                                            MaterialTheme.colorScheme.surface.copy(alpha = 0.7f)
                                        ),
                                    contentAlignment = Alignment.Center
                                ) {
                                    CircularProgressIndicator(
                                        modifier = Modifier.size(24.dp),
                                        strokeWidth = 2.dp,
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                }
                            }
                        }

                        // Show initials as fallback
                        else -> {
                            val initials = remember(accountName) {
                                val cleanName = accountName.replace("@", "").trim()
                                when {
                                    cleanName.isEmpty() -> "?"
                                    cleanName.contains(" ") -> {
                                        val parts = cleanName.split(" ")
                                        "${
                                            parts.first().firstOrNull()?.uppercase() ?: ""
                                        }${parts.last().firstOrNull()?.uppercase() ?: ""}"
                                    }

                                    else -> cleanName.take(2).uppercase()
                                }
                            }

                            Box(
                                modifier = Modifier
                                    .size(104.dp)
                                    .clip(CircleShape)
                                    .background(
                                        brush = Brush.radialGradient(
                                            colors = listOf(
                                                MaterialTheme.colorScheme.primary.copy(alpha = 0.8f),
                                                MaterialTheme.colorScheme.primary
                                            )
                                        )
                                    ),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    text = initials,
                                    color = MaterialTheme.colorScheme.onPrimary,
                                    style = MaterialTheme.typography.headlineMedium,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))

                Text(
                    text = accountName.replace("@", "").takeIf { it.isNotBlank() } ?: "",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            } else {
                // Logo for unauthenticated user
                Box(
                    modifier = Modifier
                        .size(90.dp)
                        .clip(CircleShape)
                        .background(
                            brush = Brush.radialGradient(
                                colors = listOf(
                                    MaterialTheme.colorScheme.primary.copy(alpha = 0.1f),
                                    MaterialTheme.colorScheme.primary.copy(alpha = 0.3f)
                                )
                            )
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Image(
                        painter = painterResource(R.drawable.source_icon),
                        contentDescription = "shivaaymusic Logo",
                        modifier = Modifier.size(80.dp),
                        colorFilter = ColorFilter.tint(MaterialTheme.colorScheme.primary)
                    )
                }
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = stringResource(R.string.app_name),
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.SemiBold
                )
            }
        }

        // User Profile Card - Show logged in user details
        val loggedInUserName by rememberPreference(LoggedInUserNameKey, "")
        val loggedInUserEmail by rememberPreference(LoggedInUserEmailKey, "")
        
        if (loggedInUserName.isNotEmpty() || loggedInUserEmail.isNotEmpty()) {
            Spacer(modifier = Modifier.height(16.dp))
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
                )
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // User avatar icon
                    Box(
                        modifier = Modifier
                            .size(48.dp)
                            .clip(CircleShape)
                            .background(MaterialTheme.colorScheme.primary),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = if (loggedInUserName.isNotEmpty()) 
                                loggedInUserName.first().uppercase() 
                            else "U",
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onPrimary
                        )
                    }
                    
                    Spacer(modifier = Modifier.size(16.dp))
                    
                    Column(
                        modifier = Modifier.weight(1f)
                    ) {
                        if (loggedInUserName.isNotEmpty()) {
                            Text(
                                text = loggedInUserName,
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.SemiBold,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                        }
                        if (loggedInUserEmail.isNotEmpty()) {
                            Text(
                                text = loggedInUserEmail,
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                    
                    Icon(
                        painter = painterResource(R.drawable.verified_user),
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(24.dp)
                    )
                }
            }
            Spacer(modifier = Modifier.height(8.dp))
        }

        // Extension to safely convert String to Uri
        fun String.toUri(): Uri? {
            return try {
                Uri.parse(this)
            } catch (e: Exception) {
                null
            }
        }

        PreferenceEntry(
            title = { Text(stringResource(R.string.appearance)) },
            icon = { Icon(painterResource(R.drawable.palette), null) },
            onClick = { navController.navigate("settings/appearance") },
        )
        PreferenceEntry(
            title = { Text(stringResource(R.string.account)) },
            icon = { Icon(painterResource(R.drawable.person), null) },
            onClick = { navController.navigate("settings/account") },
        )
        PreferenceEntry(
            title = { Text(stringResource(R.string.content)) },
            icon = { Icon(painterResource(R.drawable.language), null) },
            onClick = { navController.navigate("settings/content") },
        )
        PreferenceEntry(
            title = { Text(stringResource(R.string.player_and_audio)) },
            icon = { Icon(painterResource(R.drawable.play), null) },
            onClick = { navController.navigate("settings/player") },
        )
        PreferenceEntry(
            title = { Text(stringResource(R.string.storage)) },
            icon = { Icon(painterResource(R.drawable.storage), null) },
            onClick = { navController.navigate("settings/storage") },
        )
        PreferenceEntry(
            title = { Text(stringResource(R.string.privacy)) },
            icon = { Icon(painterResource(R.drawable.security), null) },
            onClick = { navController.navigate("settings/privacy") },
        )
        // Backup and Restore - Hidden as per user request
        // PreferenceEntry(
        //     title = { Text(stringResource(R.string.backup_restore)) },
        //     icon = { Icon(painterResource(R.drawable.restore), null) },
        //     onClick = { navController.navigate("settings/backup_restore") },
        // )
        PreferenceEntry(
            title = { Text(stringResource(R.string.about)) },
            icon = { Icon(painterResource(R.drawable.info), null) },
            onClick = { navController.navigate("settings/about") }
        )
//        PreferenceEntry(
//            title = { Text(stringResource(R.string.problem_solver)) },
//            icon = { Icon(painterResource(R.drawable.apps), null) },
//            onClick = { navController.navigate("settings/problem_solver") }
//        )
//        PreferenceEntry(
//            title = { Text(stringResource(R.string.Donate)) },
//            icon = { Icon(painterResource(R.drawable.paypal), null) },
//            onClick = { uriHandler.openUri("https://www.paypal.com/paypalme/shivaaymusic") }
//        )

        PreferenceEntry(
            title = { Text(stringResource(R.string.Telegramchanel)) },
            icon = { Icon(painterResource(R.drawable.telegram), null) },
            onClick = { uriHandler.openUri("https://t.me/shivaaymusic_updates") }
        )

        // TranslatePreference(uriHandler = uriHandler) // Hidden as per user request

        ChangelogButton()



        UpdateCard()
        Spacer(Modifier.height(25.dp))


        VersionCard(uriHandler)

        Spacer(Modifier.height(25.dp))


    }

    TopAppBar(


        title = { Text(stringResource(R.string.settings)) },
        modifier = Modifier
            .clip(RoundedCornerShape(bottomStart = 20.dp, bottomEnd = 20.dp)),
        navigationIcon = {
            IconButton(
                onClick = navController::navigateUp,
                onLongClick = navController::backToMain,
            )

            {
                Icon(
                    painterResource(R.drawable.arrow_back),
                    contentDescription = null,
                )
            }
        },
        scrollBehavior = scrollBehavior

    )
}

/*
@Composable
fun TranslatePreference(uriHandler: UriHandler) {
    var showDialog by remember { mutableStateOf(false) }

    PreferenceEntry(
        title = { Text(stringResource(R.string.Translate)) },
        icon = { Icon(painterResource(R.drawable.translate), null) },
        onClick = { showDialog = true }
    )

    if (showDialog) {
        AlertDialog(
            onDismissRequest = { showDialog = false },
            title = { Text(stringResource(R.string.Redirección)) },
            text = { Text(stringResource(R.string.poeditor_redirect)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        showDialog = false
                        uriHandler.openUri("https://poeditor.com/join/project/208BwCVaxx")
                    }
                ) {
                    Text("OK")
                }
            }
        )
    }
}
*/



