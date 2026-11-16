# LabIotLogbook

Aplikasi pencatatan peminjaman dan pengembalian peralatan laboratorium berbasis Flutter dan Ethereum Blockchain.

LabIotLogbook menggunakan Smart Contract pada jaringan Ethereum Sepolia Testnet untuk menyimpan riwayat peminjaman, pengembalian, dan pembatalan peminjaman alat laboratorium.

## 1. Fitur Aplikasi

- Dashboard untuk melihat ringkasan data peminjaman.
- Pencatatan peminjaman alat laboratorium.
- Pengembalian alat laboratorium.
- Pembatalan peminjaman.
- Riwayat aktivitas peminjaman.
- Integrasi Ethereum Sepolia Testnet.
- Koneksi wallet menggunakan private key.
- Menampilkan alamat wallet dan saldo ETH Sepolia.
- Mode Light dan Dark.

## 2. Teknologi yang Digunakan

| Teknologi | Keterangan |
|---|---|
| Flutter | Framework aplikasi mobile |
| Dart | Bahasa pemrograman |
| Solidity | Smart Contract |
| Ethereum | Blockchain |
| Sepolia | Test Network |
| web3dart | Integrasi Flutter dengan Ethereum |
| flutter_dotenv | Konfigurasi environment |
| VS Code | Code Editor |

## 3. Informasi Smart Contract

| Informasi | Detail |
|---|---|
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
|---|---|
| web3dart | ^3.0.3 |
| wallet | ^0.0.18 |
| Flutter SDK | Sesuai instalasi pengembangan |
| flutter_dotenv | Lihat pubspec.yaml |
| http | Lihat pubspec.yaml |

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

- Flutter SDK.
- Dart SDK (termasuk dalam Flutter).
- Visual Studio Code.
- Android SDK atau perangkat Android.
- Koneksi internet.
- Wallet MetaMask khusus pengujian.
- Sepolia ETH untuk biaya transaksi testnet.
- RPC URL Ethereum Sepolia.

## 6. Cara Menjalankan Project

### A. Clone Repository

```bash
git clone https://github.com/USERNAME/REPOSITORY.git
```

Masuk ke direktori project:

```bash
cd chain_todo
```

### B. Install Dependencies

Jalankan perintah:

```bash
flutter pub get
```

### C. Konfigurasi Environment

Buat file `.env` di direktori utama project.

Isi file `.env`:

```env
SEPOLIA_RPC_URL=https://your-sepolia-rpc-url
```

Ganti URL tersebut dengan RPC URL Ethereum Sepolia yang digunakan.

**Catatan:** Jangan memasukkan private key wallet ke dalam file `.env` atau repository.

### D. Periksa Konfigurasi

Jalankan:

```bash
flutter doctor
```

Kemudian periksa kode:

```bash
flutter analyze
```

### E. Jalankan Aplikasi

Hubungkan perangkat Android atau jalankan emulator, kemudian:

```bash
flutter devices
```

Jalankan aplikasi:

```bash
flutter run
```

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
|---|---|
| `pinjamAlat()` | Mencatat peminjaman alat |
| `kembalikanAlat()` | Mencatat pengembalian alat |
| `batalkanPeminjaman()` | Membatalkan peminjaman |
| `jumlahLog()` | Mengambil jumlah seluruh log |
| `ambilLog()` | Mengambil detail log berdasarkan ID |

Setiap transaksi perubahan data dicatat melalui jaringan Ethereum Sepolia.

## 9. Keamanan

- Gunakan wallet khusus pengujian.
- Gunakan hanya Sepolia Test ETH.
- Jangan menggunakan private key wallet utama.
- Jangan mengunggah private key ke GitHub.
- File `.env` harus dimasukkan ke `.gitignore`.
- Data pribadi tidak disarankan disimpan langsung di blockchain.
- Private key yang digunakan langsung di aplikasi mobile memiliki risiko terekspos melalui APK atau proses aplikasi. Metode ini hanya digunakan untuk kebutuhan demonstrasi dan pengujian akademik.

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

Seluruh transaksi pengujian menggunakan Ethereum Sepolia Testnet dan tidak menggunakan aset kripto pada jaringan utama.

---

**LabIotLogbook**  
Flutter Mobile Application + Ethereum Blockchain  
Ethereum Sepolia Testnet