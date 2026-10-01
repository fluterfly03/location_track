import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:task1/models/distance_response.dart';
import 'package:task1/services/distance_api_service.dart';
import 'package:task1/services/distance_repository.dart';
import 'package:task1/providers/distance_provider.dart';

void main() {
  group('Task 2: DistanceResponse Model Tests', () {
    test('1. Valid distance response parsing ({ "distance": 18.4 })', () {
      final json = {'distance': 18.4};
      final response = DistanceResponse.fromJson(json);

      expect(response.hasDistanceField, isTrue);
      expect(response.isPresent, isTrue);
      expect(response.isValid, isTrue);
      expect(response.validDistance, 18.4);
      expect(response.rawDistance, 18.4);
    });

    test('2. Null distance response parsing ({ "distance": null }) - NEVER fallback to 0.88', () {
      final json = {'distance': null};
      final response = DistanceResponse.fromJson(json);

      expect(response.hasDistanceField, isTrue);
      expect(response.isPresent, isFalse);
      expect(response.isValid, isFalse);
      expect(response.validDistance, isNull);
      // Assert that no hard-coded fake value like 0.88 is returned
      expect(response.validDistance, isNot(0.88));
    });

    test('3. Missing distance field ({}) - NEVER fallback to 0.88', () {
      final json = <String, dynamic>{};
      final response = DistanceResponse.fromJson(json);

      expect(response.hasDistanceField, isFalse);
      expect(response.isPresent, isFalse);
      expect(response.isValid, isFalse);
      expect(response.validDistance, isNull);
      expect(response.validDistance, isNot(0.88));
    });

    test('4. Negative/invalid distance parsing ({ "distance": -5.0 }) - Rejected as invalid', () {
      final json = {'distance': -5.0};
      final response = DistanceResponse.fromJson(json);

      expect(response.hasDistanceField, isTrue);
      expect(response.isPresent, isTrue);
      expect(response.isValid, isFalse);
      expect(response.validDistance, isNull);
      expect(response.validDistance, isNot(-5.0));
      expect(response.validDistance, isNot(0.88));
    });
  });

  group('Task 2: DistanceRepository & API Error Handling Tests', () {
    test('5. Handles API/Server Error 500', () async {
      final mockApi = MockDistanceApiService(activeScenario: DistanceApiScenario.serverError);
      final repo = DistanceRepository(apiService: mockApi);

      expect(
        () async => await repo.getDistance(),
        throwsA(isA<DistanceRepositoryException>().having(
          (e) => e.errorType,
          'errorType',
          'ServerError',
        )),
      );
    });

    test('6. Handles Request Timeout', () async {
      final mockApi = MockDistanceApiService(activeScenario: DistanceApiScenario.requestTimeout);
      final repo = DistanceRepository(apiService: mockApi);

      try {
        await repo.getDistance();
        fail('Expected DistanceRepositoryException');
      } on DistanceRepositoryException catch (e) {
        expect(e.errorType, 'TimeoutError');
        expect(e.message, 'Unable to retrieve distance. Please try again.');
      }
    });

    test('7. Handles Network Error (SocketException)', () async {
      final mockApi = MockDistanceApiService(activeScenario: DistanceApiScenario.networkError);
      final repo = DistanceRepository(apiService: mockApi);

      try {
        await repo.getDistance();
        fail('Expected DistanceRepositoryException');
      } on DistanceRepositoryException catch (e) {
        expect(e.errorType, 'NetworkError');
        expect(e.message, contains('Network connection unavailable'));
      }
    });
  });

  group('Task 2: DistanceProvider & Retry State Tests', () {
    test('8. Retry Success: Fails initially on network error, then succeeds on retry', () async {
      final mockApi = MockDistanceApiService(activeScenario: DistanceApiScenario.networkError);
      final provider = DistanceProvider(
        repository: DistanceRepository(apiService: mockApi),
        initialScenario: DistanceApiScenario.networkError,
      );

      // Wait for initial fetch
      await Future.delayed(const Duration(milliseconds: 400));
      expect(provider.isError, isTrue);
      expect(provider.distanceKm, isNull);

      // Set next retry to succeed
      mockApi.setNextRetrySuccess(true);
      await provider.fetchDistanceWithService(mockApi);

      expect(provider.isSuccess, isTrue);
      expect(provider.distanceKm, 18.4);
      expect(provider.formattedDistance, '18.4 km');
    });

    test('9. Retry Failure: Fails initially on server error, retry fails again', () async {
      final mockApi = MockDistanceApiService(activeScenario: DistanceApiScenario.serverError);
      final provider = DistanceProvider(
        repository: DistanceRepository(apiService: mockApi),
        initialScenario: DistanceApiScenario.serverError,
      );

      // Wait for initial fetch
      await Future.delayed(const Duration(milliseconds: 400));
      expect(provider.isError, isTrue);

      // Retry again with server error
      await provider.fetchDistanceWithService(mockApi);

      expect(provider.isError, isTrue);
      expect(provider.distanceKm, isNull);
      expect(provider.errorMessage, isNotNull);
    });
  });
}
