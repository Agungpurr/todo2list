// lib/pages/settings_page.dart

import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final NotificationService _notifService = NotificationService();

  bool _dailyEnabled = false;
  TimeOfDay _dailyTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final enabled = await _notifService.isDailyReminderEnabled();
    final time = await _notifService.getDailyReminderTime();
    setState(() {
      _dailyEnabled = enabled;
      _dailyTime = TimeOfDay(hour: time.hour, minute: time.minute);
      _isLoading = false;
    });
  }

  Future<void> _onToggleDaily(bool value) async {
    setState(() => _dailyEnabled = value);

    if (value) {
      final granted = await _notifService.requestPermissions();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Izin notifikasi ditolak. Aktifkan lewat Settings HP untuk pengingat ini berfungsi.'),
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
            content: Text('Jam pengingat diubah ke ${picked.format(context)}'),
          ),
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
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
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
