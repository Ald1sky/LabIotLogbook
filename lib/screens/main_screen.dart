import 'package:flutter/services.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../config/blockchain_config.dart';
import '../models/loan_model.dart';
import '../services/blockchain_service.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/borrow_dialog.dart';

import 'dashboard_screen.dart';
import 'loan_screen.dart';
import 'activity_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<bool> onToggleTheme;

  const MainScreen({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _walletInitializing = true;
  String? _walletError;
  String? _walletBalance;
  bool _balanceLoading = false;
  String? _balanceError;

  int _selectedIndex = 0;

  final BlockchainService _blockchain = BlockchainService();
  final List<StreamSubscription<dynamic>> _eventSubscriptions = [];

  bool _loading = false;
  bool _refreshInProgress = false;
  bool _transactionInProgress = false;

  String? _loadError;

  List<LoanModel> _loans = [];
  List<String> _activities = [];

  bool get _demoMode => !BlockchainConfig.isRpcConfigured;

  // ============================================================
  // DEMO DATA
  // ============================================================

  final List<LoanModel> _demoLoans = [
    LoanModel(
      id: 0,
      namaAlat: 'Arduino Uno',
      namaPeminjam: 'Muhammad',
      waktuPinjam: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      waktuKembali: 0,
      statusKembali: false,
      dibatalkan: false,
      walletPeminjam: '0x0000000000000000000000000000000000000000',
    ),
    LoanModel(
      id: 1,
      namaAlat: 'Sensor DHT11',
      namaPeminjam: 'Ahmad',
      waktuPinjam: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      waktuKembali: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      statusKembali: true,
      dibatalkan: false,
      walletPeminjam: '0x0000000000000000000000000000000000000000',
    ),
  ];

  final List<String> _demoActivities = [
    'Sensor DHT11 telah dikembalikan (data demo)',
    'Arduino Uno telah dipinjam (data demo)',
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loans = List.of(_demoLoans);
    _activities = List.of(_demoActivities);

if (!_demoMode) {
  _initializeBlockchainAndListen();
}
  }


Future<void> _initializeBlockchainAndListen() async {
  try {
    await _blockchain.initialize();

    await _startEventListeners();

    await _refreshBlockchainData();
  } catch (e) {
    debugPrint('Blockchain initialization error: $e');
  }
}

Future<void> _startEventListeners() async {
  const eventNames = [
    'AlatDipinjam',
    'AlatDikembalikan',
    'PeminjamanDibatalkan',
  ];

  for (final eventName in eventNames) {
    try {
      final stream = await _blockchain.watchEvent(eventName);

      final subscription = stream.listen(
        (event) {
          debugPrint('Event blockchain diterima: $eventName');

          if (!mounted) return;

          // Muat ulang data setelah event diterima.
          unawaited(_refreshBlockchainData());
        },
        onError: (error) {
          debugPrint('Event $eventName error: $error');
        },
      );

      _eventSubscriptions.add(subscription);
    } catch (e) {
      debugPrint('Gagal mendengarkan $eventName: $e');
    }
  }
}


@override
void dispose() {
  for (final subscription in _eventSubscriptions) {
    unawaited(subscription.cancel());
  }
  unawaited(_blockchain.dispose());

  super.dispose();
}

  // ============================================================
  // REFRESH DATA
  // ============================================================
  Future<void> _refreshBlockchainData() async {
    if (_demoMode || _refreshInProgress) return;

    _refreshInProgress = true;

    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }

    try {
      final loans = await _blockchain.getAllLogs();

      if (!mounted) return;

      setState(() {
        _loans = loans;
      });

      final activities = await _blockchain.getActivityHistory();

      if (!mounted) return;

      setState(() {
        _activities = activities;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadError = 'Gagal membaca blockchain: $e';
      });

      _showMessage('Gagal membaca blockchain: $e');
    } finally {
      _refreshInProgress = false;

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _refreshWalletBalance() async {
    if (!_blockchain.isWalletConnected || _demoMode) return;

    if (!mounted) return;

    setState(() {
      _balanceLoading = true;
      _balanceError = null;
    });

    try {
      final balance = await _blockchain.getWalletBalance();

      if (!mounted) return;

      setState(() {
        _walletBalance =
            (balance.getInWei.toDouble() / 1e18).toStringAsFixed(6);
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _balanceError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _balanceLoading = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================
  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // WALLET OWNER
  // ============================================================

  bool _isCurrentWalletOwner(LoanModel loan) {
    final address = _blockchain.walletAddress;

    if (address == null) return false;

    return address.toLowerCase() == loan.walletPeminjam.toLowerCase();
  }

  // ============================================================
  // REFRESH AFTER TRANSACTION
  // ============================================================

  Future<void> _afterTransaction({
    required String action,
    required String hash,
  }) async {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 20),
        behavior: SnackBarBehavior.floating,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$action berhasil dikonfirmasi!',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Transaction Hash:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            SelectableText(
              hash,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'SALIN HASH',
          onPressed: () {
            Clipboard.setData(
              ClipboardData(text: hash),
            );
          },
        ),
      ),
    );

// Refresh data blockchain setelah transaksi berhasil.
    unawaited(_refreshBlockchainData());
  }

  // ============================================================
  // TRANSACTION GUARD
  // ============================================================

  bool _canStartTransaction() {
    if (_transactionInProgress) {
      _showMessage(
        'Tunggu transaksi sebelumnya selesai.',
      );
      return false;
    }

    return true;
  }

  void _startTransaction() {
    setState(() {
      _transactionInProgress = true;
      _loading = true;
    });
  }

  void _finishTransaction() {
    if (!mounted) return;

    setState(() {
      _transactionInProgress = false;
      _loading = _refreshInProgress;
    });
  }
  // ============================================================
  // ADD LOAN
  // ============================================================

  Future<void> _addLoan(
    String namaAlat,
    String namaPeminjam,
  ) async {
    if (_demoMode) {
      final nextId = _loans.isEmpty
          ? 0
          : _loans.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;

      setState(() {
        _loans.insert(
          0,
          LoanModel(
            id: nextId,
            namaAlat: namaAlat,
            namaPeminjam: namaPeminjam,
            waktuPinjam: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            waktuKembali: 0,
            statusKembali: false,
            dibatalkan: false,
            walletPeminjam: 'DEMO WALLET',
          ),
        );

        _activities.insert(
          0,
          '$namaPeminjam meminjam $namaAlat (demo)',
        );
      });

      _showMessage('Peminjaman berhasil (mode demo).');
      return;
    }

    if (!_blockchain.isWalletConnected) {
      _showMessage(
        'Hubungkan wallet terlebih dahulu melalui Settings.',
      );
      return;
    }

    if (!_canStartTransaction()) return;

    _startTransaction();

    try {
      final hash = await _blockchain.pinjamAlat(
        namaAlat,
        namaPeminjam,
      );

      await _afterTransaction(
        action: 'Peminjaman',
        hash: hash,
      );
    } on TimeoutException catch (e) {
      _showMessage(
        'Transaksi masih menunggu konfirmasi. '
        '${e.message ?? ""}',
      );
    } catch (e) {
      _showMessage('Transaksi peminjaman gagal: $e');
    } finally {
      _finishTransaction();
    }
  }

  // ============================================================
  // RETURN LOAN
  // ============================================================

  Future<void> _returnLoan(int id) async {
    if (_demoMode) {
      final index = _loans.indexWhere((e) => e.id == id);

      if (index == -1) return;

      final loan = _loans[index];

      if (!loan.sedangDipinjam) return;

      setState(() {
        _loans[index] = LoanModel(
          id: loan.id,
          namaAlat: loan.namaAlat,
          namaPeminjam: loan.namaPeminjam,
          waktuPinjam: loan.waktuPinjam,
          waktuKembali: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          statusKembali: true,
          dibatalkan: false,
          walletPeminjam: loan.walletPeminjam,
        );

        _activities.insert(
          0,
          '${loan.namaPeminjam} mengembalikan ${loan.namaAlat} (demo)',
        );
      });

      return;
    }

    if (!_blockchain.isWalletConnected) {
      _showMessage('Wallet belum tersedia.');
      return;
    }

    final index = _loans.indexWhere((e) => e.id == id);

    if (index == -1) {
      _showMessage('Data peminjaman tidak ditemukan.');
      return;
    }

    final loan = _loans[index];

    if (!loan.sedangDipinjam) {
      _showMessage('Peminjaman sudah tidak aktif.');
      return;
    }

    if (!_isCurrentWalletOwner(loan)) {
      _showMessage(
        'Wallet ini bukan pemilik peminjaman tersebut.',
      );
      return;
    }

    if (!_canStartTransaction()) return;

    _startTransaction();

    try {
      final hash = await _blockchain.kembalikanAlat(id);

      await _afterTransaction(
        action: 'Pengembalian',
        hash: hash,
      );
    } on TimeoutException catch (e) {
      _showMessage(
        'Transaksi masih menunggu konfirmasi. ${e.message ?? ""}',
      );
    } catch (e) {
      _showMessage('Transaksi pengembalian gagal: $e');
    } finally {
      _finishTransaction();
    }
  }


  // ============================================================
  // CANCEL LOAN
  // ============================================================

  Future<void> _cancelLoan(int id) async {
    if (_demoMode) {
      final index = _loans.indexWhere((e) => e.id == id);

      if (index == -1) return;

      final loan = _loans[index];

      if (!loan.sedangDipinjam) return;

      setState(() {
        _loans[index] = LoanModel(
          id: loan.id,
          namaAlat: loan.namaAlat,
          namaPeminjam: loan.namaPeminjam,
          waktuPinjam: loan.waktuPinjam,
          waktuKembali: loan.waktuKembali,
          statusKembali: false,
          dibatalkan: true,
          walletPeminjam: loan.walletPeminjam,
        );

        _activities.insert(
          0,
          '${loan.namaPeminjam} membatalkan peminjaman ${loan.namaAlat} (demo)',
        );
      });

      return;
    }

    if (!_blockchain.isWalletConnected) {
      _showMessage('Hubungkan wallet terlebih dahulu.');
      return;
    }

    final index = _loans.indexWhere((e) => e.id == id);

    if (index == -1) {
      _showMessage('Data peminjaman tidak ditemukan.');
      return;
    }

    final loan = _loans[index];

    if (!loan.sedangDipinjam) {
      _showMessage('Peminjaman sudah tidak aktif.');
      return;
    }

    if (!_isCurrentWalletOwner(loan)) {
      _showMessage(
        'Wallet ini bukan pemilik peminjaman tersebut.',
      );
      return;
    }

    if (!_canStartTransaction()) return;

    _startTransaction();

    try {
      final hash = await _blockchain.batalkanPeminjaman(id);

      await _afterTransaction(
        action: 'Pembatalan',
        hash: hash,
      );
    } on TimeoutException catch (e) {
      _showMessage(
        'Transaksi masih menunggu konfirmasi. ${e.message ?? ""}',
      );
    } catch (e) {
      _showMessage('Transaksi pembatalan gagal: $e');
    } finally {
      _finishTransaction();
    }
  }

  // ============================================================
  // BORROW DIALOG
  // ============================================================
  void _showBorrowDialog() {
    if (_transactionInProgress) {
      _showMessage(
        'Tunggu transaksi sebelumnya selesai.',
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (_) => BorrowDialog(
        onBorrow: _addLoan,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        loans: _loans,
        onBorrow: _showBorrowDialog,
        onReturn: _returnLoan,
        onCancel: _cancelLoan,
        onOpenLoans: () {
          setState(() {
            _selectedIndex = 1;
          });
        },
        isLoading: _loading,
        loadError: _loadError,
        isDemoMode: _demoMode,
        onRefresh: _refreshBlockchainData,
      ),
      LoanScreen(
        loans: _loans,
        onBorrow: _showBorrowDialog,
        onReturn: _returnLoan,
        onCancel: _cancelLoan,
        isDemoMode: _demoMode,
        currentWalletAddress: _blockchain.walletAddress,
      ),
      ActivityScreen(
        activities: _activities,
      ),
      SettingsScreen(
        themeMode: widget.themeMode,
        onToggleTheme: widget.onToggleTheme,
        blockchain: _blockchain,
        walletInitializing: _walletInitializing,
        walletError: _walletError,
        walletBalance: _walletBalance,
        balanceLoading: _balanceLoading,
        balanceError: _balanceError,
        onRefreshBalance: _refreshWalletBalance,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNav(
        selectedIndex: _selectedIndex,
        onChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
