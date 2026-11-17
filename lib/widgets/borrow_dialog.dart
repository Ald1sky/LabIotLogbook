
import 'package:flutter/material.dart';

class BorrowDialog extends StatefulWidget {
  final Future<void> Function(
    String namaAlat,
    String namaPeminjam,
  ) onBorrow;

  const BorrowDialog({
    super.key,
    required this.onBorrow,
  });

  @override
  State<BorrowDialog> createState() => _BorrowDialogState();
}

class _BorrowDialogState extends State<BorrowDialog> {
  final _alatController = TextEditingController();
  final _peminjamController = TextEditingController();

  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _alatController.dispose();
    _peminjamController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final alat = _alatController.text.trim();
    final peminjam = _peminjamController.text.trim();

    if (alat.isEmpty || peminjam.isEmpty) {
      setState(() {
        _errorMessage = 'Nama alat dan peminjam wajib diisi.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await widget.onBorrow(alat, peminjam);

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Peminjaman gagal: $e';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: AlertDialog(
        title: const Text('Pinjam Alat'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _alatController,
                enabled: !_submitting,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama alat',
                  hintText: 'Contoh: Arduino Uno',
                  prefixIcon: Icon(Icons.memory),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _peminjamController,
                enabled: !_submitting,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama peminjam',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
              if (_submitting) ...[
                const SizedBox(height: 20),
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                const Text(
                  'Memproses transaksi blockchain...',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Lanjutkan'),
          ),
        ],
      ),
    );
  }
}
