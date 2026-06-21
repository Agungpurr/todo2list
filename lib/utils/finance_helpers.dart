// lib/utils/finance_helpers.dart

import 'package:flutter/material.dart';
import '../models/transaction.dart';

class FinanceHelpers {
  static String getCategoryLabel(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.makanan:
        return 'Makanan';
      case TransactionCategory.transport:
        return 'Transport';
      case TransactionCategory.kos:
        return 'Kos/Sewa';
      case TransactionCategory.pendidikan:
        return 'Pendidikan';
      case TransactionCategory.hiburan:
        return 'Hiburan';
      case TransactionCategory.jajan:
        return 'Jajan/Nongkrong';
      case TransactionCategory.pulsaInternet:
        return 'Pulsa/Internet';
      case TransactionCategory.kesehatan:
        return 'Kesehatan';
      case TransactionCategory.tabungan:
        return 'Tabungan';
      case TransactionCategory.lainnyaExpense:
        return 'Lainnya';
      case TransactionCategory.uangSaku:
        return 'Uang Saku';
      case TransactionCategory.gaji:
        return 'Gaji/Part-time';

      case TransactionCategory.beasiswa:
        return 'Beasiswa';
      case TransactionCategory.lainnyaIncome:
        return 'Lainnya';
    }
  }

  static IconData getCategoryIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.makanan:
        return Icons.restaurant;
      case TransactionCategory.transport:
        return Icons.directions_bus;
      case TransactionCategory.kos:
        return Icons.home;
      case TransactionCategory.pendidikan:
        return Icons.school;
      case TransactionCategory.hiburan:
        return Icons.movie;
      case TransactionCategory.jajan:
        return Icons.local_cafe;
      case TransactionCategory.pulsaInternet:
        return Icons.wifi;
      case TransactionCategory.kesehatan:
        return Icons.local_hospital;
      case TransactionCategory.tabungan:
        return Icons.savings;
      case TransactionCategory.lainnyaExpense:
        return Icons.more_horiz;
      case TransactionCategory.uangSaku:
        return Icons.account_balance_wallet;
      case TransactionCategory.gaji:
        return Icons.work;
      case TransactionCategory.beasiswa:
        return Icons.card_giftcard;
      case TransactionCategory.lainnyaIncome:
        return Icons.more_horiz;
    }
  }

  static Color getCategoryColor(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.makanan:
        return const Color(0xFFFF7043);
      case TransactionCategory.transport:
        return const Color(0xFF42A5F5);
      case TransactionCategory.kos:
        return const Color(0xFF8D6E63);
      case TransactionCategory.pendidikan:
        return const Color(0xFF5C6BC0);
      case TransactionCategory.hiburan:
        return const Color(0xFFAB47BC);
      case TransactionCategory.jajan:
        return const Color(0xFFFFA726);
      case TransactionCategory.pulsaInternet:
        return const Color(0xFF26A69A);
      case TransactionCategory.kesehatan:
        return const Color(0xFFEF5350);
      case TransactionCategory.lainnyaExpense:
        return const Color(0xFF78909C);
      case TransactionCategory.tabungan:
        return const Color(0xFF26A69A);
      case TransactionCategory.uangSaku:
        return const Color(0xFF66BB6A);
      case TransactionCategory.gaji:
        return const Color(0xFF43A047);
      case TransactionCategory.beasiswa:
        return const Color(0xFF26C6DA);
      case TransactionCategory.lainnyaIncome:
        return const Color(0xFF9CCC65);
    }
  }

  static String formatRupiah(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs().toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = absAmount.length - 1; i >= 0; i--) {
      buffer.write(absAmount[i]);
      count++;
      if (count % 3 == 0 && i != 0) buffer.write('.');
    }
    final result = buffer.toString().split('').reversed.join();
    return '${isNegative ? '-' : ''}Rp$result';
  }

  static String formatRupiahCompact(double amount) {
    if (amount.abs() >= 1000000) {
      return 'Rp${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount.abs() >= 1000) {
      return 'Rp${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return formatRupiah(amount);
  }
}
