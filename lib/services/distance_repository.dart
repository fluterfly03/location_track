import 'dart:async';
import 'dart:io';
import '../models/distance_response.dart';
import 'distance_api_service.dart';
import 'logger_service.dart';

class DistanceRepositoryException implements Exception {
  final String message;
  final String errorType;
  final Object? originalException;

  DistanceRepositoryException({
    required this.message,
    required this.errorType,
    this.originalException,
  });

  @override
  String toString() => 'DistanceRepositoryException[$errorType]: $message';
}

class DistanceRepository {
  final DistanceApiService _apiService;

  DistanceRepository({DistanceApiService? apiService})
      : _apiService = apiService ?? MockDistanceApiService();

  Future<DistanceResponse> getDistance() async {
    LoggerService.info('FetchDistance', 'Initiating distance fetch request to API');

    try {
      final json = await _apiService.fetchDistanceData();
      final response = DistanceResponse.fromJson(json);

      if (!response.hasDistanceField) {
        LoggerService.warning('FetchDistance', 'Missing distance field in response payload');
      } else if (!response.isPresent) {
        LoggerService.warning('FetchDistance', 'Distance field is explicitly null');
      } else if (!response.isValid) {
        LoggerService.warning('FetchDistance', 'Distance value is negative or invalid: ${response.rawDistance}');
      } else {
        LoggerService.info('FetchDistance', 'Successfully fetched valid distance: ${response.validDistance} km');
      }

      return response;
    } on TimeoutException catch (e, st) {
      LoggerService.error('FetchDistance', 'Request timed out', e, st);
      throw DistanceRepositoryException(
        message: 'Unable to retrieve distance. Please try again.',
        errorType: 'TimeoutError',
        originalException: e,
      );
    } on SocketException catch (e, st) {
      LoggerService.error('FetchDistance', 'Network connectivity failure', e, st);
      throw DistanceRepositoryException(
        message: 'Network connection unavailable. Please check your internet connection.',
        errorType: 'NetworkError',
        originalException: e,
      );
    } on HttpException catch (e, st) {
      LoggerService.error('FetchDistance', 'Server API returned error status', e, st);
      throw DistanceRepositoryException(
        message: 'Server error encountered while retrieving distance.',
        errorType: 'ServerError',
        originalException: e,
      );
    } catch (e, st) {
      LoggerService.error('FetchDistance', 'Unexpected API error', e, st);
      throw DistanceRepositoryException(
        message: 'An unexpected error occurred while fetching distance.',
        errorType: 'UnknownError',
        originalException: e,
      );
    }
  }
}
