import 'package:connectivity_plus/connectivity_plus.dart';

extension NetworkExtension on List<ConnectivityResult> {
  bool get isConnected => any(
    (result) =>
        result != ConnectivityResult.none &&
        result != ConnectivityResult.bluetooth &&
        result != ConnectivityResult.ethernet,
  );
}
