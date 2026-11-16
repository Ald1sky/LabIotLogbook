class LoanModel {
  final int id;
  final String namaAlat;
  final String namaPeminjam;
  final int waktuPinjam;
  final int waktuKembali;
  final bool statusKembali;
  final bool dibatalkan;
  final String walletPeminjam;

  const LoanModel({
    required this.id,
    required this.namaAlat,
    required this.namaPeminjam,
    required this.waktuPinjam,
    required this.waktuKembali,
    required this.statusKembali,
    required this.dibatalkan,
    required this.walletPeminjam,
  });

  bool get sedangDipinjam => !statusKembali && !dibatalkan;

  DateTime get tanggalPinjam =>
      DateTime.fromMillisecondsSinceEpoch(waktuPinjam * 1000);

  DateTime? get tanggalKembali => waktuKembali == 0
      ? null
      : DateTime.fromMillisecondsSinceEpoch(waktuKembali * 1000);
}
