import 'package:flutter/material.dart';
import '../models/loan_model.dart';
import '../widgets/loan_card.dart';

class DashboardScreen extends StatelessWidget {
  final List<LoanModel> loans;
  final VoidCallback onBorrow;
  final ValueChanged<int> onReturn;
  final ValueChanged<int> onCancel;
  final VoidCallback onOpenLoans;
  final bool isLoading;
  final String? loadError;
  final bool isDemoMode;
  final VoidCallback onRefresh;

  const DashboardScreen({
    super.key,
    required this.loans,
    required this.onBorrow,
    required this.onReturn,
    required this.onCancel,
    required this.onOpenLoans,
    this.isLoading = false,
    this.loadError,
    this.isDemoMode = true,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = loans.where((e) => e.sedangDipinjam).length;
    final returned = loans.where((e) => e.statusKembali).length;
    final cancelled = loans.where((e) => e.dibatalkan).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lab IoT Logbook',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang data',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Laboratory Equipment',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 4),
          Text(
            'Dashboard',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading) const LinearProgressIndicator(),
          if (loadError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Gagal membaca blockchain: $loadError',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total Log',
                  value: '${loans.length}',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Dipinjam',
                  value: '$active',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Dikembalikan',
                  value: '$returned',
                  icon: Icons.assignment_turned_in_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Dibatalkan',
                  value: '$cancelled',
                  icon: Icons.cancel_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Peminjaman Terbaru',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onOpenLoans,
                child: const Text('Lihat semua'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (loans.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Belum ada data peminjaman.')),
            )
          else
            ...loans
                .take(3)
                .map(
                  (loan) => LoanCard(
                    loan: loan,
                    onReturn: loan.sedangDipinjam
                        ? () => onReturn(loan.id)
                        : null,
                    onCancel: loan.sedangDipinjam
                        ? () => onCancel(loan.id)
                        : null,
                  ),
                ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: onBorrow,
              icon: const Icon(Icons.add),
              label: const Text('Pinjam Alat'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
