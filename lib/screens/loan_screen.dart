
import 'package:flutter/material.dart';
import '../models/loan_model.dart';
import '../widgets/loan_card.dart';

class LoanScreen extends StatefulWidget {
  final List<LoanModel> loans;
  final VoidCallback onBorrow;
  final ValueChanged<int> onReturn;
  final ValueChanged<int> onCancel;
  final bool isDemoMode;
  final String? currentWalletAddress;

  const LoanScreen({
    super.key,
    required this.loans,
    required this.onBorrow,
    required this.onReturn,
    required this.onCancel,
    this.isDemoMode = true,
    this.currentWalletAddress,
  });

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  String _filter = 'Semua';

  List<LoanModel> get _filteredLoans {
    return widget.loans.where((loan) {
      switch (_filter) {
        case 'Dipinjam':
          return loan.sedangDipinjam;

        case 'Dikembalikan':
          return loan.statusKembali;

        case 'Dibatalkan':
          return loan.dibatalkan;

        case 'Milik Saya':
          final address = widget.currentWalletAddress;

          if (address == null || address.isEmpty) {
            return false;
          }

          return loan.walletPeminjam.toLowerCase() ==
              address.toLowerCase();

        default:
          return true;
      }
    }).toList();
  }

  Widget _buildEmptyMessage() {
    if (_filter == 'Milik Saya' &&
        (widget.currentWalletAddress == null ||
            widget.currentWalletAddress!.isEmpty)) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 12),
              Text(
                'Wallet belum terhubung.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Hubungkan wallet melalui Settings '
                'untuk melihat peminjaman milik Anda.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return const Center(
      child: Text('Tidak ada data peminjaman.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLoans;

    const filters = [
      'Semua',
      'Dipinjam',
      'Dikembalikan',
      'Dibatalkan',
      'Milik Saya',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Data Peminjaman',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),   
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Row(
              children: filters.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(item),
                    selected: _filter == item,
                    onSelected: (_) {
                      setState(() {
                        _filter = item;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyMessage()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final loan = filtered[index];

                      return LoanCard(
                        loan: loan,
                        onReturn:
                            widget.isDemoMode &&
                                    loan.sedangDipinjam
                                ? () => widget.onReturn(loan.id)
                                : null,
                        onCancel:
                            widget.isDemoMode &&
                                    loan.sedangDipinjam
                                ? () => widget.onCancel(loan.id)
                                : null,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onBorrow,
        child: const Icon(Icons.add),
      ),
    );
  }
}
