//
// Generated file. Do not edit.
// This file is generated from template in file `flutter_tools/lib/src/flutter_plugins.dart`.
//

// @dart = 3.2

import 'dart:io'; // flutter_ignore: dart_io_import.
import 'package:flutter_blue_plus_android/flutter_blue_plus_android.dart' as flutter_blue_plus_android;
import 'package:geolocator_android/geolocator_android.dart' as geolocator_android;
import 'package:path_provider_android/path_provider_android.dart' as path_provider_android;
import 'package:shared_preferences_android/shared_preferences_android.dart' as shared_preferences_android;
import 'package:flutter_blue_plus_darwin/flutter_blue_plus_darwin.dart' as flutter_blue_plus_darwin;
import 'package:geolocator_apple/geolocator_apple.dart' as geolocator_apple;
import 'package:path_provider_foundation/path_provider_foundation.dart' as path_provider_foundation;
import 'package:shared_preferences_foundation/shared_preferences_foundation.dart' as shared_preferences_foundation;
import 'package:connectivity_plus/connectivity_plus.dart' as connectivity_plus;
import 'package:flutter_blue_plus_linux/flutter_blue_plus_linux.dart' as flutter_blue_plus_linux;
import 'package:package_info_plus/package_info_plus.dart' as package_info_plus;
import 'package:path_provider_linux/path_provider_linux.dart' as path_provider_linux;
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:shared_preferences_linux/shared_preferences_linux.dart' as shared_preferences_linux;
import 'package:url_launcher_linux/url_launcher_linux.dart' as url_launcher_linux;
import 'package:wakelock_plus/wakelock_plus.dart' as wakelock_plus;
import 'package:flutter_blue_plus_darwin/flutter_blue_plus_darwin.dart' as flutter_blue_plus_darwin;
import 'package:geolocator_apple/geolocator_apple.dart' as geolocator_apple;
import 'package:path_provider_foundation/path_provider_foundation.dart' as path_provider_foundation;
import 'package:shared_preferences_foundation/shared_preferences_foundation.dart' as shared_preferences_foundation;
import 'package:wakelock_plus/wakelock_plus.dart' as wakelock_plus;
import 'package:package_info_plus/package_info_plus.dart' as package_info_plus;
import 'package:path_provider_windows/path_provider_windows.dart' as path_provider_windows;
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:shared_preferences_windows/shared_preferences_windows.dart' as shared_preferences_windows;
import 'package:url_launcher_windows/url_launcher_windows.dart' as url_launcher_windows;
import 'package:wakelock_plus/wakelock_plus.dart' as wakelock_plus;

@pragma('vm:entry-point')
class _PluginRegistrant {

  @pragma('vm:entry-point')
  static void register() {
    if (Platform.isAndroid) {
      try {
        flutter_blue_plus_android.FlutterBluePlusAndroid.registerWith();
      } catch (err) {
        print(
          '`flutter_blue_plus_android` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        geolocator_android.GeolocatorAndroid.registerWith();
      } catch (err) {
        print(
          '`geolocator_android` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        path_provider_android.PathProviderAndroid.registerWith();
      } catch (err) {
        print(
          '`path_provider_android` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        shared_preferences_android.SharedPreferencesAndroid.registerWith();
      } catch (err) {
        print(
          '`shared_preferences_android` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

    } else if (Platform.isIOS) {
      try {
        flutter_blue_plus_darwin.FlutterBluePlusDarwin.registerWith();
      } catch (err) {
        print(
          '`flutter_blue_plus_darwin` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        geolocator_apple.GeolocatorApple.registerWith();
      } catch (err) {
        print(
          '`geolocator_apple` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        path_provider_foundation.PathProviderFoundation.registerWith();
      } catch (err) {
        print(
          '`path_provider_foundation` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        shared_preferences_foundation.SharedPreferencesFoundation.registerWith();
      } catch (err) {
        print(
          '`shared_preferences_foundation` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

    } else if (Platform.isLinux) {
      try {
        connectivity_plus.ConnectivityPlusLinuxPlugin.registerWith();
      } catch (err) {
        print(
          '`connectivity_plus` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        flutter_blue_plus_linux.FlutterBluePlusLinux.registerWith();
      } catch (err) {
        print(
          '`flutter_blue_plus_linux` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        package_info_plus.PackageInfoPlusLinuxPlugin.registerWith();
      } catch (err) {
        print(
          '`package_info_plus` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        path_provider_linux.PathProviderLinux.registerWith();
      } catch (err) {
        print(
          '`path_provider_linux` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        share_plus.SharePlusLinuxPlugin.registerWith();
      } catch (err) {
        print(
          '`share_plus` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        shared_preferences_linux.SharedPreferencesLinux.registerWith();
      } catch (err) {
        print(
          '`shared_preferences_linux` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        url_launcher_linux.UrlLauncherLinux.registerWith();
      } catch (err) {
        print(
          '`url_launcher_linux` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        wakelock_plus.WakelockPlusLinuxPlugin.registerWith();
      } catch (err) {
        print(
          '`wakelock_plus` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

    } else if (Platform.isMacOS) {
      try {
        flutter_blue_plus_darwin.FlutterBluePlusDarwin.registerWith();
      } catch (err) {
        print(
          '`flutter_blue_plus_darwin` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        geolocator_apple.GeolocatorApple.registerWith();
      } catch (err) {
        print(
          '`geolocator_apple` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        path_provider_foundation.PathProviderFoundation.registerWith();
      } catch (err) {
        print(
          '`path_provider_foundation` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        shared_preferences_foundation.SharedPreferencesFoundation.registerWith();
      } catch (err) {
        print(
          '`shared_preferences_foundation` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        wakelock_plus.WakelockPlusMacOSPlugin.registerWith();
      } catch (err) {
        print(
          '`wakelock_plus` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

    } else if (Platform.isWindows) {
      try {
        package_info_plus.PackageInfoPlusWindowsPlugin.registerWith();
      } catch (err) {
        print(
          '`package_info_plus` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        path_provider_windows.PathProviderWindows.registerWith();
      } catch (err) {
        print(
          '`path_provider_windows` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        share_plus.SharePlusWindowsPlugin.registerWith();
      } catch (err) {
        print(
          '`share_plus` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        shared_preferences_windows.SharedPreferencesWindows.registerWith();
      } catch (err) {
        print(
          '`shared_preferences_windows` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        url_launcher_windows.UrlLauncherWindows.registerWith();
      } catch (err) {
        print(
          '`url_launcher_windows` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        wakelock_plus.WakelockPlusWindowsPlugin.registerWith();
      } catch (err) {
        print(
          '`wakelock_plus` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

    }
  }
}
