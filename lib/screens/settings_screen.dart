import 'package:flutter/material.dart';


import '../config/blockchain_config.dart';
import '../services/blockchain_service.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<bool> onToggleTheme;
  final BlockchainService blockchain;

  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
    required this.blockchain,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _privateKeyController =
      TextEditingController();

  bool _obscureKey = true;
  bool _connecting = false;
  String? _walletAddress;
  String? _balance;
  String? _walletError;

  bool get _isConnected => widget.blockchain.isWalletConnected;

  @override
  void dispose() {
    _privateKeyController.dispose();
    super.dispose();
  }

  Future<void> _connectWallet() async {
    if (_privateKeyController.text.trim().isEmpty) {
      _showMessage('Masukkan private key terlebih dahulu.');
      return;
    }

    setState(() {
      _connecting = true;
      _walletError = null;
    });

    try {
      final address = await widget.blockchain.connectWallet(
        _privateKeyController.text.trim(),
      );

      // Bersihkan input setelah proses koneksi.
      _privateKeyController.clear();

      final balance = await widget.blockchain.getWalletBalance();

      if (!mounted) return;

      setState(() {
        _walletAddress = address;
        _balance =
            (balance.getInWei.toDouble() / 1e18).toStringAsFixed(6)
            ;
        _connecting = false;
      });

      _showMessage('Wallet berhasil dihubungkan.');
    } catch (error) {
      widget.blockchain.disconnectWallet();

      if (!mounted) return;

      setState(() {
        _connecting = false;
        _walletAddress = null;
        _balance = null;
        _walletError = error.toString();
      });

      _showMessage('Gagal menghubungkan wallet.');
    }
  }

  Future<void> _refreshBalance() async {
    try {
      final balance = await widget.blockchain.getWalletBalance();

      if (!mounted) return;

      setState(() {
        _balance = 
            (balance.getInWei.toDouble() / 1e18).toStringAsFixed(6);
            
      });
    } catch (error) {
      _showMessage('Gagal mengambil saldo: $error');
    }
  }

  void _disconnectWallet() {
    widget.blockchain.disconnectWallet();

    setState(() {
      _walletAddress = null;
      _balance = null;
      _walletError = null;
    });

    _showMessage('Wallet berhasil diputuskan.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _sectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.hintColor,
        letterSpacing: 1.2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = widget.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // TAMPILAN
          _sectionTitle('TAMPILAN', theme),
          const SizedBox(height: 10),

          Card(
            child: SwitchListTile(
              value: isDark,
              onChanged: widget.onToggleTheme,
              secondary: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Dark Mode'),
              subtitle: const Text('Ubah tampilan aplikasi'),
            ),
          ),

          const SizedBox(height: 24),

          // WALLET
          _sectionTitle('WALLET CONNECTION', theme),
          const SizedBox(height: 10),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        color: theme.colorScheme.primary,
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Ethereum Wallet',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _isConnected
                              ? Colors.green.withValues(alpha: 0.12)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _isConnected ? 'Connected' : 'Disconnected',
                          style: TextStyle(
                            color: _isConnected
                                ? Colors.green
                                : theme.hintColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  if (!_isConnected) ...[
                    const Text(
                      'Private Key',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: _privateKeyController,
                      obscureText: _obscureKey,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        hintText: 'Masukkan private key',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureKey = !_obscureKey;
                            });
                          },
                          icon: Icon(
                            _obscureKey
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Gunakan wallet khusus Ethereum Sepolia. '
                      'Jangan gunakan wallet pribadi.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _connecting ? null : _connectWallet,
                        child: _connecting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Connect Wallet'),
                      ),
                    ),

                    if (_walletError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _walletError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ] else ...[
                    const Text(
                      'Wallet Address',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),

                    SelectableText(
                      _walletAddress ?? '',
                      style: theme.textTheme.bodySmall,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Sepolia Balance',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_balance ?? '-'} ETH',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _refreshBalance,
                          tooltip: 'Refresh balance',
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _disconnectWallet,
                        icon: const Icon(Icons.logout),
                        label: const Text('Disconnect Wallet'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // BLOCKCHAIN CONFIGURATION
          _sectionTitle('BLOCKCHAIN', theme),
          const SizedBox(height: 10),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Network'),
                  const SizedBox(height: 4),
                  Text(BlockchainConfig.networkName),

                  const SizedBox(height: 16),

                  const Text('Chain ID'),
                  const SizedBox(height: 4),
                  Text('${BlockchainConfig.chainId}'),

                  const SizedBox(height: 16),

                  const Text('Contract Address'),
                  const SizedBox(height: 4),
                  SelectableText(
                    BlockchainConfig.contractAddress,
                  ),

                  const SizedBox(height: 16),

                  const Text('RPC Status'),
                  const SizedBox(height: 4),
                  Text(
                    BlockchainConfig.isRpcConfigured
                        ? 'RPC telah dikonfigurasi'
                        : 'Belum dikonfigurasi',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // APP INFORMATION
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.memory,
                  color: theme.colorScheme.primary,
                  size: 34,
                ),
                const SizedBox(height: 8),
                Text(
                  'LabIotLogbook',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Version 1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
