import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityMonitor {
  final Connectivity _connectivity = Connectivity();

  /// 現在オンラインかどうかを即座に確認
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _isOnline(results);
  }

  /// ネットワーク状態の変化を監視
  Stream<bool> onStatusChanged() {
    return _connectivity.onConnectivityChanged.map(_isOnline);
  }

  /// Wi-Fi とモバイル回線のように複数つながっていることがあるため、どれか1つでもつながっていればオンライン
  bool _isOnline(List<ConnectivityResult> results) => results.any((r) => r != ConnectivityResult.none);
}
