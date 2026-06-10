import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmailHelper {
  static const List<String> _monthNames = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static bool _hasValue(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static bool isValidEmail(String email) {
    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty) return false;

    final emailRegex = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    );

    return emailRegex.hasMatch(trimmedEmail);
  }

  static String _formatBillingMonth(String value) {
    final text = value.trim();

    if (text.isEmpty) return text;

    // Format: 2026-06 atau 2026-6
    final yearMonthMatch = RegExp(r'^(\d{4})-(\d{1,2})$').firstMatch(text);

    if (yearMonthMatch != null) {
      final year = yearMonthMatch.group(1) ?? '';
      final month = int.tryParse(yearMonthMatch.group(2) ?? '') ?? 0;

      if (month >= 1 && month <= 12) {
        return '${_monthNames[month]} tahun $year';
      }
    }

    // Format: 2026-06-01
    final dateMatch = RegExp(
      r'^(\d{4})-(\d{1,2})-(\d{1,2})$',
    ).firstMatch(text);

    if (dateMatch != null) {
      final year = dateMatch.group(1) ?? '';
      final month = int.tryParse(dateMatch.group(2) ?? '') ?? 0;

      if (month >= 1 && month <= 12) {
        return '${_monthNames[month]} tahun $year';
      }
    }

    return text;
  }

  static String _formatIndonesianDate(String value) {
    final text = value.trim();

    if (text.isEmpty) return text;

    // Format: 2026-07-02
    final isoMatch = RegExp(
      r'^(\d{4})-(\d{1,2})-(\d{1,2})$',
    ).firstMatch(text);

    if (isoMatch != null) {
      final year = isoMatch.group(1) ?? '';
      final month = int.tryParse(isoMatch.group(2) ?? '') ?? 0;
      final day = int.tryParse(isoMatch.group(3) ?? '') ?? 0;

      if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        return '${day.toString().padLeft(2, '0')} ${_monthNames[month]} $year';
      }
    }

    // Format: 02 Jul 2026 / 2 Jul 2026 / 02 July 2026
    final parts = text.split(RegExp(r'\s+'));

    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final monthText = parts[1].toLowerCase();
      final year = parts[2];

      final monthMap = <String, String>{
        'jan': 'Januari',
        'january': 'Januari',
        'januari': 'Januari',
        'feb': 'Februari',
        'february': 'Februari',
        'februari': 'Februari',
        'mar': 'Maret',
        'march': 'Maret',
        'maret': 'Maret',
        'apr': 'April',
        'april': 'April',
        'may': 'Mei',
        'mei': 'Mei',
        'jun': 'Juni',
        'june': 'Juni',
        'juni': 'Juni',
        'jul': 'Juli',
        'july': 'Juli',
        'juli': 'Juli',
        'aug': 'Agustus',
        'august': 'Agustus',
        'agu': 'Agustus',
        'agustus': 'Agustus',
        'sep': 'September',
        'sept': 'September',
        'september': 'September',
        'oct': 'Oktober',
        'october': 'Oktober',
        'okt': 'Oktober',
        'oktober': 'Oktober',
        'nov': 'November',
        'november': 'November',
        'dec': 'Desember',
        'december': 'Desember',
        'des': 'Desember',
        'desember': 'Desember',
      };

      final monthName = monthMap[monthText];

      if (day != null && monthName != null && year.isNotEmpty) {
        return '${day.toString().padLeft(2, '0')} $monthName $year';
      }
    }

    return text;
  }

  static Future<void> openEmail({
    required BuildContext context,
    required String email,
    required String subject,
    required String body,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final trimmedEmail = email.trim();

    if (!isValidEmail(trimmedEmail)) {
      _showSnackBar(
        messenger,
        'Email tenant tidak valid atau belum tersedia.',
        const Color(0xFFFF3B30),
      );
      return;
    }

    // Jangan pakai Uri(queryParameters: ...)
    // karena beberapa aplikasi email Android bisa menampilkan spasi sebagai tanda "+".
    // Uri.encodeComponent akan mengubah spasi menjadi "%20", sehingga teks tampil normal.
    final encodedSubject = Uri.encodeComponent(subject);
    final encodedBody = Uri.encodeComponent(body);

    final Uri emailUri = Uri.parse(
      'mailto:$trimmedEmail?subject=$encodedSubject&body=$encodedBody',
    );

    try {
      final bool launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) return;

      _showSnackBar(
        messenger,
        'Tidak bisa membuka aplikasi email. Pastikan Gmail, Email, atau Outlook sudah terpasang.',
        const Color(0xFFFF3B30),
      );
    } catch (_) {
      _showSnackBar(
        messenger,
        'Gagal membuka aplikasi email.',
        const Color(0xFFFF3B30),
      );
    }
  }

  static Future<void> openBillReminderEmail({
    required BuildContext context,
    required String email,
    required String tenantName,
    required String billingMonth,
    required String totalAmount,
    required String dueDate,
    String? baseRent,
    String? addonAmount,
    String? penaltyAmount,

    // Bisa isi salah satu:
    // 1. addonDetails: String bebas yang sudah diformat dari billing screen
    // 2. addonItems: List item add-on, misalnya ['Trash Bin: Rp 20.000']
    String? addonDetails,
    List<String>? addonItems,
  }) async {
    final formattedBillingMonth = _formatBillingMonth(billingMonth);
    final formattedDueDate = _formatIndonesianDate(dueDate);

    final subject = 'Pengingat Tagihan Kos - $formattedBillingMonth';

    final body = StringBuffer();

    body.writeln('Halo $tenantName,');
    body.writeln();
    body.writeln(
      'Ini adalah pengingat tagihan kos bulan $formattedBillingMonth dari KostIn.',
    );
    body.writeln();
    body.writeln('Berikut rincian tagihannya:');
    body.writeln();
    body.writeln(
      'Base rent: ${_hasValue(baseRent) ? baseRent!.trim() : '-'}',
    );

    if (_hasValue(addonAmount)) {
      body.writeln('Add-ons: ${addonAmount!.trim()}');

      if (addonItems != null && addonItems.isNotEmpty) {
        for (final item in addonItems) {
          if (item.trim().isNotEmpty) {
            body.writeln('- ${item.trim()}');
          }
        }
      } else if (_hasValue(addonDetails)) {
        final lines = addonDetails!.split('\n');

        for (final line in lines) {
          if (line.trim().isNotEmpty) {
            body.writeln('- ${line.trim()}');
          }
        }
      }
    }

    if (_hasValue(penaltyAmount)) {
      body.writeln('Penalty: ${penaltyAmount!.trim()}');
    }

    body.writeln();
    body.writeln('Total tagihan: $totalAmount');
    body.writeln('Jatuh tempo: $formattedDueDate');
    body.writeln();
    body.writeln(
      'Mohon dibayarkan sebelum jatuh tempo. Jika sudah melakukan pembayaran, silakan konfirmasi kepada kami.',
    );
    body.writeln();
    body.writeln('Terima kasih.');
    body.writeln();
    body.writeln('KostIn');

    await openEmail(
      context: context,
      email: email,
      subject: subject,
      body: body.toString(),
    );
  }

  static Future<void> openPaymentReceivedEmail({
    required BuildContext context,
    required String email,
    required String tenantName,
    required String billingMonth,
    required String totalAmount,
    String? paidDate,
  }) async {
    final formattedBillingMonth = _formatBillingMonth(billingMonth);
    final formattedPaidDate = _hasValue(paidDate)
        ? _formatIndonesianDate(paidDate!)
        : null;

    final subject = 'Konfirmasi Pembayaran Kos - $formattedBillingMonth';

    final body = StringBuffer();

    body.writeln('Halo $tenantName,');
    body.writeln();
    body.writeln(
      'Pembayaran tagihan kos bulan $formattedBillingMonth sudah kami terima di KostIn.',
    );
    body.writeln();
    body.writeln('Total dibayar: $totalAmount');

    if (_hasValue(formattedPaidDate)) {
      body.writeln('Tanggal pembayaran: $formattedPaidDate');
    }

    body.writeln();
    body.writeln('Terima kasih.');
    body.writeln();
    body.writeln('KostIn');

    await openEmail(
      context: context,
      email: email,
      subject: subject,
      body: body.toString(),
    );
  }

  static Future<void> openCustomEmail({
    required BuildContext context,
    required String email,
    required String tenantName,
    required String subject,
    required String message,
  }) async {
    final finalSubject = subject.replaceAll(
      '{tenant_name}',
      tenantName,
    );

    final finalMessage = message.replaceAll(
      '{tenant_name}',
      tenantName,
    );

    await openEmail(
      context: context,
      email: email,
      subject: finalSubject,
      body: finalMessage,
    );
  }

  static void _showSnackBar(
      ScaffoldMessengerState messenger,
      String message,
      Color color,
      ) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}