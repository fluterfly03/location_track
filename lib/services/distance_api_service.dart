import 'dart:async';
import 'dart:io';

enum DistanceApiScenario {
  validDistance,      // { "distance": 18.4 }
  nullDistance,       // { "distance": null }
  missingField,       // {}
  invalidNegative,    // { "distance": -5.0 }
  serverError,        // Throws HTTP 500 Server Error
  networkError,       // Throws SocketException
  requestTimeout,     // Throws TimeoutException
}

extension DistanceApiScenarioExtension on DistanceApiScenario {
  String get label {
    switch (this) {
      case DistanceApiScenario.validDistance:
        return 'Valid Distance (18.4 km)';
      case DistanceApiScenario.nullDistance:
        return 'Null Distance ({ distance: null })';
      case DistanceApiScenario.missingField:
        return 'Missing Field ({})';
      case DistanceApiScenario.invalidNegative:
        return 'Invalid Negative ({ distance: -5 })';
      case DistanceApiScenario.serverError:
        return 'Server Error (500 Internal Error)';
      case DistanceApiScenario.networkError:
        return 'Network Error (SocketException)';
      case DistanceApiScenario.requestTimeout:
        return 'Request Timeout (TimeoutException)';
    }
  }
}

/// Abstract Contract for Distance API Service.
/// Allows seamless replacement of Mock API with a real HTTP endpoint in production.
abstract class DistanceApiService {
  Future<Map<String, dynamic>> fetchDistanceData();
}

/// Mock Implementation simulating all required API response and error states.
class MockDistanceApiService implements DistanceApiService {
  DistanceApiScenario activeScenario;
  bool _shouldSucceedOnNextRetry = false;

  MockDistanceApiService({
    this.activeScenario = DistanceApiScenario.validDistance,
  });

  /// Allows toggling retry behavior for testing retry success/failure
  void setNextRetrySuccess(bool succeed) {
    _shouldSucceedOnNextRetry = succeed;
  }

  @override
  Future<Map<String, dynamic>> fetchDistanceData() async {
    // Artificial API network latency
    await Future.delayed(const Duration(milliseconds: 300));

    if (_shouldSucceedOnNextRetry) {
      _shouldSucceedOnNextRetry = false;
      return {'distance': 18.4};
    }

    switch (activeScenario) {
      case DistanceApiScenario.validDistance:
        return {'distance': 18.4};

      case DistanceApiScenario.nullDistance:
        return {'distance': null};

      case DistanceApiScenario.missingField:
        return <String, dynamic>{};

      case DistanceApiScenario.invalidNegative:
        return {'distance': -5.0};

      case DistanceApiScenario.serverError:
        throw const HttpException('HTTP 500 Internal Server Error');

      case DistanceApiScenario.networkError:
        throw const SocketException('Network connection failed. Device is offline.');

      case DistanceApiScenario.requestTimeout:
        throw TimeoutException('Request timed out after 15 seconds.');
    }
  }
}
