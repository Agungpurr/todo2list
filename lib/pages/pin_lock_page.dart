import 'package:flutter/material.dart';
import '../services/pin_service.dart';
import 'dart:async';

enum PinMode { verify, setup, change }

class PinLockPage extends StatefulWidget {
  final PinMode mode;
  final VoidCallback? onSuccess;

  const PinLockPage({
    Key? key,
    this.mode = PinMode.verify,
    this.onSuccess,
  }) : super(key: key);

  @override
  State<PinLockPage> createState() => _PinLockPageState();
}

class _PinLockPageState extends State<PinLockPage> {
  final _pinService = PinService.instance;
  String _input = '';
  String _firstPin = '';
  bool _isConfirming = false;
  String? _errorMsg;
  bool _isLocked = false;
  Timer? _lockTimer;
  Duration _remainingLock = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.mode == PinMode.verify) _checkLockStatus();
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkLockStatus() async {
    final remaining = await _pinService.remainingLockDuration();
    if (remaining != null) {
      _startLockCountdown(remaining);
    }
  }

  void _startLockCountdown(Duration duration) {
    setState(() {
      _isLocked = true;
      _remainingLock = duration;
    });
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingLock = _remainingLock - const Duration(seconds: 1);
        if (_remainingLock.inSeconds <= 0) {
          _isLocked = false;
          _errorMsg = null;
          timer.cancel();
        }
      });
    });
  }

  String get _title {
    if (widget.mode == PinMode.verify) return 'Masukkan PIN';
    if (widget.mode == PinMode.setup) {
      return _isConfirming ? 'Konfirmasi PIN' : 'Buat PIN Baru';
    }
    return _isConfirming ? 'Konfirmasi PIN Baru' : 'Masukkan PIN Baru';
  }

  void _onKey(String val) {
    if (_isLocked || _input.length >= 6) return;
    setState(() {
      _input += val;
      _errorMsg = null;
    });
    if (_input.length == 6) _onComplete();
  }

  void _onDelete() {
    if (_isLocked || _input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  Future<void> _onComplete() async {
    if (widget.mode == PinMode.verify) {
      final result = await _pinService.verifyPin(_input);

      if (result.isSuccess) {
        widget.onSuccess?.call();
      } else if (result.isLocked) {
        _startLockCountdown(result.lockDuration!);
        setState(() => _input = '');
      } else {
        setState(() {
          _input = '';
          _errorMsg = 'PIN salah. Sisa percobaan: ${result.remainingAttempts}';
        });
      }
    } else {
      // setup / change
      if (!_isConfirming) {
        setState(() {
          _firstPin = _input;
          _input = '';
          _isConfirming = true;
        });
      } else {
        if (_input == _firstPin) {
          final backupCode = await _pinService.setPin(_input);
          widget.onSuccess?.call();
          // Tampilkan backup code
          if (mounted) _showBackupCode(backupCode);
        } else {
          setState(() {
            _input = '';
            _firstPin = '';
            _isConfirming = false;
            _errorMsg = 'PIN tidak cocok, ulangi';
          });
        }
      }
    }
  }

  void _showBackupCode(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🔑 Simpan Kode Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Simpan kode ini di tempat aman. Digunakan untuk reset PIN jika lupa.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Kode ini tidak bisa dilihat lagi setelah ditutup.',
              style: TextStyle(fontSize: 12, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sudah Disimpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _showForgotPin() async {
    // Cek apakah sudah terkunci (sudah 5x salah)
    final locked = await _pinService.isLocked();
    if (!locked && !mounted) return;

    if (!locked) {
      // Belum terkunci — tampilkan info saja
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Lupa PIN?'),
          content: const Text(
            'Masukkan PIN yang salah sebanyak 5 kali untuk mengaktifkan opsi reset dengan kode backup.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Sudah terkunci — tampilkan form reset dengan backup code
    final backupController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    int step = 0;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(
                step == 0 ? 'Reset PIN - Verifikasi' : 'Reset PIN - PIN Baru'),
            content: step == 0
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Masukkan kode backup 8 digit yang kamu simpan saat setup PIN.',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: backupController,
                        keyboardType: TextInputType.number,
                        maxLength: 8,
                        decoration: const InputDecoration(
                          labelText: 'Kode Backup (8 digit)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: newPinController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'PIN Baru (6 digit)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: confirmPinController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Konfirmasi PIN Baru',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (step == 0) {
                    final ok = await _pinService
                        .verifyBackupCode(backupController.text);
                    if (ok) {
                      setDialogState(() => step = 1);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kode backup salah'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    final newPin = newPinController.text.trim();
                    final confirmPin = confirmPinController.text.trim();
                    if (newPin.length != 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PIN harus 6 digit')),
                      );
                      return;
                    }
                    if (newPin != confirmPin) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PIN tidak cocok')),
                      );
                      return;
                    }
                    final newBackup =
                        await _pinService.resetPinWithBackupCode(newPin);
                    Navigator.pop(ctx);

                    // Tampilkan backup code baru
                    if (mounted) {
                      await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => AlertDialog(
                          title: const Text('PIN Berhasil Direset'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Kode backup baru kamu:'),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber),
                                ),
                                child: Text(
                                  newBackup,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '⚠️ Simpan kode ini! Tidak bisa dilihat lagi.',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Sudah Disimpan'),
                            ),
                          ],
                        ),
                      );
                      // Reset lock state
                      setState(() {
                        _isLocked = false;
                        _errorMsg = null;
                        _input = '';
                        _lockTimer?.cancel();
                      });
                    }
                  }
                },
                child: Text(step == 0 ? 'Verifikasi' : 'Reset PIN'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Text('🔒 Harianku',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 32),

            // Dot indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                final filled = i < _input.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        filled ? color : Theme.of(context).colorScheme.outline,
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            // Status pesan
            SizedBox(
              height: 40,
              child: _isLocked
                  ? Column(
                      children: [
                        const Text(
                          '🔒 Terlalu banyak percobaan',
                          style: TextStyle(color: Colors.red, fontSize: 13),
                        ),
                        Text(
                          'Coba lagi dalam ${_remainingLock.inMinutes}m ${_remainingLock.inSeconds % 60}d',
                          style:
                              const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ],
                    )
                  : _errorMsg != null
                      ? Text(
                          _errorMsg!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 14),
                        )
                      : const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),

            // Numpad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  ...['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((n) =>
                      _NumKey(
                          label: n,
                          onTap: _isLocked ? () {} : () => _onKey(n),
                          disabled: _isLocked)),
                  const SizedBox(),
                  _NumKey(
                      label: '0',
                      onTap: _isLocked ? () {} : () => _onKey('0'),
                      disabled: _isLocked),
                  _NumKey(
                      icon: Icons.backspace_outlined,
                      onTap: _onDelete,
                      disabled: _isLocked),
                ],
              ),
            ),

            if (widget.mode == PinMode.verify) ...[
              const SizedBox(height: 24),
              TextButton(
                onPressed: _showForgotPin,
                child: const Text('Lupa PIN?'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NumKey extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool disabled;

  const _NumKey({
    this.label,
    this.icon,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: disabled
              ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4)
              : Theme.of(context).colorScheme.surfaceVariant,
        ),
        alignment: Alignment.center,
        child: label != null
            ? Text(
                label!,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: disabled ? Colors.grey : null,
                ),
              )
            : Icon(icon, size: 24, color: disabled ? Colors.grey : null),
      ),
    );
  }
}
