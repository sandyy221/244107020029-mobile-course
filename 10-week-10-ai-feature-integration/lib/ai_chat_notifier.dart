import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai/ai_service.dart';

/// Provider singleton untuk instance [AiService].
final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

/// State untuk percakapan chat AI.
class AiChatState {
  const AiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.hasApiKey = false,
    this.errorMessage,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final bool hasApiKey;
  final String? errorMessage;

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? hasApiKey,
    String? errorMessage,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      hasApiKey: hasApiKey ?? this.hasApiKey,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier pengelola state interaksi chat AI.
class AiChatNotifier extends Notifier<AiChatState> {
  late final AiService _aiService;

  @override
  AiChatState build() {
    _aiService = ref.watch(aiServiceProvider);
    _checkApiKeyStatus();

    // Pesan sapaan awal dari AI
    final initialGreeting = ChatMessage(
      text:
          'Halo! Saya Asisten AI Catatan Anda 🤖.\n'
          'Tanyakan apa saja seputar ide catatan, rangkuman tugas, atau tips belajar mobile!',
      isUser: false,
      timestamp: DateTime.now(),
    );

    return AiChatState(messages: [initialGreeting]);
  }

  Future<void> _checkApiKeyStatus() async {
    final key = await _aiService.getApiKey();
    state = state.copyWith(hasApiKey: key != null && key.isNotEmpty);
  }

  /// Mengirim pertanyaan pengguna ke AI Service (dengan auto-fallback).
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isLoading) return;

    final userMessage = ChatMessage(
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // Tambahkan pesan pengguna ke state dan aktifkan loading
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      errorMessage: null,
    );

    try {
      final aiResponse = await _aiService.askWithFallback(trimmed);
      state = state.copyWith(
        messages: [...state.messages, aiResponse],
        isLoading: false,
      );
    } catch (e) {
      final errorResponse = ChatMessage(
        text:
            'Terjadi kesalahan sistem: $e. Coba gunakan pertanyaan lain atau periksa koneksi internet Anda.',
        isUser: false,
        timestamp: DateTime.now(),
        isOfflineFallback: true,
      );
      state = state.copyWith(
        messages: [...state.messages, errorResponse],
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Menyimpan API Key baru ke Secure Storage.
  Future<void> updateApiKey(String key) async {
    await _aiService.saveApiKey(key);
    await _checkApiKeyStatus();
  }

  /// Menghapus API Key.
  Future<void> clearApiKey() async {
    await _aiService.deleteApiKey();
    await _checkApiKeyStatus();
  }

  /// Mereset riwayat percakapan.
  void clearMessages() {
    final resetGreeting = ChatMessage(
      text: 'Riwayat percakapan telah dibersihkan. Ada yang bisa saya bantu kembali? 💡',
      isUser: false,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: [resetGreeting]);
  }
}

final aiChatProvider = NotifierProvider<AiChatNotifier, AiChatState>(
  AiChatNotifier.new,
);
