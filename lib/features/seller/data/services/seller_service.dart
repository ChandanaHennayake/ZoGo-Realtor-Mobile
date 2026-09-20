import 'package:dio/dio.dart';
import 'package:zogo_realtor/core/storage/secure_storage_service.dart';

class SellerService {
  SellerService(this._dio, this._secureStorage);

  final Dio _dio;
  final SecureStorageService _secureStorage;

 Future<bool> activateSeller() async {
  print('========== SELLER ACTIVATION START ==========');

  try {
    final accessToken =
        await _secureStorage.getAccessToken();

    print('TOKEN EXISTS: ${accessToken != null}');
    print('TOKEN LENGTH: ${accessToken?.length ?? 0}');
    print('BASE URL: ${_dio.options.baseUrl}');

    if (accessToken == null || accessToken.isEmpty) {
      print('ERROR: NO ACCESS TOKEN');
      throw Exception('Authentication token not found.');
    }

    final url = '/api/v1/seller/activate';

    print('CALLING: ${_dio.options.baseUrl}$url');

    final response = await _dio.post(
      url,
      options: Options(
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      ),
    );

    print('STATUS CODE: ${response.statusCode}');
    print('RESPONSE: ${response.data}');
    print('========== SELLER ACTIVATION SUCCESS ==========');

    return response.statusCode == 200;
  } on DioException catch (e) {
    print('========== SELLER ACTIVATION ERROR ==========');
    print('MESSAGE: ${e.message}');
    print('STATUS: ${e.response?.statusCode}');
    print('DATA: ${e.response?.data}');
    print('TYPE: ${e.type}');
    print('==============================================');

    throw Exception(
      e.response?.data?['message'] ??
          e.response?.data?['title'] ??
          'Seller activation failed',
    );
  } catch (e) {
    print('SELLER UNKNOWN ERROR: $e');
    throw Exception(e.toString());
  }
}
}
