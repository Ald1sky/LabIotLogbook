
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

  bool _loading = false;
  String? _loadError;

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

  final List<String> _activities = [
    'Sensor DHT11 telah dikembalikan (data demo)',
    'Arduino Uno telah dipinjam (data demo)',
  ];

  List<LoanModel> _loans = [];

  bool get _demoMode => !BlockchainConfig.isRpcConfigured;

  @override
  void initState() {
    super.initState();

    _loans = List.of(_demoLoans);
    _initializeBlockchain();
  }

  @override
  void dispose() {
    _blockchain.dispose();
    super.dispose();
  }

  // INITIALISASI BLOCKCHAIN DAN WALLET
  Future<void> _initializeBlockchain() async {
    try {
      await _blockchain.initializeWallet();
    } catch (error) {
      if (mounted) {
        setState(() {
          _walletError = error.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _walletInitializing = false;
        });
      }
    }

    if (!mounted) return;

    if (_blockchain.isWalletConnected && !_demoMode) {
      await _refreshWalletBalance();
    }

    if (!_demoMode && mounted) {
      await _refreshBlockchainData();
    }
  }

  // REFRESH DATA BLOCKCHAIN
  Future<void> _refreshBlockchainData() async {
    if (_demoMode || _loading) return;

    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final result = await _blockchain.getAllLogs();

      if (!mounted) return;

      setState(() {
        _loans = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadError = error.toString();
      });
    }
  }

  // REFRESH WALLET BALANCE
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

  // SNACKBAR
  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _setLoading(bool value) {
    if (!mounted) return;

    setState(() {
      _loading = value;
    });
  }

  void _showTransactionHash(String action, String hash) {
    _showMessage(
      '$action berhasil dikirim. Hash: $hash',
    );
  }

  // VALIDASI PEMILIK WALLET
  bool _isCurrentWalletOwner(LoanModel loan) {
    final connectedAddress = _blockchain.walletAddress;

    if (connectedAddress == null) return false;

    return connectedAddress.toLowerCase() ==
        loan.walletPeminjam.toLowerCase();
  }

  // PEMINJAMAN
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
            waktuPinjam:
                DateTime.now().millisecondsSinceEpoch ~/ 1000,
            waktuKembali: 0,
            statusKembali: false,
            dibatalkan: false,
            walletPeminjam: 'DEMO WALLET',
          ),
        );

        _activities.insert(
          0,
          '$namaAlat dipinjam oleh $namaPeminjam (demo)',
        );
      });

      return;
    }

    if (!_blockchain.isWalletConnected) {
      _showMessage('Wallet belum tersedia. Periksa konfigurasi .env.');
      return;
    }

    if (_loading) return;

    _setLoading(true);

    try {
      final hash = await _blockchain.pinjamAlat(
        namaAlat,
        namaPeminjam,
      );

      _showTransactionHash('Peminjaman', hash);
    } catch (error) {
      _showMessage('Gagal mengirim transaksi peminjaman: $error');
    } finally {
      _setLoading(false);
    }
  }

  // PENGEMBALIAN
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
          waktuKembali:
              DateTime.now().millisecondsSinceEpoch ~/ 1000,
          statusKembali: true,
          dibatalkan: false,
          walletPeminjam: loan.walletPeminjam,
        );

        _activities.insert(
          0,
          '${loan.namaAlat} dikembalikan (demo)',
        );
      });

      return;
    }

    if (!_blockchain.isWalletConnected) {
      _showMessage('Wallet belum tersedia.');
      return;
    }

    final loan = _loans.where((e) => e.id == id).firstOrNull;

    if (loan == null || !loan.sedangDipinjam) {
      _showMessage('Data peminjaman tidak valid.');
      return;
    }

    if (!_isCurrentWalletOwner(loan)) {
      _showMessage('Wallet ini bukan pemilik peminjaman tersebut.');
      return;
    }

    if (_loading) return;

    _setLoading(true);

    try {
      final hash = await _blockchain.kembalikanAlat(id);
      _showTransactionHash('Pengembalian', hash);
    } catch (error) {
      _showMessage('Gagal mengirim transaksi pengembalian: $error');
    } finally {
      _setLoading(false);
    }
  }

  // PEMBATALAN
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
          'Peminjaman ${loan.namaAlat} dibatalkan (demo)',
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
      _showMessage('Wallet ini bukan pemilik peminjaman tersebut.');
      return;
    }

    if (_loading) return;

    _setLoading(true);

    try {
      final hash = await _blockchain.batalkanPeminjaman(id);
      _showTransactionHash('Pembatalan', hash);
    } catch (error) {
      _showMessage('Gagal mengirim transaksi pembatalan: $error');
    } finally {
      _setLoading(false);
    }
  }

  // DIALOG PEMINJAMAN
  void _showBorrowDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => BorrowDialog(
        onBorrow: _addLoan,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        loans: _loans,
        onBorrow: _showBorrowDialog,
        onReturn: _returnLoan,
        onCancel: _cancelLoan,
        onOpenLoans: () => setState(() => _selectedIndex = 1),
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
