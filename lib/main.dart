import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:word_pods/app.dart';
import 'package:word_pods/core/firebase/options/firebase_options_dev.dart'
    as dev;
import 'package:word_pods/core/firebase/options/firebase_options_prod.dart'
    as prod;

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp(
    options: _firebaseOptions(),
  );

  // Firebase へのアクセスに「本物のアプリから来た」証明を付ける（App Check）。
  // デバッグビルドは端末の証明を取れないため、Firebase コンソールに登録したデバッグ用トークンを使う。
  await FirebaseAppCheck.instance.activate(
    androidProvider:
        kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode
        ? AppleProvider.debug
        : AppleProvider.appAttestWithDeviceCheckFallback,
  );

  FlutterNativeSplash.remove();

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}

/// `--flavor prod` でビルドしたときだけ本番の Firebase に接続する。
/// それ以外（`dev`・フレーバー未指定）は開発の Firebase に接続し、
/// 指定漏れで本番のデータを触らないようにする。
FirebaseOptions _firebaseOptions() => switch (appFlavor) {
      'prod' => prod.DefaultFirebaseOptions.currentPlatform,
      _ => dev.DefaultFirebaseOptions.currentPlatform,
    };
