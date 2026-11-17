
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import 'package:wallet/wallet.dart';

import '../config/blockchain_config.dart';
import '../models/loan_model.dart';

class BlockchainService {
  Web3Client? _client;
  DeployedContract? _contract;

  EthPrivateKey? _credentials;
  String? _walletAddress;

  String? get walletAddress => _walletAddress;

  bool get isWalletConnected => _credentials != null;

  // INISIALISASI RPC DAN SMART CONTRACT
  Future<void> initialize() async {
    if (!BlockchainConfig.isRpcConfigured) {
      throw StateError('RPC Sepolia belum dikonfigurasi.');
    }

    if (_client != null && _contract != null) {
      return;
    }

    final client = Web3Client(
      BlockchainConfig.rpcUrl,
      http.Client(),
    );

    try {
      final abiJson = await rootBundle.loadString(
        BlockchainConfig.abiPath,
      );

      final contractAbi = ContractAbi.fromJson(
        abiJson,
        'LabIoTLogbook',
      );

      final contract = DeployedContract(
        contractAbi,
        EthereumAddress.fromHex(
          BlockchainConfig.contractAddress,
        ),
      );

      _client = client;
      _contract = contract;
    } catch (_) {
      client.dispose();
      rethrow;
    }
  }

  // INISIALISASI WALLET DARI .ENV
  Future<void> initializeWallet() async {
    if (isWalletConnected) return;

    final privateKey = dotenv.env['PRIVATE_KEY']?.trim();

    if (privateKey == null || privateKey.isEmpty) {
      throw StateError(
        'PRIVATE_KEY tidak ditemukan di file .env.',
      );
    }

    final credentials = EthPrivateKey.fromHex(privateKey);

    _credentials = credentials;

    _walletAddress = bytesToHex(
      credentials.address.value,
      include0x: true,
    );
  }

  // KOMPATIBILITAS DENGAN KODE LAMA
  Future<String> connectWallet(String privateKey) async {
    final key = privateKey.trim();

    if (key.isEmpty) {
      throw ArgumentError('Private key tidak boleh kosong.');
    }

    final credentials = EthPrivateKey.fromHex(key);

    _credentials = credentials;

    _walletAddress = bytesToHex(
      credentials.address.value,
      include0x: true,
    );

    return _walletAddress!;
  }

  // MENGAMBIL SALDO WALLET
  Future<EtherAmount> getWalletBalance() async {
    await initialize();

    if (_credentials == null) {
      throw StateError('Wallet belum terhubung.');
    }

    return _client!.getBalance(
      _credentials!.address,
    );
  }

  // MENGIRIM TRANSAKSI SMART CONTRACT
  Future<String> _sendContractTransaction(
    String functionName,
    List<dynamic> params,
  ) async {
    await initialize();

    if (_credentials == null) {
      throw StateError('Wallet belum terhubung.');
    }

    final function = _contract!.function(functionName);

    final transaction = Transaction(
      to: _contract!.address,
      data: function.encodeCall(params),
      maxGas: 600000,
    );

    return _client!.sendTransaction(
      _credentials!,
      transaction,
      chainId: BlockchainConfig.chainId,
    );
  }

  // TRANSAKSI: MEMINJAM ALAT
  Future<String> pinjamAlat(
    String namaAlat,
    String namaPeminjam,
  ) async {
    if (namaAlat.trim().isEmpty ||
        namaPeminjam.trim().isEmpty) {
      throw ArgumentError(
        'Nama alat dan kode peminjam wajib diisi.',
      );
    }

    return _sendContractTransaction(
      'pinjamAlat',
      [
        namaAlat.trim(),
        namaPeminjam.trim(),
      ],
    );
  }

  // TRANSAKSI: MENGEMBALIKAN ALAT
  Future<String> kembalikanAlat(int id) async {
    if (id < 0) {
      throw ArgumentError('ID peminjaman tidak valid.');
    }

    return _sendContractTransaction(
      'kembalikanAlat',
      [BigInt.from(id)],
    );
  }

  // TRANSAKSI: MEMBATALKAN PEMINJAMAN
  Future<String> batalkanPeminjaman(int id) async {
    if (id < 0) {
      throw ArgumentError('ID peminjaman tidak valid.');
    }

    return _sendContractTransaction(
      'batalkanPeminjaman',
      [BigInt.from(id)],
    );
  }

  // READ: MENGAMBIL JUMLAH SELURUH LOG
  Future<int> getJumlahLog() async {
    await initialize();

    final result = await _client!.call(
      contract: _contract!,
      function: _contract!.function('jumlahLog'),
      params: [],
    );

    return (result.first as BigInt).toInt();
  }

  // READ: MENGAMBIL DETAIL LOG
  Future<LoanModel> getLog(int id) async {
    await initialize();

    final result = await _client!.call(
      contract: _contract!,
      function: _contract!.function('ambilLog'),
      params: [BigInt.from(id)],
    );

    return LoanModel(
      id: id,
      namaAlat: result[0] as String,
      namaPeminjam: result[1] as String,
      waktuPinjam: (result[2] as BigInt).toInt(),
      waktuKembali: (result[3] as BigInt).toInt(),
      statusKembali: result[4] as bool,
      dibatalkan: result[5] as bool,
      walletPeminjam: bytesToHex(
        (result[6] as EthereumAddress).value,
        include0x: true,
      ),
    );
  }

  // READ: MENGAMBIL SELURUH DATA PEMINJAMAN
  Future<List<LoanModel>> getAllLogs() async {
    final jumlah = await getJumlahLog();

    final List<LoanModel> logs = [];

    for (int id = 0; id < jumlah; id++) {
      logs.add(await getLog(id));
    }

    return logs.reversed.toList();
  }

  // MENUTUP KONEKSI
  void dispose() {
    _credentials = null;
    _walletAddress = null;

    _client?.dispose();

    _client = null;
    _contract = null;
  }
}
