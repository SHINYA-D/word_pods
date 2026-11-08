import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:word_pods/app.dart';
import 'package:word_pods/core/di/provider_retry.dart';
import 'package:word_pods/core/di/reporting_providers.dart';
import 'package:word_pods/core/di/repository_providers.dart';
import 'package:word_pods/core/utils/crash_reporting.dart';
import 'package:word_pods/core/firebase/options/firebase_options_dev.dart'
    as dev;
import 'package:word_pods/core/firebase/options/firebase_options_prod.dart'
    as prod;

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // スマートフォンは縦向きだけ（横向きのレイアウトを用意していないため）。iPad は横向きも許可する
  // （Info.plist で iPhone は縦向きだけ・iPad は全方向、AndroidManifest.xml で縦向きに固定している）。
  // 画面の短い辺が 600 未満をスマートフォンとみなす（Material Design のタブレットの目安）
  final view = widgetsBinding.platformDispatcher.views.first;
  final shortestSide = view.physicalSize.shortestSide / view.devicePixelRatio;
  if (shortestSide < 600) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  await Firebase.initializeApp(
    options: _firebaseOptions(),
  );

  // Firebase へのアクセスに「本物のアプリから来た」証明を付ける（App Check）。
  // デバッグビルドは端末の証明を取れないため、Firebase コンソールに登録したデバッグ用トークンを使う。
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode ? const AndroidDebugProvider() : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode ? const AppleDebugProvider() : const AppleAppAttestWithDeviceCheckFallbackProvider(),
  );

  // Google ログインは、ログイン・再認証の前に1回だけ初期化しておく必要がある（google_sign_in 7 から）。
  // クライアント ID は google-services.json / GoogleService-Info.plist から読まれる
  await GoogleSignIn.instance.initialize();

  // 報告口を Provider から取り出して、アプリより先にクラッシュの収集を始めるため、
  // ProviderScope ではなく自分で作った ProviderContainer をアプリに渡す
  final container = ProviderContainer(retry: noRetry);

  // クラッシュ・利用状況の収集（docs/high_level_design/crash_reporting.md）。
  // デバッグビルドと Mock モードでは集めず、エラーは今までどおりコンソールに出す
  initCrashReporting(
    isDebug: kDebugMode,
    useMocks: kUseMocks,
    reporter: container.read(crashReporterProvider),
    analytics: container.read(analyticsReporterProvider),
  );

  FlutterNativeSplash.remove();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const App(),
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
