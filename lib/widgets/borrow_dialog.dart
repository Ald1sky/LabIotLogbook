import 'package:flutter/material.dart';

class BorrowDialog extends StatefulWidget {
  final void Function(String namaAlat, String namaPeminjam) onBorrow;

  const BorrowDialog({super.key, required this.onBorrow});

  @override
  State<BorrowDialog> createState() => _BorrowDialogState();
}

class _BorrowDialogState extends State<BorrowDialog> {
  final _alatController = TextEditingController();
  final _peminjamController = TextEditingController();

  @override
  void dispose() {
    _alatController.dispose();
    _peminjamController.dispose();
    super.dispose();
  }

  void _submit() {
    final alat = _alatController.text.trim();
    final peminjam = _peminjamController.text.trim();
    if (alat.isEmpty || peminjam.isEmpty) return;
    widget.onBorrow(alat, peminjam);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pinjam Alat'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _alatController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nama alat',
              hintText: 'Contoh: Arduino Uno',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _peminjamController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nama peminjam',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Lanjutkan'),
        ),
      ],
    );
  }
}
