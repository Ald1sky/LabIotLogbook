
import 'package:flutter/material.dart';

import '../config/blockchain_config.dart';
import '../services/blockchain_service.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeMode themeMode;
  final ValueChanged<bool> onToggleTheme;
  final BlockchainService blockchain;

  final bool walletInitializing;
  final String? walletError;
  final String? walletBalance;
  final bool balanceLoading;
  final String? balanceError;
  final VoidCallback onRefreshBalance;

  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
    required this.blockchain,
    required this.walletInitializing,
    required this.walletError,
    required this.walletBalance,
    required this.balanceLoading,
    required this.balanceError,
    required this.onRefreshBalance,
  });

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
    final isDark = themeMode == ThemeMode.dark;
    final isConnected = blockchain.isWalletConnected;

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
              onChanged: onToggleTheme,
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
                          color: isConnected
                              ? Colors.green.withValues(alpha: 0.12)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          walletInitializing
                              ? 'Loading'
                              : isConnected
                                  ? 'Loaded'
                                  : 'Unavailable',
                          style: TextStyle(
                            color: isConnected
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

                  if (walletInitializing) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                    const Text('Memuat wallet dari environment...'),
                  ] else if (isConnected) ...[
                    const Text(
                      'Wallet Address',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    SelectableText(
                      blockchain.walletAddress ?? '-',
                      style: theme.textTheme.bodySmall,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Sepolia Balance',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            balanceLoading
                                ? 'Memuat saldo...'
                                : '${walletBalance ?? '-'} ETH',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: balanceLoading
                              ? null
                              : onRefreshBalance,
                          tooltip: 'Refresh balance',
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),

                    if (balanceError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Gagal membaca saldo: $balanceError',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    Text(
                      'Wallet dimuat dari environment configuration.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ] else ...[
                    Text(
                      walletError ?? 'Wallet belum tersedia.',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Periksa PRIVATE_KEY pada konfigurasi environment.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
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

                  const Text('RPC Configuration'),
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
