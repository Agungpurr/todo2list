// lib/pages/settings_page.dart

import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/pin_service.dart';
import 'pin_lock_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final NotificationService _notifService = NotificationService();
  final PinService _pinService = PinService.instance;

  bool _dailyEnabled = false;
  TimeOfDay _dailyTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isLoading = true;
  bool _pinEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final enabled = await _notifService.isDailyReminderEnabled();
    final time = await _notifService.getDailyReminderTime();
    final pinEnabled = await _pinService.isPinEnabled();
    setState(() {
      _dailyEnabled = enabled;
      _dailyTime = TimeOfDay(hour: time.hour, minute: time.minute);
      _pinEnabled = pinEnabled;
      _isLoading = false;
    });
  }

  // ===== PIN =====
  Future<void> _onTogglePin(bool value) async {
    if (value) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PinLockPage(
            mode: PinMode.setup,
            onSuccess: () async {
              Navigator.pop(context);
              setState(() => _pinEnabled = true);
              // Backup code sudah disimpan di PinService.setPin()
              // Tampilkan ke user
              final prefs = await SharedPreferences.getInstance();
              final backupCode = prefs.getString('pin_backup_code') ?? '';
              if (mounted) {
                await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => AlertDialog(
                    title: const Text('🔑 Simpan Kode Backup'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Ini kode backup untuk reset PIN jika lupa. Simpan di tempat aman!',
                          textAlign: TextAlign.center,
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
                            backupCode,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Kode ini tidak bisa dilihat lagi setelah ditutup.',
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
            },
          ),
        ),
      );
    } else {
      // Konfirmasi PIN dulu sebelum nonaktifkan
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Nonaktifkan PIN?'),
          content: const Text('Masukkan PIN untuk konfirmasi.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Lanjut'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PinLockPage(
            mode: PinMode.verify,
            onSuccess: () async {
              await _pinService.disablePin();
              Navigator.pop(context);
              setState(() => _pinEnabled = false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN dinonaktifkan')),
                );
              }
            },
          ),
        ),
      );
    }
  }

  Future<void> _changePin() async {
    // Verifikasi PIN lama dulu
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PinLockPage(
          mode: PinMode.verify,
          onSuccess: () async {
            Navigator.pop(context);
            if (!mounted) return;
            // Setup PIN baru
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PinLockPage(
                  mode: PinMode.change,
                  onSuccess: () {
                    Navigator.pop(context);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('PIN berhasil diubah'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ===== NOTIFIKASI (tetap sama) =====
  Future<void> _onToggleDaily(bool value) async {
    setState(() => _dailyEnabled = value);
    if (value) {
      final granted = await _notifService.requestPermissions();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin notifikasi ditolak.'),
          ),
        );
      }
    }
    await _notifService.setDailyReminder(
      enabled: value,
      hour: _dailyTime.hour,
      minute: _dailyTime.minute,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value
              ? 'Pengingat harian diaktifkan jam ${_dailyTime.format(context)}'
              : 'Pengingat harian dimatikan'),
        ),
      );
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dailyTime,
    );
    if (picked == null) return;
    setState(() => _dailyTime = picked);
    if (_dailyEnabled) {
      await _notifService.setDailyReminder(
        enabled: true,
        hour: picked.hour,
        minute: picked.minute,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Jam pengingat diubah ke ${picked.format(context)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // ===== SECTION PIN =====
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    'Keamanan',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Kunci PIN'),
                  subtitle: const Text('Lindungi app dengan PIN 6 digit'),
                  secondary:
                      const Icon(Icons.lock_outline), // ✅ pakai secondary
                  value: _pinEnabled,
                  onChanged: _onTogglePin,
                ),
                if (_pinEnabled)
                  ListTile(
                    leading: const Icon(Icons.key),
                    title: const Text('Ganti PIN'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _changePin,
                  ),
                const Divider(),

                // ===== SECTION NOTIFIKASI (tetap sama) =====
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'Notifikasi',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Pengingat Harian'),
                  subtitle: const Text(
                      'Ringkasan todo aktif & note hari ini, dikirim tiap hari'),
                  value: _dailyEnabled,
                  onChanged: _onToggleDaily,
                ),
                ListTile(
                  enabled: _dailyEnabled,
                  leading: const Icon(Icons.access_time),
                  title: const Text('Jam Pengingat'),
                  subtitle: Text(_dailyTime.format(context)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _dailyEnabled ? _pickTime : null,
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'Tentang Pengingat Todo',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text(
                    'Todo dengan tanggal & jam jatuh tempo otomatis diberi pengingat 2 jam sebelum, 1 jam sebelum, dan saat waktunya tiba.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
    );
  }
}
