import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelper {
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

  static String normalizePhone(String rawPhone) {
    String phone = rawPhone.trim();

    phone = phone.replaceAll(RegExp(r'[^0-9+]'), '');

    if (phone.startsWith('+')) {
      phone = phone.substring(1);
    }

    if (phone.startsWith('0')) {
      phone = '62${phone.substring(1)}';
    }

    if (phone.startsWith('8')) {
      phone = '62$phone';
    }

    return phone;
  }

  static String _formatBillingMonth(String value) {
    final text = value.trim();

    if (text.isEmpty) return text;

    final yearMonthMatch = RegExp(r'^(\d{4})-(\d{1,2})$').firstMatch(text);

    if (yearMonthMatch != null) {
      final year = yearMonthMatch.group(1) ?? '';
      final month = int.tryParse(yearMonthMatch.group(2) ?? '') ?? 0;

      if (month >= 1 && month <= 12) {
        return '${_monthNames[month]} tahun $year';
      }
    }

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

  static bool _hasValue(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static Future<void> openChat({
    required BuildContext context,
    required String phone,
    required String message,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final normalizedPhone = normalizePhone(phone);

    if (normalizedPhone.isEmpty || normalizedPhone.length < 10) {
      _showSnackBar(
        messenger,
        'Nomor WhatsApp tenant tidak valid atau belum tersedia.',
        const Color(0xFFFF3B30),
      );
      return;
    }

    final Uri waMeUri = Uri.parse(
      'https://wa.me/$normalizedPhone?text=${Uri.encodeComponent(message)}',
    );

    final Uri apiWhatsappUri = Uri.parse(
      'https://api.whatsapp.com/send?phone=$normalizedPhone&text=${Uri.encodeComponent(message)}',
    );

    try {
      final bool launchedWaMe = await launchUrl(
        waMeUri,
        mode: LaunchMode.externalApplication,
      );

      if (launchedWaMe) return;

      final bool launchedApi = await launchUrl(
        apiWhatsappUri,
        mode: LaunchMode.externalApplication,
      );

      if (launchedApi) return;

      _showSnackBar(
        messenger,
        'Tidak bisa membuka WhatsApp. Pastikan WhatsApp sudah terpasang.',
        const Color(0xFFFF3B30),
      );
    } catch (_) {
      try {
        final bool launchedFallback = await launchUrl(
          apiWhatsappUri,
          mode: LaunchMode.externalApplication,
        );

        if (launchedFallback) return;

        _showSnackBar(
          messenger,
          'Tidak bisa membuka WhatsApp. Pastikan WhatsApp sudah terpasang.',
          const Color(0xFFFF3B30),
        );
      } catch (_) {
        _showSnackBar(
          messenger,
          'Gagal membuka WhatsApp.',
          const Color(0xFFFF3B30),
        );
      }
    }
  }

  static Future<void> openBillReminder({
    required BuildContext context,
    required String phone,
    required String tenantName,
    required String billingMonth,
    required String totalAmount,
    required String dueDate,
    String? baseRent,
    String? addonAmount,
    String? penaltyAmount,

    String? addonDetails,
    List<String>? addonItems,
  }) async {
    final formattedBillingMonth = _formatBillingMonth(billingMonth);
    final formattedDueDate = _formatIndonesianDate(dueDate);

    final message = StringBuffer();

    message.writeln('Halo $tenantName 👋');
    message.writeln();
    message.writeln(
      'Ini pengingat tagihan kos bulan $formattedBillingMonth dari *KostIn*.',
    );
    message.writeln();
    message.writeln('Berikut rincian tagihannya ya:');
    message.writeln();
    message.writeln(
      '🏠 Base rent: ${_hasValue(baseRent) ? baseRent!.trim() : '-'}',
    );

    if (_hasValue(addonAmount)) {
      message.writeln('🧩 Add-ons: ${addonAmount!.trim()}');

      if (addonItems != null && addonItems.isNotEmpty) {
        for (final item in addonItems) {
          if (item.trim().isNotEmpty) {
            message.writeln('   • ${item.trim()}');
          }
        }
      } else if (_hasValue(addonDetails)) {
        final lines = addonDetails!.split('\n');

        for (final line in lines) {
          if (line.trim().isNotEmpty) {
            message.writeln('   • ${line.trim()}');
          }
        }
      }
    }

    if (_hasValue(penaltyAmount)) {
      message.writeln('⚠️ Penalty: ${penaltyAmount!.trim()}');
    }

    message.writeln();
    message.writeln('💰 *Total tagihan: $totalAmount*');
    message.writeln();
    message.writeln('📅 Jatuh tempo: *$formattedDueDate*');
    message.writeln();
    message.writeln(
      'Mohon dibayarkan sebelum jatuh tempo ya. Kalau sudah melakukan pembayaran, boleh langsung kabari kami 😊',
    );
    message.writeln();
    message.writeln('Terima kasih 🙏');

    await openChat(
      context: context,
      phone: phone,
      message: message.toString(),
    );
  }

  static Future<void> openPaymentReceivedMessage({
    required BuildContext context,
    required String phone,
    required String tenantName,
    required String billingMonth,
    required String totalAmount,
    String? paidDate,
  }) async {
    final formattedBillingMonth = _formatBillingMonth(billingMonth);
    final formattedPaidDate = _hasValue(paidDate)
        ? _formatIndonesianDate(paidDate!)
        : null;

    final message = StringBuffer();

    message.writeln('Halo $tenantName 👋');
    message.writeln();
    message.writeln(
      'Pembayaran tagihan kos bulan $formattedBillingMonth sudah kami terima di *KostIn*.',
    );
    message.writeln();
    message.writeln('💰 *Total dibayar: $totalAmount*');

    if (_hasValue(formattedPaidDate)) {
      message.writeln('📅 Tanggal pembayaran: *$formattedPaidDate*');
    }

    message.writeln();
    message.writeln('Terima kasih ya 🙏😊');

    await openChat(
      context: context,
      phone: phone,
      message: message.toString(),
    );
  }

  static Future<void> openCustomMessage({
    required BuildContext context,
    required String phone,
    required String tenantName,
    required String message,
  }) async {
    final finalMessage = message.replaceAll(
      '{tenant_name}',
      tenantName,
    );

    await openChat(
      context: context,
      phone: phone,
      message: finalMessage,
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