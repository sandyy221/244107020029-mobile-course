import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_service.dart';
import '../presentation/ai_chat_notifier.dart';

/// Halaman antarmuka obrolan cerdas berbasis AI (Week 10 AI Feature Integration).
class AiChatPage extends ConsumerStatefulWidget {
  const AiChatPage({super.key});

  @override
  ConsumerState<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends ConsumerState<AiChatPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  final List<String> _quickSuggestions = [
    'Ringkas catatanku',
    'Ide judul catatan produktif',
    'Tips belajar Flutter',
    'Jadwal kuliah kampus',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? prefilled]) {
    final text = prefilled ?? _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    ref.read(aiChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _showApiKeyDialog(BuildContext context, bool hasApiKey) {
    final keyController = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.key, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text('Pengaturan API Key'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kunci API disimpan secara aman di perangkat menggunakan flutter_secure_storage '
                'dan tidak pernah dikirim ke pihak selain Google Gemini API.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: keyController,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Google Gemini API Key',
                  hintText: 'AIzaSy...',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        obscure = !obscure;
                      });
                    },
                  ),
                ),
              ),
              if (hasApiKey) ...[
                const SizedBox(height: 12),
                const Text(
                  '✓ Kunci API saat ini sudah tersimpan.',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            if (hasApiKey)
              TextButton(
                onPressed: () async {
                  await ref.read(aiChatProvider.notifier).clearApiKey();
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('API Key berhasil dihapus.'),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Hapus Kunci',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final key = keyController.text.trim();
                if (key.isNotEmpty) {
                  await ref.read(aiChatProvider.notifier).updateApiKey(key);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'API Key berhasil disimpan di Secure Storage!',
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);

    // Auto-scroll saat pesan baru masuk
    ref.listen(aiChatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length ||
          previous?.isLoading != next.isLoading) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber),
            const SizedBox(width: 8),
            const Text('Asisten AI Catatan'),
          ],
        ),
        actions: [
          // Status mode AI (Cloud vs Fallback)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Chip(
              avatar: Icon(
                chatState.hasApiKey ? Icons.cloud_done : Icons.cloud_off,
                size: 14,
                color: chatState.hasApiKey ? Colors.green : Colors.orange,
              ),
              label: Text(
                chatState.hasApiKey ? 'Gemini AI' : 'Offline Mode',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
          // Tombol pengaturan API Key
          IconButton(
            icon: const Icon(Icons.key),
            tooltip: 'Pengaturan API Key',
            onPressed: () => _showApiKeyDialog(context, chatState.hasApiKey),
          ),
          // Tombol bersihkan chat
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Bersihkan Obrolan',
            onPressed: () {
              ref.read(aiChatProvider.notifier).clearMessages();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner edukasi privasi & fallback jika API key belum diisi
          if (!chatState.hasApiKey)
            Container(
              width: double.infinity,
              color: Colors.amber.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mode Offline aktif. Respons dihasilkan oleh mesin fallback lokal. '
                      'Tambahkan Gemini API Key pada ikon kunci di atas untuk menghubungkan ke cloud LLM.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.brown.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Daftar Pesan Chat
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                final message = chatState.messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Indikator Loading / AI Sedang Mengetik
          if (chatState.isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Asisten AI sedang berpikir...',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

          // Suggestion Chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: _quickSuggestions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final suggestion = _quickSuggestions[index];
                return ActionChip(
                  label: Text(suggestion, style: const TextStyle(fontSize: 12)),
                  onPressed: chatState.isLoading
                      ? null
                      : () => _sendMessage(suggestion),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Input Bar Bawah
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Tanyakan sesuatu ke Asisten AI...',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: chatState.isLoading
                          ? null
                          : () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final theme = Theme.of(context);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : (message.isOfflineFallback
                    ? Colors.amber.shade50
                    : theme.colorScheme.surfaceContainerHighest),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: message.isOfflineFallback
              ? Border.all(color: Colors.amber.shade300)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUser ? Icons.person : Icons.smart_toy_outlined,
                  size: 14,
                  color: isUser
                      ? Colors.white70
                      : (message.isOfflineFallback
                            ? Colors.brown
                            : theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 4),
                Text(
                  isUser
                      ? 'Anda'
                      : (message.isOfflineFallback
                            ? 'AI (Offline)'
                            : 'AI Asisten'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isUser
                        ? Colors.white70
                        : (message.isOfflineFallback
                              ? Colors.brown
                              : theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message.text,
              style: TextStyle(
                fontSize: 14,
                color: isUser
                    ? Colors.white
                    : (message.isOfflineFallback
                          ? Colors.brown.shade900
                          : theme.colorScheme.onSurfaceVariant),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
