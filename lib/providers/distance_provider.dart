import 'package:flutter/foundation.dart';
import '../models/distance_response.dart';
import '../services/distance_api_service.dart';
import '../services/distance_repository.dart';

enum DistanceStatus {
  initial,
  loading,
  success,
  unavailable,
  error,
}

class DistanceProvider extends ChangeNotifier {
  final DistanceRepository _repository;

  DistanceStatus _status = DistanceStatus.initial;
  double? _distanceKm;
  String? _errorMessage;
  DistanceResponse? _lastResponse;

  DistanceStatus get status => _status;
  double? get distanceKm => _distanceKm;
  String? get errorMessage => _errorMessage;
  DistanceResponse? get lastResponse => _lastResponse;

  bool get isLoading => _status == DistanceStatus.loading;
  bool get isSuccess => _status == DistanceStatus.success;
  bool get isUnavailable => _status == DistanceStatus.unavailable;
  bool get isError => _status == DistanceStatus.error;

  String get formattedDistance =>
      _distanceKm != null ? '${_distanceKm!.toStringAsFixed(1)} km' : 'Distance unavailable';

  DistanceApiScenario _activeScenario = DistanceApiScenario.validDistance;
  DistanceApiScenario get activeScenario => _activeScenario;

  DistanceProvider({
    DistanceRepository? repository,
    DistanceApiScenario? initialScenario,
    bool autoFetch = true,
  })  : _repository = repository ?? DistanceRepository(),
        _activeScenario = initialScenario ?? DistanceApiScenario.validDistance {
    if (autoFetch) {
      fetchDistance();
    }
  }

  /// Change mock scenario for interactive demonstration and testing
  void setScenario(DistanceApiScenario scenario) {
    _activeScenario = scenario;
    final apiService = MockDistanceApiService(activeScenario: scenario);
    // Fetch using new scenario
    fetchDistanceWithService(apiService);
  }

  Future<void> fetchDistance() async {
    final apiService = MockDistanceApiService(activeScenario: _activeScenario);
    await fetchDistanceWithService(apiService);
  }

  Future<void> fetchDistanceWithService(DistanceApiService apiService) async {
    _status = DistanceStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final repo = DistanceRepository(apiService: apiService);
      final response = await repo.getDistance();
      _lastResponse = response;

      if (response.isValid) {
        // Valid positive number
        _status = DistanceStatus.success;
        _distanceKm = response.validDistance;
        _errorMessage = null;
      } else {
        // Null, missing field, or negative/invalid data
        // ABSOLUTELY NO FAKE FALLBACK DISTANCE VALUE (e.g. 0.88) IS APPLIED HERE.
        _status = DistanceStatus.unavailable;
        _distanceKm = null;
        if (!response.hasDistanceField) {
          _errorMessage = 'Distance field is missing from response payload.';
        } else if (!response.isPresent) {
          _errorMessage = 'Distance value is unavailable (null).';
        } else {
          _errorMessage = 'Invalid distance value (${response.rawDistance}).';
        }
      }
    } on DistanceRepositoryException catch (e) {
      _status = DistanceStatus.error;
      _distanceKm = null;
      _errorMessage = e.message;
    } catch (e) {
      _status = DistanceStatus.error;
      _distanceKm = null;
      _errorMessage = 'An unexpected error occurred.';
    }

    notifyListeners();
  }

  Future<void> retry() async {
    await fetchDistance();
  }
}
