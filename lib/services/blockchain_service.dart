
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:reown_appkit/reown_appkit.dart';

import '../config/blockchain_config.dart';
import '../models/loan_model.dart';

class BlockchainService {
  Web3Client? _client;
  DeployedContract? _contract;

  IReownAppKitModal? _appKitModal;
  String? _walletAddress;

  String? get walletAddress => _walletAddress;

  bool get isWalletConnected =>

      _walletAddress != null && _appKitModal?.isConnected == true;

      _walletAddress != null &&
      _appKitModal?.isConnected == true;
 57a3c58 (Update fitur)

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

    for (
      int attempt = 0;
      attempt <= retryDelays.length;
      attempt++
    ) {
      try {
        return await request();
      } catch (e) {
        final message = e.toString().toLowerCase();

        final isRateLimit =
            message.contains('429') ||
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
  // WALLET - REOWN APPKIT
  // ============================================================


  Future<void> connectWallet(String address, IReownAppKitModal appKitModal) async {
    final normalized = address.trim();
    if (!RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(normalized)) {
      throw ArgumentError('Alamat wallet tidak valid.');
    }
    _walletAddress = normalized;
    _appKitModal = appKitModal;
  }

  void disconnectWallet() {

  Future<String> connectWallet(
    String address,
    IReownAppKitModal appKitModal,
  ) async {
    await initialize();

    final wallet = address.trim();

    if (wallet.isEmpty) {
      throw ArgumentError(
        'Alamat wallet tidak ditemukan.',
      );
    }

    if (!RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(wallet)) {
      throw ArgumentError(
        'Format alamat wallet tidak valid.',
      );
    }

    if (!appKitModal.isConnected ||
        appKitModal.session == null) {
      throw StateError(
        'Sesi Reown belum terhubung.',
      );
    }

    _appKitModal = appKitModal;
    _walletAddress = wallet;

    return _walletAddress!;
  }

  void disconnectWallet() {
    _appKitModal = null;
 57a3c58 (Update fitur)
    _walletAddress = null;
    _appKitModal = null;
  }

  // ============================================================
  // GET WALLET BALANCE
  // ============================================================

  Future<EtherAmount> getWalletBalance() async {
    await initialize();

    if (!isWalletConnected) {
      throw StateError('Wallet belum terhubung.');
    }
    final address = EthereumAddress.fromHex(_walletAddress!);
    return _withRpcRetry(() => _client!.getBalance(address));
  }



    if (!isWalletConnected || _walletAddress == null) {
      throw StateError(
        'Wallet belum terhubung.',
      );
    }

    final address = EthereumAddress.fromHex(
      _walletAddress!,
    );

    return _withRpcRetry(
      () => _client!.getBalance(address),
    );
  }

  // ============================================================
  // SEND CONTRACT TRANSACTION - REOWN
  // ============================================================

 57a3c58 (Update fitur)
  Future<String> _sendContractTransaction(
    String functionName,
    List<dynamic> params,
  ) async {
    await initialize();

    final modal = _appKitModal;
    if (!isWalletConnected || modal == null) {
      throw StateError('Hubungkan wallet terlebih dahulu.');
    }

    final session = modal.session;
    if (session == null) {
      throw StateError('Sesi wallet Reown tidak ditemukan. Hubungkan ulang wallet.');
    }

    final appKit = _appKitModal;

    if (!isWalletConnected || appKit == null) {
      throw StateError(
        'Hubungkan wallet terlebih dahulu.',
      );
    }

    final session = appKit.session;

    if (session == null) {
      throw StateError(
        'Sesi wallet tidak ditemukan.',
      );
    }

    // Pastikan wallet menggunakan Ethereum Sepolia.
    final expectedChain =
        'eip155:${BlockchainConfig.chainId}';

    if (session.chainId != expectedChain) {
      throw StateError(
        'Wallet belum menggunakan Ethereum Sepolia. '
        'Silakan ganti jaringan melalui Reown AppKit.',
      );
    }

    final function = _contract!.function(
      functionName,
    );
 57a3c58 (Update fitur)

    final chainId = 'eip155:${BlockchainConfig.chainId}';
    final function = _contract!.function(functionName);
    final transaction = Transaction(
      from: EthereumAddress.fromHex(_walletAddress!),
      to: _contract!.address,
      data: function.encodeCall(params),
      maxGas: 600000,
    );


    // Penandatanganan dan pengiriman transaksi dilakukan oleh wallet melalui Reown.
    final dynamic response = await modal.requestWriteContract(
      topic: session.topic,
      chainId: chainId,

    // Kirim transaksi ke wallet melalui Reown AppKit.
    // Pengguna harus menyetujui transaksi dari wallet.
    final response = await appKit.requestWriteContract(
      topic: session.topic,
      chainId: expectedChain,
 57a3c58 (Update fitur)
      deployedContract: _contract!,
      functionName: functionName,
      transaction: transaction,
      parameters: params,
    );


    final hash = _extractTransactionHash(response);
    if (hash == null) {
      throw StateError('Wallet tidak mengembalikan transaction hash: $response');
    }

    const maxAttempts = 90;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {

    final hash = response.toString();

    if (!RegExp(r'^0x[a-fA-F0-9]{64}$').hasMatch(hash)) {
      throw StateError(
        'Wallet tidak mengembalikan transaction hash '
        'yang valid: $hash',
      );
    }

    // ========================================================
    // WAIT FOR TRANSACTION RECEIPT
    // ========================================================

    const maxAttempts = 60;

    for (
      int attempt = 0;
      attempt < maxAttempts;
      attempt++
    ) {
>>>>>>> 57a3c58 (Update fitur)
      final receipt = await _withRpcRetry(
        () => _client!.getTransactionReceipt(hash),
      );
      if (receipt != null) {
        if (receipt.status == true) return hash;
        if (receipt.status == false) {
          throw StateError('Transaksi gagal dieksekusi smart contract. Hash: $hash');
        }


        throw StateError(
          'Status receipt transaksi tidak tersedia. '
          'Hash: $hash',
        );
 57a3c58 (Update fitur)
      }
      await Future.delayed(const Duration(seconds: 2));
    }

    throw TimeoutException(
      'Transaksi belum terkonfirmasi. Periksa Etherscan. Hash: $hash',
    );
  }

  String? _extractTransactionHash(dynamic response) {
    if (response == null) return null;
    if (response is String) {
      final match = RegExp(r'0x[a-fA-F0-9]{64}').firstMatch(response);
      return match?.group(0);
    }
    if (response is Map) {
      for (final key in ['transactionHash', 'txHash', 'hash']) {
        final value = response[key];
        if (value != null) {
          final match = RegExp(r'0x[a-fA-F0-9]{64}').firstMatch(value.toString());
          if (match != null) return match.group(0);
        }
      }
    }
    final match = RegExp(r'0x[a-fA-F0-9]{64}').firstMatch(response.toString());
    return match?.group(0);
  }

  // ============================================================
  // PINJAM ALAT
  // ============================================================

  Future<String> pinjamAlat(
    String namaAlat,
    String namaPeminjam,
  ) async {
    if (namaAlat.trim().isEmpty ||
        namaPeminjam.trim().isEmpty) {
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
      throw ArgumentError(
        'ID peminjaman tidak valid.',
      );
    }

    return _sendContractTransaction(
      'kembalikanAlat',
      [
        BigInt.from(id),
      ],
    );
  }

  Future<String> batalkanPeminjaman(int id) async {
    if (id < 0) {
      throw ArgumentError(
        'ID peminjaman tidak valid.',
      );
    }

    return _sendContractTransaction(
      'batalkanPeminjaman',
      [
        BigInt.from(id),
      ],
    );
  }

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
      throw ArgumentError(
        'ID peminjaman tidak valid.',
      );
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

  Future<Stream<FilterEvent>> watchEvent(
    String eventName,
  ) async {
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

    final loans = await getAllLogs();

    final List<_ActivityItem> activities = [];

    for (final loan in loans) {
      // Aktivitas peminjaman.
      activities.add(
        _ActivityItem(
          message:
              '${loan.namaPeminjam} meminjam ${loan.namaAlat}',
          timestamp: loan.waktuPinjam,
          id: loan.id,
          order: 0,
        ),
      );

      // Aktivitas pengembalian.
      if (loan.statusKembali && loan.waktuKembali > 0) {
        activities.add(
          _ActivityItem(
            message:
                '${loan.namaPeminjam} mengembalikan ${loan.namaAlat}',
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
            message:
                '${loan.namaPeminjam} membatalkan peminjaman '
                '${loan.namaAlat}',

            // Kontrak lama tidak menyimpan waktu pembatalan.
            // Waktu pinjam dipakai sebagai perkiraan urutan.
            timestamp: loan.waktuPinjam,
            id: loan.id,
            order: 1,
          ),
        );
      }
    }

    // Urutkan aktivitas dari terbaru ke terlama.
    activities.sort((a, b) {
      final timeCompare =
          b.timestamp.compareTo(a.timestamp);

      if (timeCompare != 0) {
        return timeCompare;
      }

      final idCompare = b.id.compareTo(a.id);

      if (idCompare != 0) {
        return idCompare;
      }

      return b.order.compareTo(a.order);
    });

    return activities
        .map((activity) => activity.message)
        .toList();
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
