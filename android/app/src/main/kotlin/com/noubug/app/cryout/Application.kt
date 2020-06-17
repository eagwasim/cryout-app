package com.noubug.app.cryout

import com.tekartik.sqflite.SqflitePlugin
import com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin
import io.flutter.app.FlutterApplication
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugins.firebasemessaging.FlutterFirebaseMessagingService

class Application : FlutterApplication(), PluginRegistrantCallback {

    override fun onCreate() {
        super.onCreate()
        FlutterFirebaseMessagingService.setPluginRegistrant(this)
    }

    override fun registerWith(registry: PluginRegistry?) {
        io.flutter.plugins.firebasemessaging.FirebaseMessagingPlugin.registerWith(registry?.registrarFor("io.flutter.plugins.firebasemessaging.FirebaseMessagingPlugin"));
        SqflitePlugin.registerWith(registry?.registrarFor("com.tekartik.sqflite.SqflitePlugin"));
        FlutterLocalNotificationsPlugin.registerWith(registry?.registrarFor("com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin"))
        io.flutter.plugins.pathprovider.PathProviderPlugin.registerWith(registry?.registrarFor("io.flutter.plugins.pathprovider.PathProviderPlugin"))
        io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin.registerWith(registry?.registrarFor("io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin"));
    }
}