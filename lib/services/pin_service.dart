import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class PinService {
  static final PinService instance = PinService._();
  PinService._();

  static const _keyPin = 'app_pin';
  static const _keyEnabled = 'pin_enabled';
  static const _keyBackupCode = 'pin_backup_code';
  static const _keyAttempts = 'pin_attempts';
  static const _keyLockedUntil = 'pin_locked_until';
  static const int maxAttempts = 5;
  static const int lockDurationMinutes = 5;

  Future<bool> isPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  Future<String?> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPin);
  }

  Future<int> getAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyAttempts) ?? 0;
  }

  Future<DateTime?> getLockedUntil() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_keyLockedUntil);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<bool> isLocked() async {
    final lockedUntil = await getLockedUntil();
    if (lockedUntil == null) return false;
    return DateTime.now().isBefore(lockedUntil);
  }

  Future<Duration?> remainingLockDuration() async {
    final lockedUntil = await getLockedUntil();
    if (lockedUntil == null) return null;
    final remaining = lockedUntil.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  String _generateCode(int length) {
    final rand = Random.secure();
    return List.generate(length, (_) => rand.nextInt(10)).join();
  }

  Future<String> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final backupCode = _generateCode(8);
    await prefs.setString(_keyPin, pin);
    await prefs.setBool(_keyEnabled, true);
    await prefs.setString(_keyBackupCode, backupCode);
    await prefs.remove(_keyAttempts);
    await prefs.remove(_keyLockedUntil);
    return backupCode;
  }

  Future<void> disablePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPin);
    await prefs.remove(_keyBackupCode);
    await prefs.remove(_keyAttempts);
    await prefs.remove(_keyLockedUntil);
    await prefs.setBool(_keyEnabled, false);
  }

  // Verifikasi PIN + hitung percobaan gagal
  Future<PinVerifyResult> verifyPin(String input) async {
    final prefs = await SharedPreferences.getInstance();

    // Cek terkunci
    final lockedUntil = await getLockedUntil();
    if (lockedUntil != null && DateTime.now().isBefore(lockedUntil)) {
      final remaining = lockedUntil.difference(DateTime.now());
      return PinVerifyResult.locked(remaining);
    }

    final saved = prefs.getString(_keyPin);
    final ok = saved == input;

    if (ok) {
      await prefs.remove(_keyAttempts);
      await prefs.remove(_keyLockedUntil);
      return PinVerifyResult.success();
    } else {
      final attempts = (prefs.getInt(_keyAttempts) ?? 0) + 1;
      await prefs.setInt(_keyAttempts, attempts);

      if (attempts >= maxAttempts) {
        final until =
            DateTime.now().add(Duration(minutes: lockDurationMinutes));
        await prefs.setInt(_keyLockedUntil, until.millisecondsSinceEpoch);
        await prefs.remove(_keyAttempts);
        return PinVerifyResult.locked(Duration(minutes: lockDurationMinutes));
      }

      return PinVerifyResult.failed(maxAttempts - attempts);
    }
  }

  Future<bool> verifyBackupCode(String input) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyBackupCode);
    return saved != null && saved == input.trim();
  }

  Future<String> resetPinWithBackupCode(String newPin) async {
    final prefs = await SharedPreferences.getInstance();
    final newBackupCode = _generateCode(8);
    await prefs.setString(_keyPin, newPin);
    await prefs.setString(_keyBackupCode, newBackupCode);
    await prefs.remove(_keyAttempts);
    await prefs.remove(_keyLockedUntil);
    return newBackupCode;
  }
}

// Result class untuk verifyPin
class PinVerifyResult {
  final bool isSuccess;
  final bool isLocked;
  final int? remainingAttempts;
  final Duration? lockDuration;

  PinVerifyResult._({
    required this.isSuccess,
    required this.isLocked,
    this.remainingAttempts,
    this.lockDuration,
  });

  factory PinVerifyResult.success() =>
      PinVerifyResult._(isSuccess: true, isLocked: false);

  factory PinVerifyResult.failed(int remaining) => PinVerifyResult._(
      isSuccess: false, isLocked: false, remainingAttempts: remaining);

  factory PinVerifyResult.locked(Duration duration) => PinVerifyResult._(
      isSuccess: false, isLocked: true, lockDuration: duration);
}
