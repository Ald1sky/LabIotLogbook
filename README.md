# LabIotLogbook

Aplikasi pencatatan peminjaman dan pengembalian peralatan laboratorium berbasis Flutter dan Ethereum Blockchain.

LabIotLogbook menggunakan Smart Contract pada jaringan Ethereum Sepolia Testnet untuk menyimpan riwayat peminjaman, pengembalian, dan pembatalan peminjaman alat laboratorium. Koneksi wallet dan persetujuan transaksi dilakukan melalui **Reown AppKit** dengan wallet seperti **MetaMask**.

## 1. Fitur Aplikasi

- Dashboard untuk melihat ringkasan data peminjaman.
- Pencatatan peminjaman alat laboratorium.
- Pengembalian alat laboratorium.
- Pembatalan peminjaman.
- Riwayat aktivitas peminjaman.
- Integrasi Ethereum Sepolia Testnet.
- Koneksi wallet melalui Reown AppKit (WalletConnect).
- Dukungan MetaMask dan wallet lain yang kompatibel dengan Reown.
- Menampilkan alamat wallet dan saldo ETH Sepolia.
- Persetujuan transaksi melalui wallet yang terhubung.
- Mode Light dan Dark.

## 2. Teknologi yang Digunakan

| Teknologi | Keterangan |
| :--- | :--- |
| Flutter | Framework aplikasi mobile |
| Dart | Bahasa pemrograman |
| Solidity | Smart Contract |
| Ethereum Blockchain | Blockchain |
| Sepolia Test Network | Test network |
| web3dart | Membaca data dan berinteraksi dengan smart contract melalui RPC |
| Reown AppKit | Menghubungkan wallet dan meminta persetujuan transaksi |
| WalletConnect | Protokol koneksi aplikasi dengan wallet |
| MetaMask | Salah satu wallet yang dapat dihubungkan |
| flutter_dotenv | Konfigurasi environment |
| http | Komunikasi HTTP dengan RPC |
| VS Code | Code Editor |

## 3. Informasi Smart Contract

| Informasi | Detail |
| :--- | :--- |
| Contract Name | LabIoTLogbook |
| Network | Ethereum Sepolia Testnet |
| Chain ID | 11155111 |
| Contract Address | `0x434bb4B9e10Dd9A277824f6E568FE389292a3f31` |

**Link Smart Contract:**

