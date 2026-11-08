// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reporting_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// クラッシュ・非致命的エラーの報告口。Mock モードでは何もしない実装を渡す。
/// Firebase が初期化されていない場合（Widget テストでアプリ全体を組み立てた場合など）も、
/// 報告のためにアプリを止めないよう、何もしない実装を渡す。

@ProviderFor(crashReporter)
final crashReporterProvider = CrashReporterProvider._();

/// クラッシュ・非致命的エラーの報告口。Mock モードでは何もしない実装を渡す。
/// Firebase が初期化されていない場合（Widget テストでアプリ全体を組み立てた場合など）も、
/// 報告のためにアプリを止めないよう、何もしない実装を渡す。

final class CrashReporterProvider
    extends $FunctionalProvider<CrashReporter, CrashReporter, CrashReporter>
    with $Provider<CrashReporter> {
  /// クラッシュ・非致命的エラーの報告口。Mock モードでは何もしない実装を渡す。
  /// Firebase が初期化されていない場合（Widget テストでアプリ全体を組み立てた場合など）も、
  /// 報告のためにアプリを止めないよう、何もしない実装を渡す。
  CrashReporterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'crashReporterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$crashReporterHash();

  @$internal
  @override
  $ProviderElement<CrashReporter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CrashReporter create(Ref ref) {
    return crashReporter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CrashReporter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CrashReporter>(value),
    );
  }
}

String _$crashReporterHash() => r'acfcd9f23129b942e4653642035cccde3d4af045';

/// 利用状況の記録口。Mock モード・Firebase が初期化されていない場合は何もしない実装を渡す。

@ProviderFor(analyticsReporter)
final analyticsReporterProvider = AnalyticsReporterProvider._();

/// 利用状況の記録口。Mock モード・Firebase が初期化されていない場合は何もしない実装を渡す。

final class AnalyticsReporterProvider
    extends
        $FunctionalProvider<
          AnalyticsReporter,
          AnalyticsReporter,
          AnalyticsReporter
        >
    with $Provider<AnalyticsReporter> {
  /// 利用状況の記録口。Mock モード・Firebase が初期化されていない場合は何もしない実装を渡す。
  AnalyticsReporterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyticsReporterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyticsReporterHash();

  @$internal
  @override
  $ProviderElement<AnalyticsReporter> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AnalyticsReporter create(Ref ref) {
    return analyticsReporter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnalyticsReporter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnalyticsReporter>(value),
    );
  }
}

String _$analyticsReporterHash() => r'c972f92bfc8f30901f3e3c5fa71d68100b03cbc1';
