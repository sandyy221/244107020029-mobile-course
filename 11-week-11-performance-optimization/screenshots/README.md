## Profiling Screenshots

Folder ini berisi screenshot hasil profiling Flutter DevTools sebelum dan sesudah optimasi.

### Daftar File

| File | Deskripsi |
|------|-----------|
| `before-profile.png` | Flame Chart baseline sebelum optimasi – terlihat frame merah saat typing search |
| `after-profile.png` | Flame Chart sesudah optimasi – frame time turun ke ~11ms rata-rata |
| `memory-baseline.png` | Heap memory naik terus setelah 10× buka dialog (memory leak) |
| `memory-after.png` | Heap memory stabil setelah perbaikan dispose() |

> **Catatan:** Screenshot profiling diambil menggunakan Flutter DevTools dalam mode `--profile`.
> Untuk mereproduksi: jalankan `flutter run --profile` lalu buka DevTools → tab Performance → Record.
