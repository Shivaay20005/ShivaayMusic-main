package com.shivaay20005.shivaaymusic.ui.screens.settings

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarScrollBehavior
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.TextFieldValue
import androidx.navigation.NavController
import com.shivaay20005.innertube.YouTube
import com.shivaay20005.innertube.utils.parseCookieString
import com.shivaay20005.shivaaymusic.App.Companion.forgetAccount
import com.shivaay20005.shivaaymusic.LocalPlayerAwareWindowInsets
import com.shivaay20005.shivaaymusic.R
import com.shivaay20005.shivaaymusic.constants.AccountChannelHandleKey
import com.shivaay20005.shivaaymusic.constants.AccountEmailKey
import com.shivaay20005.shivaaymusic.constants.AccountNameKey
import com.shivaay20005.shivaaymusic.constants.DataSyncIdKey
import com.shivaay20005.shivaaymusic.constants.InnerTubeCookieKey
import com.shivaay20005.shivaaymusic.constants.UseLoginForBrowse
import com.shivaay20005.shivaaymusic.constants.VisitorDataKey
import com.shivaay20005.shivaaymusic.constants.YtmSyncKey
import com.shivaay20005.shivaaymusic.ui.component.IconButton
import com.shivaay20005.shivaaymusic.ui.component.InfoLabel
import com.shivaay20005.shivaaymusic.ui.component.PreferenceEntry
import com.shivaay20005.shivaaymusic.ui.component.PreferenceGroupTitle
import com.shivaay20005.shivaaymusic.ui.component.SwitchPreference
import com.shivaay20005.shivaaymusic.ui.component.TextFieldDialog
import com.shivaay20005.shivaaymusic.ui.utils.backToMain
import com.shivaay20005.shivaaymusic.utils.rememberPreference

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AccountSettings(
    navController: NavController,
    scrollBehavior: TopAppBarScrollBehavior,
) {
    val context = LocalContext.current

    val (accountName, onAccountNameChange) = rememberPreference(AccountNameKey, "")
    val (accountEmail, onAccountEmailChange) = rememberPreference(AccountEmailKey, "")
    val (accountChannelHandle, onAccountChannelHandleChange) = rememberPreference(
        AccountChannelHandleKey,
        ""
    )
    val (innerTubeCookie, onInnerTubeCookieChange) = rememberPreference(InnerTubeCookieKey, "")
    val (visitorData, onVisitorDataChange) = rememberPreference(VisitorDataKey, "")
    val (dataSyncId, onDataSyncIdChange) = rememberPreference(DataSyncIdKey, "")

    val isLoggedIn = remember(innerTubeCookie) {
        innerTubeCookie.isNotEmpty() && "SAPISID" in parseCookieString(innerTubeCookie)
    }

    // Function to safely get account display name
    val getAccountDisplayName =
        remember(accountName, accountEmail, accountChannelHandle, isLoggedIn) {
            when {
                !isLoggedIn -> ""
                accountName.isNotBlank() -> accountName
                accountEmail.isNotBlank() -> accountEmail.substringBefore("@")
                accountChannelHandle.isNotBlank() -> accountChannelHandle
                else -> "Unnamed User" // Fallback to prevent crashes
            }
        }

    // Function to safely get account description
    val getAccountDescription = remember(accountEmail, accountChannelHandle, isLoggedIn) {
        when {
            !isLoggedIn -> null
            accountEmail.isNotBlank() -> accountEmail
            accountChannelHandle.isNotBlank() -> accountChannelHandle
            else -> null
        }
    }

    val (useLoginForBrowse, onUseLoginForBrowseChange) = rememberPreference(UseLoginForBrowse, true)
    val (ytmSync, onYtmSyncChange) = rememberPreference(YtmSyncKey, defaultValue = true)

    var showToken: Boolean by remember {
        mutableStateOf(false)
    }
    var showTokenEditor by remember {
        mutableStateOf(false)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.account)) },
                navigationIcon = {
                    IconButton(
                        onClick = navController::navigateUp,
                        onLongClick = navController::backToMain
                    ) {
                        Icon(
                            painterResource(R.drawable.arrow_back),
                            contentDescription = null
                        )
                    }
                },
                scrollBehavior = scrollBehavior
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .padding(paddingValues)
                .windowInsetsPadding(
                    LocalPlayerAwareWindowInsets.current.only(
                        WindowInsetsSides.Horizontal + WindowInsetsSides.Bottom
                    )
                )
                .verticalScroll(rememberScrollState())
        ) {

            PreferenceGroupTitle(
                title = stringResource(R.string.google),
            )

            PreferenceEntry(
                title = {
                    Text(
                        if (isLoggedIn) {
                            getAccountDisplayName.takeIf { it.isNotBlank() }
                                ?: stringResource(R.string.login)
                        } else {
                            stringResource(R.string.login)
                        }
                    )
                },
                description = if (isLoggedIn) getAccountDescription else null,
                icon = { Icon(painterResource(R.drawable.login), null) },
                trailingContent = {
                    if (isLoggedIn) {
                        OutlinedButton(onClick = {
                            // Clear all account data
                            onInnerTubeCookieChange("")
                            onAccountNameChange("")
                            onAccountEmailChange("")
                            onAccountChannelHandleChange("")
                            onVisitorDataChange("")
                            onDataSyncIdChange("")
                            forgetAccount(context)
                        }
                        ) {
                            Text(stringResource(R.string.logout))
                        }
                    }
                },
                onClick = { if (!isLoggedIn) navController.navigate("login") }
            )

            if (showTokenEditor) {
                val text =
                    "*** COOKIE*** =${innerTubeCookie}\n\n***VISITOR DATA*** =${visitorData}\n\n***DATASYNC ID*** =${dataSyncId}\n\n***ACCOUNT NAME*** =${accountName}\n\n***ACCOUNT EMAIL*** =${accountEmail}\n\n***ACCOUNT CHANNEL HANDLE*** =${accountChannelHandle}"
                TextFieldDialog(
                    modifier = Modifier,
                    initialTextFieldValue = TextFieldValue(text),
                    onDone = { data ->
                        data.split("\n").forEach {
                            when {
                                it.startsWith("*** COOKIE*** =") -> {
                                    val cookie =
                                        it.substringAfter("*** COOKIE*** =").trim()
                                    onInnerTubeCookieChange(cookie)
                                }

                                it.startsWith("***VISITOR DATA*** =") -> {
                                    val visitorDataValue =
                                        it.substringAfter("***VISITOR DATA*** =").trim()
                                    onVisitorDataChange(visitorDataValue)
                                }

                                it.startsWith("***DATASYNC ID*** =") -> {
                                    val dataSyncIdValue =
                                        it.substringAfter("***DATASYNC ID*** =").trim()
                                    onDataSyncIdChange(dataSyncIdValue)
                                }

                                it.startsWith("***ACCOUNT NAME*** =") -> {
                                    val name = it.substringAfter("***ACCOUNT NAME*** =").trim()
                                    onAccountNameChange(name)
                                }

                                it.startsWith("***ACCOUNT EMAIL*** =") -> {
                                    val email = it.substringAfter("***ACCOUNT EMAIL*** =").trim()
                                    onAccountEmailChange(email)
                                }

                                it.startsWith("***ACCOUNT CHANNEL HANDLE*** =") -> {
                                    val handle =
                                        it.substringAfter("***ACCOUNT CHANNEL HANDLE*** =").trim()
                                    onAccountChannelHandleChange(handle)
                                }
                            }
                        }
                    },
                    onDismiss = { showTokenEditor = false },
                    singleLine = false,
                    maxLines = 20,
                    isInputValid = { input ->
                        input.isNotEmpty() &&
                                try {
                                    val cookieLine = input.lines()
                                        .find { it.startsWith("*** COOKIE*** =") }
                                    if (cookieLine != null) {
                                        val cookie =
                                            cookieLine.substringAfter("*** COOKIE*** =")
                                                .trim()
                                        cookie.isEmpty() || "SAPISID" in parseCookieString(cookie)
                                    } else {
                                        false
                                    }
                                } catch (e: Exception) {
                                    false
                                }
                    },
                    extraContent = {
                        InfoLabel(text = stringResource(R.string.token_adv_login_description))
                    }
                )
            }

            PreferenceEntry(
                title = {
                    if (!isLoggedIn) {
                        Text(stringResource(R.string.advanced_login))
                    } else {
                        if (showToken) {
                            Text(stringResource(R.string.token_shown))
                        } else {
                            Text(stringResource(R.string.token_hidden))
                        }
                    }
                },
                icon = { Icon(painterResource(R.drawable.token), null) },
                onClick = {
                    if (!isLoggedIn) {
                        showTokenEditor = true
                    } else {
                        if (!showToken) {
                            showToken = true
                        } else {
                            showTokenEditor = true
                        }
                    }
                },
            )

            if (isLoggedIn) {
                SwitchPreference(
                    title = { Text(stringResource(R.string.use_login_for_browse)) },
                    description = stringResource(R.string.use_login_for_browse_desc),
                    icon = { Icon(painterResource(R.drawable.person), null) },
                    checked = useLoginForBrowse,
                    onCheckedChange = {
                        YouTube.useLoginForBrowse = it
                        onUseLoginForBrowseChange(it)
                    }
                )
            }

            if (isLoggedIn) {
                SwitchPreference(
                    title = { Text(stringResource(R.string.ytm_sync)) },
                    icon = { Icon(painterResource(R.drawable.cached), null) },
                    checked = ytmSync,
                    onCheckedChange = onYtmSyncChange,
                    isEnabled = isLoggedIn
                )
            }

            // Discord integration disabled
            // PreferenceGroupTitle(
            //     title = stringResource(R.string.discord),
            // )

            // PreferenceEntry(
            //     title = { Text(stringResource(R.string.discord_integration)) },
            //     icon = { Icon(painterResource(R.drawable.discord), null) },
            //     onClick = { navController.navigate("settings/discord") }
            // )
        }
    }
}