import 'package:dio/dio.dart';

String handleApiError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Koneksi ke server timeout. Silakan periksa jaringan Anda.';
      
    case DioExceptionType.connectionError:
      return 'Anda sedang offline. Periksa koneksi internet Anda.';
      
    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) {
        return 'Sesi Anda telah berakhir atau kredensial tidak valid. Silakan login ulang.';
      } else if (statusCode == 403) {
        return 'Anda tidak memiliki akses ke sumber daya ini.';
      } else if (statusCode == 404) {
        return 'Data atau layanan yang diminta tidak ditemukan.';
      } else if (statusCode != null && statusCode >= 500) {
        return 'Terjadi gangguan pada server. Silakan coba beberapa saat lagi.';
      }
      return error.response?.data['message'] ?? 'Terjadi kesalahan pada server.';
      
    case DioExceptionType.cancel:
      return 'Permintaan ke server dibatalkan.';
      
    default:
      return 'Terjadi kesalahan tak terduga. Periksa koneksi Anda.';
  }
}