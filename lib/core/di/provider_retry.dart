/// Provider が失敗したときに自動で再試行しない（Riverpod 3 は既定で再試行する）。
///
/// 失敗は Notifier の `result.fold` で扱い、初回読み込みの失敗はエラー画面を出す方針のため、
/// 裏で再試行させない。アプリの `ProviderScope` とテストの `ProviderContainer` の `retry:` に渡す。
Duration? noRetry(int retryCount, Object error) => null;
