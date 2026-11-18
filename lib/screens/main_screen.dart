import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:reown_appkit/reown_appkit.dart';


import '../config/blockchain_config.dart';

import '../models/loan_model.dart';

import '../services/blockchain_service.dart';

import '../widgets/bottom_nav.dart';

import '../widgets/borrow_dialog.dart';

import 'activity_screen.dart';

import 'dashboard_screen.dart';

import 'loan_screen.dart';

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

  final BlockchainService _blockchain = BlockchainService();

  final List<StreamSubscription<dynamic>> _eventSubscriptions = [];

  late final ReownAppKitModal _appKitModal;
  bool _appKitReady = false;



  bool _walletInitializing = true;

  String? _walletError;

  String? _walletBalance;

  bool _balanceLoading = false;

  String? _balanceError;



  int _selectedIndex = 0;

  bool _loading = false;

  bool _refreshInProgress = false;

  bool _transactionInProgress = false;



  String? _loadError;

  List<LoanModel> _loans = [];

  List<String> _activities = [];



  bool get _demoMode => !BlockchainConfig.isRpcConfigured;



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



  @override
  void initState() {
    super.initState();

    if (_demoMode) {
      _loans = List.of(_demoLoans);
      _activities = List.of(_demoActivities);
      _walletInitializing = false;
      return;
    }

    ReownAppKitModalNetworks.addSupportedNetworks('eip155', [
      ReownAppKitModalNetworkInfo(
        name: BlockchainConfig.networkName,
        chainId: 'eip155:${BlockchainConfig.chainId}',
        currency: 'ETH',
        rpcUrl: BlockchainConfig.rpcUrl,
        explorerUrl: 'https://sepolia.etherscan.io',
        isTestNetwork: true,
      ),
    ]);

    _appKitModal = ReownAppKitModal(
      context: context,
      projectId: BlockchainConfig.reownProjectId,
      metadata: const PairingMetadata(
        name: 'LabIoTLogbook',
        description: 'Aplikasi peminjaman alat laboratorium berbasis blockchain',
        url: 'https://reown.com/',
        icons: ['https://reown.com/logo.png'],
        redirect: Redirect(
          native: 'labiotlogbook://',
          universal: 'https://reown.com/',
        ),
      ),
    );

    _appKitModal.addListener(_handleAppKitChange);
    unawaited(_initializeBlockchainAndWallet());
  }

  Future<void> _initializeBlockchainAndWallet() async {
    try {
      await _blockchain.initialize();
      await _appKitModal.init();
      _appKitReady = true;

      if (_appKitModal.isConnected) {
        await _syncWalletFromAppKit();
      }

      if (!mounted) return;
      setState(() {
        _walletInitializing = false;
      });

      await _refreshBlockchainData();
      await _subscribeToContractEvents();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _walletError = e.toString();
        _walletInitializing = false;
      });
      _showMessage('Gagal menginisialisasi blockchain: $e');
    }
  }

  Future<void> _syncWalletFromAppKit() async {
    if (!_appKitReady) return;

    try {
      final session = _appKitModal.session;
      if (!_appKitModal.isConnected || session == null) {
        _blockchain.disconnectWallet();
        if (!mounted) return;
        setState(() {
          _walletBalance = null;
          _balanceError = null;
          _walletError = null;
        });
        return;
      }

      final address = session.getAddress('eip155');
      if (address == null || address.isEmpty) {
        throw StateError('Alamat wallet tidak ditemukan dari sesi Reown.');
      }

      final expectedChain = 'eip155:${BlockchainConfig.chainId}';
      if (session.chainId != expectedChain) {
        _blockchain.disconnectWallet();
        if (!mounted) return;
        setState(() {
          _walletBalance = null;
          _walletError =
              'Jaringan wallet tidak sesuai. Pilih ${BlockchainConfig.networkName}.';
        });
        return;
      }

      await _blockchain.connectWallet(address, _appKitModal);
      if (!mounted) return;
      setState(() {
        _walletError = null;
      });
      await _loadWalletBalance();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _walletError = e.toString();
      });
    }
  }

  void _handleAppKitChange() {
    unawaited(_syncWalletFromAppKit());
  }

  Future<void> _connectWallet() async {
    if (!_appKitReady) {
      _showMessage('Koneksi wallet belum siap. Coba beberapa saat lagi.');
      return;
    }
    try {
      await _appKitModal.openModalView();
    } catch (e) {
      _showMessage('Gagal membuka koneksi wallet: $e');
    }
  }

  Future<void> _disconnectWallet() async {
    try {
      await _appKitModal.disconnect();
      _blockchain.disconnectWallet();
      if (!mounted) return;
      setState(() {
        _walletBalance = null;
        _balanceError = null;
        _walletError = null;
      });
      _showMessage('Wallet berhasil diputus.');
    } catch (e) {
      _showMessage('Gagal memutus wallet: $e');
    }
  }

  Future<void> _subscribeToContractEvents() async {

    const eventNames = [

      'AlatDipinjam',

      'AlatDikembalikan',

      'PeminjamanDibatalkan',

    ];



    for (final eventName in eventNames) {

      try {

        final stream = await _blockchain.watchEvent(eventName);

        final subscription = stream.listen(

          (_) {

            // Event baru masuk: muat ulang data agar Dashboard dan Activity

            // ikut diperbarui tanpa perlu hot restart.

            unawaited(_refreshBlockchainData());

          },

          onError: (Object error) {

            if (mounted) {

              _showMessage('Listener $eventName mengalami kendala: $error');

            }

          },

        );

        _eventSubscriptions.add(subscription);

      } catch (e) {

        if (mounted) {

          _showMessage('Gagal memasang listener $eventName: $e');

        }

      }

    }

  }



  Future<void> _loadWalletBalance() async {

    if (_demoMode || !_blockchain.isWalletConnected) return;



    if (mounted) {

      setState(() {

        _balanceLoading = true;

        _balanceError = null;

      });

    }



    try {

      final balance = await _blockchain.getWalletBalance();

        final wei = balance.getInWei;

        final formatted = (wei / BigInt.from(10).pow(18))

          .toStringAsFixed(6);



      if (!mounted) return;

      setState(() {

        _walletBalance = formatted;

        _balanceError = null;

      });

    } catch (e) {

      if (!mounted) return;

      setState(() {

        _balanceError = e.toString();

      });

    } finally {

      if (mounted) {

        setState(() {

          _balanceLoading = false;

        });

      }

    }

  }



  void _refreshWalletBalance() {

    unawaited(_loadWalletBalance());

  }



  @override

  void dispose() {

    for (final subscription in _eventSubscriptions) {

      unawaited(subscription.cancel());

    }

    unawaited(_blockchain.dispose());

    if (!_demoMode) {
      _appKitModal.removeListener(_handleAppKitChange);
      unawaited(_appKitModal.dispose());
    }

    super.dispose();

  }



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



  void _showMessage(String message) {

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Text(message),

        behavior: SnackBarBehavior.floating,

      ),

    );

  }



  bool _isCurrentWalletOwner(LoanModel loan) {

    final address = _blockchain.walletAddress;

    if (address == null) return false;

    return address.toLowerCase() == loan.walletPeminjam.toLowerCase();

  }



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

              style: const TextStyle(fontWeight: FontWeight.bold),

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

            Clipboard.setData(ClipboardData(text: hash));

          },

        ),

      ),

    );



    // Refresh setelah transaksi dikonfirmasi. Listener event juga akan

    // memperbarui data, sedangkan guard mencegah refresh bertumpuk.

    unawaited(_refreshBlockchainData());

    unawaited(_loadWalletBalance());

  }



  bool _canStartTransaction() {

    if (_transactionInProgress) {

      _showMessage('Tunggu transaksi sebelumnya selesai.');

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

      _showMessage('Wallet belum terhubung. Hubungkan wallet melalui menu Settings.');

      return;

    }

    if (!_canStartTransaction()) return;



    _startTransaction();

    try {

      final hash = await _blockchain.pinjamAlat(namaAlat, namaPeminjam);

      await _afterTransaction(action: 'Peminjaman', hash: hash);

    } on TimeoutException catch (e) {

      _showMessage(

        'Transaksi masih menunggu konfirmasi. ${e.message ?? ''}',

      );

    } catch (e) {

      _showMessage('Transaksi peminjaman gagal: $e');

    } finally {

      _finishTransaction();

    }

  }



  Future<void> _returnLoan(int id) async {

    final index = _loans.indexWhere((loan) => loan.id == id);

    if (index == -1) {

      _showMessage('Data peminjaman tidak ditemukan.');

      return;

    }



    final loan = _loans[index];

    if (!loan.sedangDipinjam) {

      _showMessage('Peminjaman sudah tidak aktif.');

      return;

    }



    if (_demoMode) {

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

      _showMessage('Pengembalian berhasil (mode demo).');

      return;

    }



    if (!_blockchain.isWalletConnected) {

      _showMessage('Wallet belum tersedia.');

      return;

    }

    if (!_isCurrentWalletOwner(loan)) {

      _showMessage('Wallet ini bukan pemilik peminjaman tersebut.');

      return;

    }

    if (!_canStartTransaction()) return;



    _startTransaction();

    try {

      final hash = await _blockchain.kembalikanAlat(id);

      await _afterTransaction(action: 'Pengembalian', hash: hash);

    } on TimeoutException catch (e) {

      _showMessage(

        'Transaksi masih menunggu konfirmasi. ${e.message ?? ''}',

      );

    } catch (e) {

      _showMessage('Transaksi pengembalian gagal: $e');

    } finally {

      _finishTransaction();

    }

  }



  Future<void> _cancelLoan(int id) async {

    final index = _loans.indexWhere((loan) => loan.id == id);

    if (index == -1) {

      _showMessage('Data peminjaman tidak ditemukan.');

      return;

    }



    final loan = _loans[index];

    if (!loan.sedangDipinjam) {

      _showMessage('Peminjaman sudah tidak aktif.');

      return;

    }



    if (_demoMode) {

      setState(() {

        _loans[index] = LoanModel(

          id: loan.id,

          namaAlat: loan.namaAlat,

          namaPeminjam: loan.namaPeminjam,

          waktuPinjam: loan.waktuPinjam,

          waktuKembali: 0,

          statusKembali: false,

          dibatalkan: true,

          walletPeminjam: loan.walletPeminjam,

        );

        _activities.insert(

          0,

          '${loan.namaPeminjam} membatalkan peminjaman ${loan.namaAlat} (demo)',

        );

      });

      _showMessage('Peminjaman berhasil dibatalkan (mode demo).');

      return;

    }



    if (!_blockchain.isWalletConnected) {

      _showMessage('Wallet belum tersedia.');

      return;

    }

    if (!_isCurrentWalletOwner(loan)) {

      _showMessage('Wallet ini bukan pemilik peminjaman tersebut.');

      return;

    }

    if (!_canStartTransaction()) return;



    _startTransaction();

    try {

      final hash = await _blockchain.batalkanPeminjaman(id);

      await _afterTransaction(action: 'Pembatalan peminjaman', hash: hash);

    } on TimeoutException catch (e) {

      _showMessage(

        'Transaksi masih menunggu konfirmasi. ${e.message ?? ''}',

      );

    } catch (e) {

      _showMessage('Transaksi pembatalan gagal: $e');

    } finally {

      _finishTransaction();

    }

  }



  void _showBorrowDialog() {

    if (_transactionInProgress) {

      _showMessage('Tunggu transaksi sebelumnya selesai.');

      return;

    }



    showDialog<void>(

      context: context,

      builder: (_) => BorrowDialog(onBorrow: _addLoan),

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

      ActivityScreen(activities: _activities),

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
        onConnectWallet: _connectWallet,
        onDisconnectWallet: _disconnectWallet,

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
