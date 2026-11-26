# Docs Performance Findings - Week 11 Optimasi Performa

## Profil Aplikasi: `week5_offline_notes`

> Project: Notes Offline (Week 5–10 iterative build)  
> Platform: Flutter/Dart | Riverpod | SQLite | Gemini AI  
> Profiling: Flutter DevTools (profile mode)

---

## Baseline Profiling (Sebelum Optimasi)

### Skenario Pengujian

1. Buka halaman utama `SearchNotesPage` → scroll daftar 50+ catatan
2. Ketik karakter di search bar secara cepat (10 ketukan dalam 2 detik)
3. Navigasi ke `AiChatPage` → kirim 5 pesan → scroll ke atas/bawah
4. Kembali ke halaman utama → ulangi 3×

### Temuan Masalah (Sebelum Optimasi)

| # | Komponen | Masalah Teridentifikasi | Dampak |
|---|----------|------------------------|--------|
| 1 | `search_notes_page.dart` | Setiap ketukan keyboard memanggil `setState(() {})` di parent widget untuk rebuild tombol clear, menyebabkan rebuild seluruh `Scaffold` termasuk `AppBar`, `ListView`, dan badge dirty | Widget rebuild tidak perlu ± 15–20× lebih sering dari yang diperlukan |
| 2 | `search_notes_page.dart` | `ref.watch(notesSearchProvider)` di root `build()` tanpa pembatasan, sehingga perubahan `dirtyCountProvider` juga memicu rebuild body catatan | Rebuild gabungan: satu perubahan state → 2 widget subtree di-rebuild |
| 3 | `search_notes_page.dart` | Setiap karakter yang diketik langsung memanggil `notifier.updateQuery()` tanpa jeda → filter berjalan N kali pada list besar | CPU spike pada list besar (> 30 catatan) |
| 4 | `ai_chat_page.dart` | `ref.watch(aiChatProvider)` mengembalikan seluruh `AiChatState` → perubahan `isLoading` atau `hasApiKey` saja memicu rebuild seluruh halaman termasuk `ListView` pesan | Frame drop saat AI merespons, animasi loading stuttering |
| 5 | `ai_chat_page.dart` | `_buildMessageBubble()` adalah method di dalam StatefulWidget → closure baru setiap frame | GC pressure naik karena objek fungsi baru terus dibuat |
| 6 | `paged_post_page.dart` | Item `Card` + `ListTile` dibangun langsung di dalam `itemBuilder` tanpa ekstraksi | Setiap scroll `setState` mengekspansi seluruh item tree |
| 7 | Semua Dialog | `TextEditingController` dibuat di dalam `StatefulBuilder` tanpa dijamin `dispose()` terpanggil → risiko memory leak | Heap memory naik ±2–3 MB per navigasi buka-tutup dialog |

---

## Analisis Flame Chart (Baseline)

```
Frame #12 (merah – 38ms):
  build (SearchNotesPage)          → 18ms
    build (_DirtyBadge inline)     →  3ms
    build (ListTile × 30 items)    →  12ms
    paint (ListTile × 30)          →  5ms
  
Frame #23 (merah – 44ms, saat typing):
  updateQuery()                    → 2ms
  filterNotes (domain)             → 8ms
  build (SearchNotesPage root)     → 22ms   ← MASALAH: rebuild terlalu lebar
  paint (repaint seluruh body)     → 12ms
```

**Rata-rata frame time (baseline):** ~22 ms (target: < 16 ms)  
**Frame merah (> 32 ms):** ±12 frame dari 100 frame direkam  
**Frame kuning (16–32 ms):** ±34 frame dari 100 frame direkam  
**Memori (heap):** 42 MB setelah navigasi 10× bolak-balik

---

## Masalah Memory (Sebelum Optimasi)

```
Heap Snapshot #1 (halaman daftar):   38.2 MB
Heap Snapshot #2 (setelah 5× buka dialog): 46.8 MB  ← naik 8.6 MB
Heap Snapshot #3 (setelah 10× dialog):    54.1 MB  ← terus naik → memory leak
```

Objek yang menumpuk: `TextEditingController`, anonymous closure dari `StatefulBuilder`

---

## Kesimpulan Temuan

- **Bottleneck utama:** Rebuild terlalu lebar di `SearchNotesPage` (setState di root) dan AI Chat (watch seluruh state)
- **Bottleneck sekunder:** Tanpa debounce pada search, filter berjalan berlebihan
- **Risiko keamanan memori:** Dialog controller tidak di-dispose dengan benar
