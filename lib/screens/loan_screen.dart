import 'package:flutter/material.dart';
import '../models/loan_model.dart';
import '../widgets/loan_card.dart';

class LoanScreen extends StatefulWidget {
  final List<LoanModel> loans;
  final VoidCallback onBorrow;
  final ValueChanged<int> onReturn;
  final ValueChanged<int> onCancel;
  final bool isDemoMode;

  const LoanScreen({
    super.key,
    required this.loans,
    required this.onBorrow,
    required this.onReturn,
    required this.onCancel,
    this.isDemoMode = true,
  });

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  String _filter = 'Semua';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.loans.where((loan) {
      switch (_filter) {
        case 'Dipinjam':
          return loan.sedangDipinjam;
        case 'Dikembalikan':
          return loan.statusKembali;
        case 'Dibatalkan':
          return loan.dibatalkan;
        default:
          return true;
      }
    }).toList();

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['Semua', 'Dipinjam', 'Dikembalikan', 'Dibatalkan']
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(item),
                        selected: _filter == item,
                        onSelected: (_) => setState(() => _filter = item),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Tidak ada data peminjaman.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final loan = filtered[index];
                      return LoanCard(
                        loan: loan,
                        onReturn: widget.isDemoMode && loan.sedangDipinjam
                            ? () => widget.onReturn(loan.id)
                            : null,
                        onCancel: widget.isDemoMode && loan.sedangDipinjam
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
