import 'package:flutter/material.dart';
import '../models/loan_model.dart';

class LoanCard extends StatelessWidget {
  final LoanModel loan;
  final VoidCallback? onReturn;
  final VoidCallback? onCancel;

  const LoanCard({
    super.key,
    required this.loan,
    this.onReturn,
    this.onCancel,
  });

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = loan.dibatalkan
        ? 'Dibatalkan'
        : loan.statusKembali
            ? 'Dikembalikan'
            : 'Sedang dipinjam';

    final statusColor = loan.dibatalkan
        ? Colors.red
        : loan.statusKembali
            ? Colors.green
            : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.10),
                  child: Icon(
                    Icons.memory,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.namaAlat,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Peminjam: ${loan.namaPeminjam}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '#${loan.id}',
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14),
                const SizedBox(width: 6),
                Text(
                  _date(loan.tanggalPinjam),
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (onReturn != null || onCancel != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onCancel != null)
                    TextButton(
                      onPressed: onCancel,
                      child: const Text('Batalkan'),
                    ),
                  if (onReturn != null)
                    FilledButton.tonal(
                      onPressed: onReturn,
                      child: const Text('Kembalikan'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