[View Contract on Sepolia Etherscan](https://sepolia.etherscan.io/address/0x434bb4B9e10Dd9A277824f6E568FE389292a3f31)

**Jaringan:** Sepolia Testnet, bukan Ethereum Mainnet.

## 4. Versi dan Dependencies

Dependencies utama yang digunakan:

| Package | Versi |
| :--- | :--- |
| web3dart | `^3.0.3` |
| reown_appkit | `^1.9.0` |
| wallet | `^0.0.18` (masih tercantum di pubspec.yaml) |
| flutter_dotenv | `^6.0.2` |
| http | `^1.2.2` |
| Flutter SDK | Batas SDK proyek `>=3.8.0 <4.0.0` |

Untuk melihat versi Flutter dan Dart:

```bash
flutter --version
```

Untuk melihat versi seluruh package yang terpasang:

```bash
flutter pub deps
```

File `pubspec.lock` digunakan sebagai referensi versi dependency yang benar-benar terpasang.

## 5. Persyaratan Sistem

Sebelum menjalankan aplikasi, pastikan sudah tersedia:

- Flutter SDK yang memenuhi batas SDK proyek.
- Dart SDK (termasuk dalam Flutter).
- Visual Studio Code.
- Android SDK atau perangkat Android.
- Koneksi internet.
- Reown Project ID dari Reown Cloud.
- Wallet seperti MetaMask yang mendukung Ethereum Sepolia.
- Sepolia ETH untuk biaya transaksi testnet.
- RPC URL Ethereum Sepolia.

## 6. Cara Menjalankan Project

### A. Clone Repository

```bash
git clone https://github.com/Ald1sky/LabIotLogbook.git
```

Masuk ke direktori project:

```bash
cd LabIotLogbook
```

### B. Install Dependencies

```bash
flutter pub get
```

### C. Konfigurasi Environment

Buat file `.env` di direktori utama project.

Isi file `.env`:

```env
SEPOLIA_RPC_URL=https://your-sepolia-rpc-url
```

Ganti URL tersebut dengan RPC URL Ethereum Sepolia milikmu.

### D. Konfigurasi Reown AppKit

1. Buat project pada Reown Cloud dan dapatkan Project ID.
2. Buka `lib/config/blockchain_config.dart`.
3. Isi `reownProjectId` dengan Project ID milik project Reown tersebut.
4. Pastikan konfigurasi jaringan menggunakan Ethereum Sepolia dengan Chain ID `11155111`.

Reown AppKit digunakan untuk menghubungkan aplikasi dengan wallet dan meminta persetujuan transaksi. Pengguna menyetujui transaksi melalui wallet yang terhubung, misalnya MetaMask. RPC Sepolia tetap digunakan aplikasi untuk membaca data blockchain dan memeriksa status transaksi.

### E. Periksa Konfigurasi

```bash
flutter doctor
```

Kemudian periksa kode:

```bash
flutter analyze
```

### F. Jalankan Aplikasi

Hubungkan perangkat Android atau jalankan emulator, kemudian:

```bash
flutter devices
```

Jalankan aplikasi:

```bash
flutter run
```

Setelah aplikasi terbuka, masuk ke menu Settings dan pilih **Connect Wallet** untuk menghubungkan MetaMask atau wallet lain melalui Reown AppKit. Pastikan wallet menggunakan jaringan Ethereum Sepolia.

## 7. Struktur Project

```text
chain_todo/
│
├── assets/
│   └── abi/
│       └── lab_iot_blockchain.json
│
├── lib/
│   ├── config/
│   │   └── blockchain_config.dart
│   │
│   ├── models/
│   │   └── loan_model.dart
│   │
│   ├── screens/
│   │   ├── main_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── loan_screen.dart
│   │   ├── activity_screen.dart
│   │   └── settings_screen.dart
│   │
│   ├── services/
│   │   └── blockchain_service.dart
│   │
│   ├── theme/
│   │   └── app_theme.dart
│   │
│   ├── widgets/
│   │   ├── bottom_nav.dart
│   │   ├── borrow_dialog.dart
│   │   └── loan_card.dart
│   │
│   └── main.dart
│
├── .env
├── .gitignore
├── pubspec.yaml
├── pubspec.lock
└── README.md
```

## 8. Fungsi Smart Contract

Smart Contract `LabIoTLogbook` menyediakan fungsi utama berikut:

| Fungsi | Keterangan |
| :--- | :--- |
| `pinjamAlat()` | Mencatat peminjaman alat |
| `kembalikanAlat()` | Mencatat pengembalian alat |
| `batalkanPeminjaman()` | Membatalkan peminjaman |
| `jumlahLog()` | Mengambil jumlah seluruh log |
| `ambilLog()` | Mengambil detail log berdasarkan ID |

Setiap transaksi perubahan data dicatat melalui jaringan Ethereum Sepolia. Transaksi dikirim melalui Reown AppKit dan harus disetujui oleh wallet yang terhubung.

## 9. Keamanan

- Gunakan wallet khusus pengujian.
- Gunakan hanya Sepolia Test ETH.
- Jangan memasukkan atau menyimpan private key wallet di aplikasi.
- Jangan mengunggah private key maupun RPC URL yang berisi API key ke GitHub.
- File `.env` harus dimasukkan ke `.gitignore`.
- Reown AppKit menghubungkan aplikasi dengan wallet; penandatanganan transaksi dilakukan oleh wallet, bukan dengan menyimpan private key di aplikasi.
- Simpan dan gunakan Reown Project ID sesuai konfigurasi aplikasi. Project ID bukan pengganti private key dan tidak boleh digunakan untuk menyimpan kredensial wallet.
- Data pribadi tidak disarankan disimpan langsung di blockchain.

Contoh `.gitignore`:

```gitignore
.env
.dart_tool/
.packages
build/
.flutter-plugins
.flutter-plugins-dependencies
```

## 10. Blockchain Explorer

Untuk memeriksa transaksi dan data Smart Contract, gunakan:

- [Sepolia Etherscan](https://sepolia.etherscan.io/)
- [LabIoTLogbook Smart Contract](https://sepolia.etherscan.io/address/0x434bb4B9e10Dd9A277824f6E568FE389292a3f31)

Hash transaksi dapat dimasukkan ke kolom pencarian Etherscan untuk melihat status transaksi.

## 11. Catatan Pengembangan

Project ini dikembangkan sebagai proyek pembelajaran integrasi aplikasi mobile Flutter dengan teknologi blockchain Ethereum.

Aplikasi menggunakan Reown AppKit untuk koneksi wallet dan persetujuan transaksi. Pembacaan data blockchain dan pemeriksaan status transaksi menggunakan RPC Ethereum Sepolia.

Seluruh transaksi pengujian menggunakan Ethereum Sepolia Testnet dan tidak menggunakan aset kripto pada jaringan utama.

---

**LabIotLogbook**  
Flutter Mobile Application + Ethereum Blockchain  
Reown AppKit + MetaMask  
Ethereum Sepolia Testnet