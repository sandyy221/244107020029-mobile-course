# AI Feature Integration Log (`docs/ai-log.md`)

**Mata Kuliah:** Pemrograman Mobile  
**Topik:** #10 | Integrasi Fitur AI (LLM API, Secure Storage, Prompt Design, & Fallback Architecture)  
**Proyek Basis:** `week5_offline_notes` (Offline Notes dengan Riverpod & SQLite)  
**Fitur AI yang Diintegrasikan:** Chat Asisten AI Catatan (*AI Note Assistant*) dengan Google Gemini LLM API, Secure Storage, Sanitasi Privasi, dan Offline Fallback Engine.

---

## 1. Perancangan Prompt (System Prompt, User Prompt, & Konteks)

### 1.1. System Prompt
System prompt dirancang untuk menetapkan persona, bahasa pengantar, batasan panjang jawaban, dan perlindungan privasi:

```text
Kamu adalah Asisten Cerdas untuk aplikasi Catatan Offline.
Tugasmu membantu pengguna merangkum catatan, memberikan ide judul produktif,
dan tips belajar mobile. Jawab dalam Bahasa Indonesia secara ringkas, jelas, dan santun.
Jangan pernah meminta atau menyebarkan data pribadi rahasia seperti NIK, nomor telepon, atau kata sandi.
```

### 1.2. Contoh User Prompt & Format Payload
Ketika pengguna menanyakan pertanyaan seperti `"Beri saya 3 ide judul catatan untuk tugas kuliah mobile"`, payload HTTP POST ke Google Gemini API (`gemini-1.5-flash:generateContent`) dibungkus secara aman:

```json
{
  "contents": [
    {
      "role": "user",
      "parts": [
        {
          "text": "Kamu adalah Asisten Cerdas untuk aplikasi Catatan Offline... [System Prompt]\n\nPertanyaan Pengguna: Beri saya 3 ide judul catatan untuk tugas kuliah mobile"
        }
      ]
    }
  ],
  "generationConfig": {
    "temperature": 0.7,
    "maxOutputTokens": 500
  }
}
```

---

## 2. Draf Awal AI vs Refactoring Arsitektur

### 2.1. Draf Mentah Output Awal dari AI (Sebelum Refactor)
Pada rancangan awal yang disarankan oleh AI:
- Kunci API di-hardcode di dalam kode sumber (`String apiKey = 'AIzaSy...'`).
- Pemanggilan `http.post()` ditulis langsung di dalam event handler widget button `onPressed`.
- Tidak ada penanganan ketika koneksi internet mati atau ketika API key kosong (aplikasi langsung melempar unhandled exception / crash).
- Tidak ada sanitasi nomor telepon atau data pribadi.

### 2.2. Refactoring ke Clean Architecture & Secure Storage
Dilakukan perombakan menyeluruh menjadi struktur modular:
1. **Security Layer (`FlutterSecureStorage`):**  
   Kunci API disimpan di Keychain/Keystore terenkripsi bawaan OS melalui `flutter_secure_storage`. Pengguna memasukkan kunci melalui dialog UI dengan field `obscureText`.
2. **Service Layer (`lib/ai/ai_service.dart`):**  
   Memisahkan logika HTTP client Gemini API, sanitasi string (`sanitizePrompt`), dan mesin fallback offline berbasis aturan.
3. **State Management (`lib/presentation/ai_chat_notifier.dart`):**  
   Menggunakan Riverpod `Notifier<AiChatState>` untuk mengelola daftar pesan, status loading, ketersediaan API key, dan pesan error secara reaktif.
4. **UI Layer (`lib/pages/ai_chat_page.dart`):**  
   Tampilan obrolan responsif dengan bubble chat, chip suggestion instan, badge mode cloud vs offline, dan auto-scroll.

---

## 3. Arsitektur Fallback & Penanganan Kesalahan (Offline Fallback Engine)

Untuk mencegah aplikasi macet ketika:
- Kunci API belum diisi oleh pengguna,
- Kuota token API harian habis (*rate limit exceeded*), atau
- Perangkat berada di luar jangkauan sinyal internet (*airplane mode* / offline),

`AiService` mengimplementasikan fungsi `askWithFallback(question)`:
1. Jika API Key belum diatur, sistem otomatis mengalihkan permintaan ke `_generateLocalFallback(question)`.
2. Jika request HTTP ke Gemini API gagal (timeout, status 429, atau 500), exception ditangkap secara elegan (*graceful degradation*) dan pengguna diberikan jawaban alternatif yang relevan dari mesin fallback lokal disertai keterangan transparan:
   ```text
   *(Layanan AI cloud sedang tidak dapat dijangkau: [error]. Jawaban ini dihasilkan oleh Fallback Engine lokal).*
   ```

---

## 4. Evaluasi Pengalaman Pengguna (UX AI di Mobile)

1. **Indikator Proses (Thinking Indicator):** Memberikan feedback visual progress bar saat LLM memproses teks sehingga pengguna tidak mengira aplikasi *hang*.
2. **Chips Saran Cepat (Quick Suggestions):** Mengurangi beban mengetik di layar ponsel dengan menyediakan prompt siap pakai seperti *"Ringkas catatanku"*, *"Ide judul catatan produktif"*, dan *"Tips belajar Flutter"*.
3. **Pembedaan Visual (Bubble Styling):** Pesan dari pengguna diwarnai kontras di sebelah kanan, sedangkan respons AI di sebelah kiri dengan ikon bot dan label mode (Cloud vs Offline).
