import 'dart:async';

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

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    if (_client != null && _contract != null) {
      return;
    }

    if (!BlockchainConfig.isRpcConfigured) {
      throw StateError('RPC Sepolia belum dikonfigurasi.');
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
    } catch (e) {
      client.dispose();
      rethrow;
    }
  }

  // ============================================================
  // RPC RETRY
  // ============================================================

  Future<T> _withRpcRetry<T>(
    Future<T> Function() request,
  ) async {
    const retryDelays = [
      1,
      2,
      4,
      8,
      15,
    ];

    for (int attempt = 0; attempt <= retryDelays.length; attempt++) {
      try {
        return await request();
      } catch (e) {
        final message = e.toString().toLowerCase();

        final isRateLimit = message.contains('429') ||
            message.contains('compute units') ||
            message.contains('too many requests') ||
            message.contains('rate limit');

        if (!isRateLimit || attempt == retryDelays.length) {
          rethrow;
        }

        await Future.delayed(
          Duration(seconds: retryDelays[attempt]),
        );
      }
    }

    throw Exception('Permintaan RPC gagal.');
  }

  // ============================================================
  // WALLET
  // ============================================================

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

  void disconnectWallet() {
    _credentials = null;
    _walletAddress = null;
  }

  // MENGAMBIL SALDO WALLET
  Future<EtherAmount> getWalletBalance() async {
    await initialize();

    if (_credentials == null) {
      throw StateError('Wallet belum terhubung.');
    }

    return _withRpcRetry(
      () => _client!.getBalance(
        _credentials!.address,
      ),
    );
  }
  // ============================================================
  // SEND TRANSACTION
  // ============================================================
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

    final hash = await _client!.sendTransaction(
      _credentials!,
      transaction,
      chainId: BlockchainConfig.chainId,
    );

    // Tunggu konfirmasi transaksi.
    const maxAttempts = 60;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final receipt = await _withRpcRetry(
        () => _client!.getTransactionReceipt(hash),
      );

      if (receipt != null) {
        if (receipt.status == true) {
          return hash;
        }

        if (receipt.status == false) {
          throw StateError(
            'Transaksi gagal dieksekusi oleh smart contract. '
            'Hash: $hash',
          );
        }

        throw StateError(
          'Status receipt transaksi tidak tersedia. Hash: $hash',
        );
      }

      await Future.delayed(
        const Duration(seconds: 2),
      );
    }

    throw TimeoutException(
      'Transaksi masih menunggu konfirmasi. '
      'Periksa Etherscan. Hash: $hash',
    );
  }

  // ============================================================
  // PINJAM ALAT
  // ============================================================

  Future<String> pinjamAlat(
    String namaAlat,
    String namaPeminjam,
  ) async {
    if (namaAlat.trim().isEmpty || namaPeminjam.trim().isEmpty) {
      throw ArgumentError(
        'Nama alat dan nama peminjam wajib diisi.',
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
  // ============================================================
  // KEMBALIKAN ALAT
  // ============================================================

  Future<String> kembalikanAlat(int id) async {
    if (id < 0) {
      throw ArgumentError('ID peminjaman tidak valid.');
    }

    return _sendContractTransaction(
      'kembalikanAlat',
      [BigInt.from(id)],
    );
  }
  // ============================================================
  // BATALKAN PEMINJAMAN
  // ============================================================
  Future<String> batalkanPeminjaman(int id) async {
    if (id < 0) {
      throw ArgumentError('ID peminjaman tidak valid.');
    }

    return _sendContractTransaction(
      'batalkanPeminjaman',
      [BigInt.from(id)],
    );
  }
  // ============================================================
  // READ: JUMLAH LOG
  // ============================================================
  Future<int> getJumlahLog() async {
    await initialize();

    final result = await _withRpcRetry(
      () => _client!.call(
        contract: _contract!,
        function: _contract!.function('jumlahLog'),
        params: [],
      ),
    );

    return (result.first as BigInt).toInt();
  }
  // ============================================================
  // READ: SATU LOG
  // ============================================================

  Future<LoanModel> getLog(int id) async {
    await initialize();

    if (id < 0) {
      throw ArgumentError('ID peminjaman tidak valid.');
    }

    final result = await _withRpcRetry(
      () => _client!.call(
        contract: _contract!,
        function: _contract!.function('ambilLog'),
        params: [
          BigInt.from(id),
        ],
      ),
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
  // ============================================================
  // READ: SELURUH LOG
  // ============================================================
  Future<List<LoanModel>> getAllLogs() async {
    await initialize();

    final jumlah = await getJumlahLog();

    final List<LoanModel> logs = [];

    for (int id = 0; id < jumlah; id++) {
      final loan = await getLog(id);

      logs.add(loan);

      // Kurangi tekanan request ke RPC.
      if (id < jumlah - 1) {
        await Future.delayed(
          const Duration(milliseconds: 150),
        );
      }
    }

    return logs.reversed.toList();
  }
  // ============================================================
// WATCH SMART CONTRACT EVENT
// ============================================================

  Future<Stream<FilterEvent>> watchEvent(String eventName) async {
    await initialize();

    final event = _contract!.event(eventName);

    return _client!.events(
      FilterOptions.events(
        contract: _contract!,
        event: event,
      ),
    );
  }

  // ============================================================
  // ACTIVITY HISTORY
  // ============================================================

  Future<List<String>> getActivityHistory() async {
    await initialize();

    // Ambil seluruh data langsung dari smart contract.
    final loans = await getAllLogs();

    final List<_ActivityItem> activities = [];

    for (final loan in loans) {
      // Aktivitas peminjaman.
      activities.add(
        _ActivityItem(
          message: '${loan.namaPeminjam} meminjam ${loan.namaAlat}',
          timestamp: loan.waktuPinjam,
          id: loan.id,
          order: 0,
        ),
      );

      // Aktivitas pengembalian.
      if (loan.statusKembali && loan.waktuKembali > 0) {
        activities.add(
          _ActivityItem(
            message: '${loan.namaPeminjam} mengembalikan ${loan.namaAlat}',
            timestamp: loan.waktuKembali,
            id: loan.id,
            order: 1,
          ),
        );
      }

      // Aktivitas pembatalan.
      if (loan.dibatalkan) {
        activities.add(
          _ActivityItem(
            message: '${loan.namaPeminjam} membatalkan peminjaman '
                '${loan.namaAlat}',
            // Smart contract lama tidak menyimpan waktu pembatalan.
            // Waktu pinjam hanya digunakan sebagai perkiraan urutan.
            timestamp: loan.waktuPinjam,
            id: loan.id,
            order: 1,
          ),
        );
      }
    }

    // Urutkan aktivitas dari terbaru ke terlama.
    activities.sort((a, b) {
      final timeCompare = b.timestamp.compareTo(a.timestamp);

      if (timeCompare != 0) {
        return timeCompare;
      }

      final idCompare = b.id.compareTo(a.id);

      if (idCompare != 0) {
        return idCompare;
      }

      return b.order.compareTo(a.order);
    });

    return activities.map((activity) => activity.message).toList();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    disconnectWallet();

    await _client?.dispose();

    _client = null;
    _contract = null;
  }
}

// ============================================================
// ACTIVITY MODEL
// ============================================================

class _ActivityItem {
  final String message;
  final int timestamp;
  final int id;
  final int order;

  const _ActivityItem({
    required this.message,
    required this.timestamp,
    required this.id,
    required this.order,
  });
}
