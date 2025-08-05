import 'package:connectivity_plus/connectivity_plus.dart';

extension NetworkExtension on List<ConnectivityResult> {
  bool get isConnected =>
      contains(ConnectivityResult.wifi) ||
      contains(ConnectivityResult.ethernet) ||
      contains(ConnectivityResult.mobile);
}
