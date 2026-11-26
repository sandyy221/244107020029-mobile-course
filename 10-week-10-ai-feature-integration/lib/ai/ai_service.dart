import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Model data pesan obrolan antara pengguna dan Asisten AI.
class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isOfflineFallback = false,
  });

  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isOfflineFallback;

  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isOfflineFallback,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isOfflineFallback: isOfflineFallback ?? this.isOfflineFallback,
    );
  }
}

/// Service untuk menghubungkan aplikasi Flutter dengan Gemini LLM API
/// dan menangani secure storage, privasi data, dan offline fallback.
class AiService {
  AiService({http.Client? client, FlutterSecureStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  final http.Client _client;
  final FlutterSecureStorage _storage;

  static const String _storageKey = 'ai_api_key';
  static const String _defaultApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  /// System prompt untuk menetapkan persona, bahasa, dan batas keamanan privasi.
  static const String systemInstruction =
      'Kamu adalah Asisten Cerdas untuk aplikasi Catatan Offline. '
      'Tugasmu membantu pengguna merangkum catatan, memberikan ide judul produktif, '
      'dan tips belajar mobile. Jawab dalam Bahasa Indonesia secara ringkas, jelas, dan santun. '
      'Jangan pernah meminta atau menyebarkan data pribadi rahasia seperti NIK, nomor telepon, atau kata sandi.';

  /// Membaca API Key yang tersimpan di Secure Storage.
  Future<String?> getApiKey() async {
    try {
      return await _storage.read(key: _storageKey);
    } catch (_) {
      return null;
    }
  }

  /// Menyimpan API Key pengguna secara aman di Secure Storage.
  Future<void> saveApiKey(String key) async {
    await _storage.write(key: _storageKey, value: key.trim());
  }

  /// Menghapus API Key dari Secure Storage.
  Future<void> deleteApiKey() async {
    await _storage.delete(key: _storageKey);
  }

  /// Sanitasi input untuk melindungi privasi pengguna sebelum dikirim ke cloud AI.
  String sanitizePrompt(String input) {
    // Menyamarkan pola nomor telepon/NIK sederhana
    final sanitized = input.replaceAll(
      RegExp(r'\b08[0-9]{8,11}\b'),
      '[NOMOR_DISAMARKAN]',
    );
    return sanitized.trim();
  }

  /// Mengirim pertanyaan ke Google Gemini API secara langsung.
  Future<String> ask(String question) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'API key tidak tersedia. Silakan atur di menu Pengaturan AI.',
      );
    }

    final cleanPrompt = sanitizePrompt(question);
    final url = Uri.parse('$_defaultApiUrl?key=$apiKey');

    final payload = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': '$systemInstruction\n\nPertanyaan Pengguna: $cleanPrompt'},
          ],
        },
      ],
      'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 500},
    };

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;
        if (parts != null && parts.isNotEmpty) {
          final text = parts[0]['text'] as String?;
          if (text != null && text.isNotEmpty) {
            return text.trim();
          }
        }
      }
      return 'Maaf, AI tidak memberikan respons yang dapat dibaca.';
    } else {
      throw Exception(
        'Gagal memanggil AI API: HTTP ${response.statusCode} - ${response.reasonPhrase}',
      );
    }
  }

  /// Mengirim pertanyaan dengan mekanisme Fallback cerdas (Offline & Error Fallback).
  /// Menjamin aplikasi tidak crash jika offline, kuota habis, atau API key belum diset.
  Future<ChatMessage> askWithFallback(String question) async {
    try {
      final apiKey = await getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        // Fallback jika API Key belum diatur
        final localAnswer = _generateLocalFallback(question);
        return ChatMessage(
          text:
              '$localAnswer\n\n*(Catatan: Mode Offline aktif. Anda dapat menambahkan Gemini API Key pada ikon kunci di pojok kanan atas untuk kecerdasan penuh).*',
          isUser: false,
          timestamp: DateTime.now(),
          isOfflineFallback: true,
        );
      }

      final aiText = await ask(question);
      return ChatMessage(
        text: aiText,
        isUser: false,
        timestamp: DateTime.now(),
        isOfflineFallback: false,
      );
    } catch (e) {
      // Fallback ketika terjadi kesalahan jaringan / kuota habis
      final localAnswer = _generateLocalFallback(question);
      return ChatMessage(
        text:
            '$localAnswer\n\n*(Layanan AI cloud sedang tidak dapat dijangkau: $e. Jawaban ini dihasilkan oleh Fallback Engine lokal).*',
        isUser: false,
        timestamp: DateTime.now(),
        isOfflineFallback: true,
      );
    }
  }

  /// Engine pencocokan fallback lokal berbasis aturan untuk skenario offline.
  String _generateLocalFallback(String question) {
    final lower = question.toLowerCase();

    if (lower.contains('ringkas') || lower.contains('rangkum')) {
      return 'Untuk merangkum catatan: Buka catatan yang diinginkan, pilih poin-poin terpenting, lalu kelompokkan menggunakan bullet points agar mudah dipelajari kembali.';
    } else if (lower.contains('judul') || lower.contains('ide')) {
      return 'Saran format judul catatan produktif:\n1. [KULIAH] Nama Mata Kuliah - Topik Bahasan\n2. [TODO] Rencana Kerja Mingguan\n3. [IDE] Rencana Proyek Akhir';
    } else if (lower.contains('jadwal') || lower.contains('kuliah')) {
      return 'Fitur jadwal lokal: Pastikan Anda mencatat jam kuliah dan ruangan di catatan dengan label #jadwal agar mudah dicari melalui fitur Search.';
    } else if (lower.contains('tips') ||
        lower.contains('belajar') ||
        lower.contains('mobile')) {
      return 'Tips Belajar Pemrograman Mobile:\n- Pahami konsep dasar State Management (Riverpod).\n- Gunakan Clean Architecture untuk memisahkan UI, domain, dan database.\n- Tulis unit test untuk use case penting agar kode bebas bug.';
    } else {
      return 'Halo! Saya Asisten AI Catatan Anda. Saya dapat membantu memberikan ide catatan, tips belajar mobile, dan saran penataan tugas. Silakan tanyakan sesuatu!';
    }
  }
}
