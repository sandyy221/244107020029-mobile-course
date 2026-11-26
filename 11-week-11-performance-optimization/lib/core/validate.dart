/// Validator untuk data catatan (notes)
class NoteValidator {
  /// Memvalidasi judul catatan.
  /// Mengembalikan pesan error jika judul null, kosong, atau hanya berisi spasi.
  /// Mengembalikan pesan error jika judul melebihi batas maksimal (100 karakter).
  /// Mengembalikan null jika valid.
  static String? validateTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return 'Judul tidak boleh kosong';
    }
    if (title.trim().length > 100) {
      return 'Judul terlalu panjang (maksimal 100 karakter)';
    }
    return null;
  }

  /// Memvalidasi isi catatan (opsional, batas maksimal 1000 karakter).
  static String? validateBody(String? body) {
    if (body != null && body.length > 1000) {
      return 'Isi catatan maksimal 1000 karakter';
    }
    return null;
  }
}
