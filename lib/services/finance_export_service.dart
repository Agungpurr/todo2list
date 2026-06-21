// lib/services/finance_export_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/transaction.dart';
import '../utils/finance_helpers.dart';

class FinanceExportService {
  static Future<void> exportCsv(
    List<Transaction> transactions,
    DateTimeRange range,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln('Tanggal,Judul,Tipe,Kategori,Jumlah,Catatan');

    final sorted = List<Transaction>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final t in sorted) {
      final date = DateFormat('yyyy-MM-dd').format(t.date);
      final type =
          t.type == TransactionType.income ? 'Pemasukan' : 'Pengeluaran';
      final category = FinanceHelpers.getCategoryLabel(t.category);
      final note = (t.note ?? '').replaceAll(',', ';').replaceAll('\n', ' ');
      final title = t.title.replaceAll(',', ';');
      buffer.writeln(
          '$date,$title,$type,$category,${t.amount.toStringAsFixed(0)},$note');
    }

    final dir = await getTemporaryDirectory();
    final fileName =
        'laporan_keuangan_${DateFormat('yyyyMMdd').format(range.start)}_${DateFormat('yyyyMMdd').format(range.end)}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles([XFile(file.path)],
        text:
            'Laporan Keuangan ${DateFormat('d MMM yyyy', 'id_ID').format(range.start)} - ${DateFormat('d MMM yyyy', 'id_ID').format(range.end)}');
  }

  static Future<void> exportPdf(
    List<Transaction> transactions,
    DateTimeRange range, {
    required double totalIncome,
    required double totalExpense,
    required Map<TransactionCategory, double> expenseByCategory,
  }) async {
    final doc = pw.Document();
    final sorted = List<Transaction>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    final balance = totalIncome - totalExpense;
    final dateRangeLabel =
        '${DateFormat('d MMM yyyy', 'id_ID').format(range.start)} - ${DateFormat('d MMM yyyy', 'id_ID').format(range.end)}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Laporan Keuangan',
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Text(dateRangeLabel, style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _pdfSummaryItem('Pemasukan', totalIncome, PdfColors.green700),
                _pdfSummaryItem('Pengeluaran', totalExpense, PdfColors.red700),
                _pdfSummaryItem('Selisih', balance,
                    balance >= 0 ? PdfColors.blue700 : PdfColors.red700),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          pw.Text('Pengeluaran per Kategori',
              style:
                  pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(2),
            },
            children: [
              _pdfTableHeaderRow(['Kategori', 'Jumlah']),
              ...expenseByCategory.entries.map((e) => _pdfTableRow([
                    FinanceHelpers.getCategoryLabel(e.key),
                    FinanceHelpers.formatRupiah(e.value),
                  ])),
            ],
          ),
          pw.SizedBox(height: 20),

          pw.Text('Rincian Transaksi',
              style:
                  pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(3),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(2),
            },
            children: [
              _pdfTableHeaderRow(['Tanggal', 'Judul', 'Kategori', 'Jumlah']),
              ...sorted.map((t) => _pdfTableRow([
                    DateFormat('d/M/yy').format(t.date),
                    t.title,
                    FinanceHelpers.getCategoryLabel(t.category),
                    '${t.type == TransactionType.income ? '+' : '-'}${FinanceHelpers.formatRupiah(t.amount)}',
                  ])),
            ],
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final fileName =
        'laporan_keuangan_${DateFormat('yyyyMMdd').format(range.start)}_${DateFormat('yyyyMMdd').format(range.end)}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await doc.save());

    await Share.shareXFiles([XFile(file.path)],
        text: 'Laporan Keuangan $dateRangeLabel');
  }

  static pw.Widget _pdfSummaryItem(String label, double value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(
          FinanceHelpers.formatRupiah(value),
          style: pw.TextStyle(
              fontSize: 12, fontWeight: pw.FontWeight.bold, color: color),
        ),
      ],
    );
  }

  static pw.TableRow _pdfTableHeaderRow(List<String> cells) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: cells
          .map((c) => pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(c,
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ))
          .toList(),
    );
  }

  static pw.TableRow _pdfTableRow(List<String> cells) {
    return pw.TableRow(
      children: cells
          .map((c) => pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(c, style: const pw.TextStyle(fontSize: 9)),
              ))
          .toList(),
    );
  }
}
