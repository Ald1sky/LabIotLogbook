
import 'package:flutter/services.dart';
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

  // Inisialisasi koneksi blockchain.
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
    } catch (error) {
      client.dispose();
      rethrow;
    }
  }

  // Menghubungkan wallet menggunakan private key.
  // Private key hanya disimpan sementara di memori.
  Future<String> connectWallet(String privateKey) async {
    await initialize();

    final key = privateKey.trim();

    if (key.isEmpty) {
      throw ArgumentError('Private key tidak boleh kosong.');
    }

    final credentials = EthPrivateKey.fromHex(key);

    final address = credentials.address;

    _credentials = credentials;

    _walletAddress = bytesToHex(
      address.value,
      include0x: true,
    );

    return _walletAddress!;
  }

  // Memutuskan koneksi wallet dari service.
  void disconnectWallet() {
    _credentials = null;
    _walletAddress = null;
  }

  // Memeriksa saldo wallet.
  Future<EtherAmount> getWalletBalance() async {
    await initialize();

    if (_credentials == null) {
      throw StateError('Wallet belum terhubung.');
    }

    return _client!.getBalance(
      _credentials!.address,
    );
  }

  // Mengirim transaksi ke smart contract.
  Future<String> _sendContractTransaction(
    String functionName,
    List<dynamic> params,
  ) async {
    await initialize();

    if (_credentials == null) {
      throw StateError('Hubungkan wallet terlebih dahulu.');
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

  // TRANSAKSI 1: Meminjam alat.
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

  // TRANSAKSI 2: Mengembalikan alat.
  Future<String> kembalikanAlat(int id) async {
    if (id < 0) {
      throw ArgumentError('ID peminjaman tidak valid.');
    }

    return _sendContractTransaction(
      'kembalikanAlat',
      [
        BigInt.from(id),
      ],
    );
  }

  // TRANSAKSI 3: Membatalkan peminjaman.
  Future<String> batalkanPeminjaman(int id) async {
    if (id < 0) {
      throw ArgumentError('ID peminjaman tidak valid.');
    }

    return _sendContractTransaction(
      'batalkanPeminjaman',
      [
        BigInt.from(id),
      ],
    );
  }

  // READ: Mengambil jumlah seluruh log.
  Future<int> getJumlahLog() async {
    await initialize();

    final result = await _client!.call(
      contract: _contract!,
      function: _contract!.function('jumlahLog'),
      params: [],
    );

    return (result.first as BigInt).toInt();
  }

  // READ: Mengambil detail log.
  Future<LoanModel> getLog(int id) async {
    await initialize();

    final result = await _client!.call(
      contract: _contract!,
      function: _contract!.function('ambilLog'),
      params: [
        BigInt.from(id),
      ],
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

  // READ: Mengambil seluruh data peminjaman.
  Future<List<LoanModel>> getAllLogs() async {
    final jumlah = await getJumlahLog();

    final List<LoanModel> logs = [];

    for (int id = 0; id < jumlah; id++) {
      final loan = await getLog(id);
      logs.add(loan);
    }

    return logs.reversed.toList();
  }

  // Menutup koneksi blockchain.
  void dispose() {
    disconnectWallet();

    _client?.dispose();

    _client = null;
    _contract = null;
  }
}
