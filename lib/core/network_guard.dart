import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NetworkBlockedException implements Exception {
  const NetworkBlockedException();
  @override
  String toString() => 'Internet access is blocked in Shafiq mode settings.';
}

/// Single choke point for ALL network traffic made by the app.
/// When [blocked] is true no request leaves the device.
class NetworkGuard extends ChangeNotifier {
  bool _blocked = false;
  bool get blocked => _blocked;
  set blocked(bool v) {
    if (v == _blocked) return;
    _blocked = v;
    notifyListeners();
  }

  http.Client createClient() => _GuardedClient(this);
}

class _GuardedClient extends http.BaseClient {
  _GuardedClient(this._guard) : _inner = http.Client();
  final NetworkGuard _guard;
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (_guard.blocked) throw const NetworkBlockedException();
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}
