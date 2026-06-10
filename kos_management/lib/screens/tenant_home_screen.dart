import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';
import '../providers/tenant_provider.dart';
import 'role_select_screen.dart';

class TenantHomeScreen extends StatefulWidget {
  const TenantHomeScreen({super.key});

  @override
  State<TenantHomeScreen> createState() => _TenantHomeScreenState();
}

class _TenantHomeScreenState extends State<TenantHomeScreen> {
  final Color primaryGreen = const Color(0xFF34D399);
  final Color secondaryGreen = const Color(0xFF10B981);
  final Color darkGreen = const Color(0xFF0F3D2E);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TenantProvider>(
        context,
        listen: false,
      ).fetchBills();
    });
  }

  double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  String _formatRupiah(dynamic amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(_toDouble(amount));
  }

  DateTime _parseDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime(1900);
  }

  List<Map<String, dynamic>> _normalizeBills(List<dynamic> rawBills) {
    return rawBills
        .map<Map<String, dynamic>>((bill) {
      if (bill is Map<String, dynamic>) return bill;
      if (bill is Map) return Map<String, dynamic>.from(bill);
      return <String, dynamic>{};
    })
        .where((bill) => bill.isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _sortNewestFirst(
      List<Map<String, dynamic>> bills,
      ) {
    final copiedBills = List<Map<String, dynamic>>.from(bills);

    copiedBills.sort((a, b) {
      final monthA = '${a['billing_month'] ?? ''}';
      final monthB = '${b['billing_month'] ?? ''}';

      final monthCompare = monthB.compareTo(monthA);

      if (monthCompare != 0) return monthCompare;

      final dateA = _parseDate(a['due_date']);
      final dateB = _parseDate(b['due_date']);

      return dateB.compareTo(dateA);
    });

    return copiedBills;
  }

  List<Map<String, dynamic>> _getPaidBills(
      List<Map<String, dynamic>> bills,
      ) {
    return _sortNewestFirst(
      bills.where((bill) {
        final status = '${bill['status']}'.toLowerCase().trim();
        return status == 'paid';
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _getUnpaidBills(
      List<Map<String, dynamic>> bills,
      ) {
    return _sortNewestFirst(
      bills.where((bill) {
        final status = '${bill['status']}'.toLowerCase().trim();

        return status == 'unpaid' ||
            status == 'pending' ||
            status == 'belum_bayar' ||
            status == 'waiting_confirmation';
      }).toList(),
    );
  }

  Map<String, dynamic>? _getCurrentUnpaidBill({
    required dynamic providerCurrentBill,
    required List<Map<String, dynamic>> allBills,
  }) {
    if (providerCurrentBill is Map) {
      final mappedCurrent = Map<String, dynamic>.from(providerCurrentBill);
      final status = '${mappedCurrent['status']}'.toLowerCase().trim();

      if (status == 'unpaid' ||
          status == 'pending' ||
          status == 'belum_bayar' ||
          status == 'waiting_confirmation') {
        return mappedCurrent;
      }
    }

    final unpaidBills = _getUnpaidBills(allBills);

    if (unpaidBills.isEmpty) return null;

    return unpaidBills.first;
  }

  double _getBillTotal(Map<String, dynamic>? bill) {
    if (bill == null) return 0;

    final totalAmount = _toDouble(bill['total_amount']);

    if (totalAmount > 0) return totalAmount;

    final baseAmount = _toDouble(bill['base_amount']);
    final addonAmount = _toDouble(bill['addon_amount']);
    final penaltyAmount = _toDouble(bill['penalty_amount']);

    return baseAmount + addonAmount + penaltyAmount;
  }

  bool _isOverdue(dynamic dueDate) {
    final parsedDate = DateTime.tryParse(dueDate?.toString() ?? '');

    if (parsedDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return parsedDate.isBefore(today);
  }

  Map<String, dynamic> _buildFallbackBill(TenantProvider tenantProvider) {
    final basePrice = _toDouble(tenantProvider.tenant?.basePrice ?? 0);

    return {
      'id': null,
      'billing_month': 'Current Month',
      'due_date': null,
      'base_amount': basePrice,
      'addon_amount': 0,
      'penalty_amount': 0,
      'total_amount': basePrice,
      'status': 'unpaid',
    };
  }

  Future<void> _refreshBills() async {
    await Provider.of<TenantProvider>(
      context,
      listen: false,
    ).fetchBills();
  }

  String _getTenantToken(TenantProvider tenantProvider) {
    try {
      final dynamic provider = tenantProvider;

      final token = provider.token;
      if (token != null && token.toString().isNotEmpty) {
        return token.toString();
      }
    } catch (_) {}

    try {
      final dynamic provider = tenantProvider;

      final token = provider.tenantToken;
      if (token != null && token.toString().isNotEmpty) {
        return token.toString();
      }
    } catch (_) {}

    try {
      final dynamic provider = tenantProvider;

      final token = provider.authToken;
      if (token != null && token.toString().isNotEmpty) {
        return token.toString();
      }
    } catch (_) {}

    return '';
  }

  Future<void> _sendPaymentRequest({
    required Map<String, dynamic> bill,
    required String paymentMethod,
  }) async {
    final billId = bill['id'];

    if (billId == null ||
        billId.toString().isEmpty ||
        billId.toString() == 'null') {
      _showSnackBar(
        message: 'Bill id not found. Please refresh your bill first.',
      );
      return;
    }

    final tenantProvider = Provider.of<TenantProvider>(
      context,
      listen: false,
    );

    final token = _getTenantToken(tenantProvider);

    if (token.isEmpty) {
      _showSnackBar(
        message: 'Tenant token not found. Please login again.',
      );
      return;
    }

    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/tenant/pay/$billId',
      );

      debugPrint('PAYMENT REQUEST URL: $url');
      debugPrint('PAYMENT REQUEST METHOD: $paymentMethod');
      debugPrint('PAYMENT REQUEST BILL ID: $billId');

      final response = await http
          .post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'payment_method': paymentMethod,
        }),
      )
          .timeout(
        const Duration(seconds: 12),
      );

      debugPrint('PAYMENT REQUEST STATUS: ${response.statusCode}');
      debugPrint('PAYMENT REQUEST BODY: ${response.body}');

      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }

      if (!mounted) return;

      if (response.statusCode == 200 &&
          decoded is Map &&
          decoded['success'] == true) {
        _showSnackBar(
          message: decoded['message']?.toString() ??
              'Payment request sent. Waiting for owner confirmation.',
        );

        await _refreshBills();
      } else {
        _showSnackBar(
          message: decoded is Map
              ? decoded['message']?.toString() ??
              'Failed to send payment request.'
              : 'Failed to send payment request. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('PAYMENT REQUEST ERROR: $e');

      if (!mounted) return;

      _showSnackBar(
        message: 'Failed to send payment request. Please check your connection.',
      );
    }
  }

  Future<void> _logout() async {
    final tenant = Provider.of<TenantProvider>(
      context,
      listen: false,
    );

    await tenant.logout();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const RoleSelectScreen(),
      ),
    );
  }

  Widget _blurCircle({
    required double size,
    required Color color,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  void _showPaymentMethodSheet({
    required Map<String, dynamic> bill,
  }) {
    final amount = _getBillTotal(bill);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _GlassBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetDragHandle(),
              const SizedBox(height: 18),
              const Text(
                'Choose Payment Method',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Select how you want to pay your bill.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.66),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: primaryGreen.withOpacity(0.34),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      color: primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Total: ${_formatRupiah(amount)}',
                        style: const TextStyle(
                          color: Color(0xFFB8FFE2),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _PaymentOptionTile(
                icon: Icons.qr_code_2_rounded,
                title: 'QRIS',
                subtitle: 'Scan QR code to complete payment',
                iconColor: const Color(0xFF34D399),
                onTap: () {
                  Navigator.pop(context);
                  _showQrisSheet(bill: bill);
                },
              ),
              const SizedBox(height: 12),
              _PaymentOptionTile(
                icon: Icons.payments_rounded,
                title: 'Cash',
                subtitle: 'Pay directly to kos owner',
                iconColor: const Color(0xFFFFB74D),
                onTap: () {
                  Navigator.pop(context);
                  _showCashSheet(bill: bill);
                },
              ),
              const SizedBox(height: 12),
              _PaymentOptionTile(
                icon: Icons.account_balance_rounded,
                title: 'E-Banking',
                subtitle: 'Open installed banking or wallet apps',
                iconColor: const Color(0xFF60A5FA),
                onTap: () {
                  Navigator.pop(context);
                  _showEBankingSheet(bill: bill);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQrisSheet({
    required Map<String, dynamic> bill,
  }) {
    final amount = _getBillTotal(bill);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _GlassBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetDragHandle(),
              const SizedBox(height: 18),
              const Text(
                'Pay with QRIS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan this QR code using your payment app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.66),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 230,
                height: 230,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  size: 175,
                  color: Color(0xFF062116),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _formatRupiah(amount),
                style: const TextStyle(
                  color: Color(0xFFB8FFE2),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              _PrimarySheetButton(
                label: 'I Have Paid',
                icon: Icons.check_circle_rounded,
                color: primaryGreen,
                onTap: () {
                  Navigator.pop(context);

                  _sendPaymentRequest(
                    bill: bill,
                    paymentMethod: 'qris',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCashSheet({
    required Map<String, dynamic> bill,
  }) {
    final amount = _getBillTotal(bill);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _GlassBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetDragHandle(),
              const SizedBox(height: 18),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.22),
                  ),
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  color: Color(0xFFFFB74D),
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cash Payment',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please pay directly to the kos owner. After payment, the owner can confirm your bill.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.68),
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D).withOpacity(0.13),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFFFB74D).withOpacity(0.30),
                  ),
                ),
                child: Text(
                  'Amount: ${_formatRupiah(amount)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFFE0A3),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _PrimarySheetButton(
                label: 'Confirm Cash Payment',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFFFFB74D),
                textColor: const Color(0xFF1A1A1A),
                onTap: () {
                  Navigator.pop(context);

                  _sendPaymentRequest(
                    bill: bill,
                    paymentMethod: 'cash',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEBankingSheet({
    required Map<String, dynamic> bill,
  }) {
    final apps = [
      _PaymentApp(
        name: 'BCA Mobile',
        packageName: 'com.bca',
        icon: Icons.account_balance_rounded,
        color: const Color(0xFF60A5FA),
      ),
      _PaymentApp(
        name: 'Livin by Mandiri',
        packageName: 'id.bmri.livin',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFFFFD34D),
      ),
      _PaymentApp(
        name: 'BRImo',
        packageName: 'id.co.bri.brimo',
        icon: Icons.account_balance_rounded,
        color: const Color(0xFF3B82F6),
      ),
      _PaymentApp(
        name: 'BNI Mobile',
        packageName: 'src.com.bni',
        icon: Icons.account_balance_rounded,
        color: const Color(0xFFFF8A3D),
      ),
      _PaymentApp(
        name: 'DANA',
        packageName: 'id.dana',
        icon: Icons.wallet_rounded,
        color: const Color(0xFF38BDF8),
      ),
      _PaymentApp(
        name: 'GoPay / Gojek',
        packageName: 'com.gojek.app',
        icon: Icons.wallet_rounded,
        color: const Color(0xFF22C55E),
      ),
      _PaymentApp(
        name: 'OVO',
        packageName: 'ovo.id',
        icon: Icons.wallet_rounded,
        color: const Color(0xFFA855F7),
      ),
      _PaymentApp(
        name: 'ShopeePay',
        packageName: 'com.shopee.id',
        icon: Icons.shopping_bag_rounded,
        color: const Color(0xFFFF6B35),
      ),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _GlassBottomSheet(
          maxHeightFactor: 0.78,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetDragHandle(),
              const SizedBox(height: 18),
              const Text(
                'Choose E-Banking App',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Open your installed banking or payment app to pay.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.66),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: apps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final app = apps[index];

                    return _PaymentOptionTile(
                      icon: app.icon,
                      title: app.name,
                      subtitle: 'Open app',
                      iconColor: app.color,
                      onTap: () {
                        Navigator.pop(context);

                        _showSnackBar(
                          message:
                          'Opening ${app.name}. After payment, please wait for owner confirmation.',
                        );

                        _openExternalPaymentApp(
                          appName: app.name,
                          packageName: app.packageName,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openExternalPaymentApp({
    required String appName,
    required String packageName,
  }) async {
    final Uri appUri = Uri.parse('android-app://$packageName');
    final Uri intentUri = Uri.parse('intent://#Intent;package=$packageName;end');
    final Uri playStoreUri = Uri.parse('market://details?id=$packageName');
    final Uri webPlayStoreUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$packageName',
    );

    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(
          appUri,
          mode: LaunchMode.externalApplication,
        );
        return;
      }

      if (await canLaunchUrl(intentUri)) {
        await launchUrl(
          intentUri,
          mode: LaunchMode.externalApplication,
        );
        return;
      }

      if (await canLaunchUrl(playStoreUri)) {
        _showSnackBar(
          message: '$appName belum terpasang. Membuka Play Store.',
        );

        await launchUrl(
          playStoreUri,
          mode: LaunchMode.externalApplication,
        );
        return;
      }

      _showSnackBar(
        message: '$appName belum terpasang. Membuka halaman Play Store.',
      );

      await launchUrl(
        webPlayStoreUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      _showSnackBar(
        message: 'Tidak bisa membuka $appName.',
      );
    }
  }

  void _showSnackBar({
    required String message,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF071B14),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tenantProvider = Provider.of<TenantProvider>(context);

    final normalizedBills = _normalizeBills(tenantProvider.bills);
    final paidBills = _getPaidBills(normalizedBills);
    final unpaidBills = _getUnpaidBills(normalizedBills);

    final currentBillFromProvider = _getCurrentUnpaidBill(
      providerCurrentBill: tenantProvider.currentBill,
      allBills: normalizedBills,
    );

    final fallbackBill = _buildFallbackBill(tenantProvider);
    final displayedCurrentBill = currentBillFromProvider ?? fallbackBill;

    final baseRentAmount = _toDouble(
      displayedCurrentBill['base_amount'] ??
          tenantProvider.tenant?.basePrice ??
          0,
    );

    final additionalBillAmount = _toDouble(
      displayedCurrentBill['addon_amount'],
    );

    final totalBillAmount = _getBillTotal(displayedCurrentBill);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: darkGreen,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(82),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 38,
                  sigmaY: 38,
                ),
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.30),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.18),
                        blurRadius: 1,
                        offset: const Offset(0, -0.5),
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.22),
                        Colors.white.withOpacity(0.13),
                        Colors.white.withOpacity(0.08),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Center(
                        child: Text(
                          'My Kos',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 6,
                        child: IconButton(
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                          ),
                          splashRadius: 20,
                          onPressed: _logout,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: darkGreen,
          ),
          Positioned(
            top: -120,
            left: -90,
            child: _blurCircle(
              size: 310,
              color: const Color(0xFF6EE7B7).withOpacity(0.55),
            ),
          ),
          Positioned(
            top: 140,
            right: -140,
            child: _blurCircle(
              size: 390,
              color: const Color(0xFF22C55E).withOpacity(0.45),
            ),
          ),
          Positioned(
            bottom: 90,
            left: -140,
            child: _blurCircle(
              size: 360,
              color: const Color(0xFF10B981).withOpacity(0.42),
            ),
          ),
          Positioned(
            bottom: -130,
            right: -90,
            child: _blurCircle(
              size: 340,
              color: const Color(0xFFA7F3D0).withOpacity(0.35),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 75,
                sigmaY: 75,
              ),
              child: Container(
                color: Colors.white.withOpacity(0.015),
              ),
            ),
          ),
          SafeArea(
            child: tenantProvider.isLoading
                ? const Center(
              child: CircularProgressIndicator.adaptive(
                backgroundColor: Colors.white,
              ),
            )
                : RefreshIndicator(
              color: primaryGreen,
              backgroundColor: darkGreen,
              onRefresh: _refreshBills,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileGlassCard(
                      name: tenantProvider.tenant?.name ?? 'Tenant',
                      roomText:
                      'Room ${tenantProvider.tenant?.roomNumber ?? '-'} • ${tenantProvider.tenant?.roomType ?? '-'}',
                      baseRent: _formatRupiah(baseRentAmount),
                      additionalBill:
                      _formatRupiah(additionalBillAmount),
                      totalBill: _formatRupiah(totalBillAmount),
                      paidBills: paidBills.length.toString(),
                      primaryGreen: primaryGreen,
                      secondaryGreen: secondaryGreen,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Current Bill',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withOpacity(0.90),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CurrentBillCard(
                      bill: displayedCurrentBill,
                      currentBillTotal: totalBillAmount,
                      isOverdue: _isOverdue(
                        displayedCurrentBill['due_date'],
                      ),
                      formatRupiah: _formatRupiah,
                      primaryGreen: primaryGreen,
                      onPayNow: () {
                        _showPaymentMethodSheet(
                          bill: displayedCurrentBill,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Billing History',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withOpacity(0.90),
                            ),
                          ),
                        ),
                        if (paidBills.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: primaryGreen.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: primaryGreen.withOpacity(0.38),
                              ),
                            ),
                            child: Text(
                              '${paidBills.length} paid',
                              style: const TextStyle(
                                color: Color(0xFFB8FFE2),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (paidBills.isEmpty)
                      const _EmptyHistoryState()
                    else
                      ...paidBills.map((bill) {
                        return _HistoryBillCard(
                          bill: bill,
                          formatRupiah: _formatRupiah,
                        );
                      }),
                    if (unpaidBills.isNotEmpty &&
                        paidBills.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Unpaid bills are shown in Current Bill.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.52),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const _TopScrollShield(),
        ],
      ),
    );
  }
}

class _ProfileGlassCard extends StatelessWidget {
  final String name;
  final String roomText;
  final String baseRent;
  final String additionalBill;
  final String totalBill;
  final String paidBills;
  final Color primaryGreen;
  final Color secondaryGreen;

  const _ProfileGlassCard({
    required this.name,
    required this.roomText,
    required this.baseRent,
    required this.additionalBill,
    required this.totalBill,
    required this.paidBills,
    required this.primaryGreen,
    required this.secondaryGreen,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'T';

    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 85,
          sigmaY: 85,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            border: Border.all(
              color: Colors.white.withOpacity(0.34),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: primaryGreen.withOpacity(0.14),
                blurRadius: 34,
                offset: const Offset(0, 10),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryGreen.withOpacity(0.34),
                Colors.white.withOpacity(0.20),
                secondaryGreen.withOpacity(0.20),
                Colors.white.withOpacity(0.09),
              ],
              stops: const [0.0, 0.34, 0.68, 1.0],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryGreen,
                          secondaryGreen,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryGreen.withOpacity(0.38),
                          blurRadius: 20,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Color(0xFF062116),
                          fontWeight: FontWeight.w900,
                          fontSize: 27,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                  ),
                ),
                child: Text(
                  roomText,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.82),
                    fontSize: 12.2,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _ProfileStat(
                      label: 'Base Rent',
                      value: baseRent,
                      icon: Icons.payments_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ProfileStat(
                      label: 'Additional Bills',
                      value: additionalBill,
                      icon: Icons.add_circle_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ProfileStat(
                      label: 'Total Bill',
                      value: totalBill,
                      icon: Icons.receipt_long_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ProfileStat(
                      label: 'Bills Paid',
                      value: paidBills,
                      icon: Icons.check_circle_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProfileStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: const Color(0xFF34D399).withOpacity(0.18),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6EE7B7),
              size: 17,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFB8FFE2),
                    fontWeight: FontWeight.w900,
                    fontSize: 11.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.66),
                    fontSize: 9.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentBillCard extends StatelessWidget {
  final Map<String, dynamic> bill;
  final double currentBillTotal;
  final bool isOverdue;
  final String Function(dynamic) formatRupiah;
  final Color primaryGreen;
  final VoidCallback onPayNow;

  const _CurrentBillCard({
    required this.bill,
    required this.currentBillTotal,
    required this.isOverdue,
    required this.formatRupiah,
    required this.primaryGreen,
    required this.onPayNow,
  });

  @override
  Widget build(BuildContext context) {
    final penaltyAmount = double.tryParse('${bill['penalty_amount']}') ?? 0;

    final dueDateText = bill['due_date'] == null ||
        '${bill['due_date']}'.isEmpty ||
        '${bill['due_date']}' == 'null' ||
        '${bill['due_date']}' == '-'
        ? 'Not set yet'
        : '${bill['due_date']}';

    return _GlassSimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.17),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                  ),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: primaryGreen,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${bill['billing_month']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Due: $dueDateText',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isOverdue
                            ? const Color(0xFFFFB4AB)
                            : Colors.white.withOpacity(0.64),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Total to Pay',
            style: TextStyle(
              color: Colors.white.withOpacity(0.62),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            formatRupiah(currentBillTotal),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF6EE7B7),
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _BillDetail(
                  label: 'Base Rent',
                  value: formatRupiah(bill['base_amount']),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BillDetail(
                  label: 'Additional',
                  value: formatRupiah(bill['addon_amount']),
                ),
              ),
            ],
          ),
          if (penaltyAmount > 0) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _BillDetail(
                label: 'Penalty',
                value: formatRupiah(bill['penalty_amount']),
                isRed: true,
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onPayNow,
              icon: const Icon(Icons.payment_rounded),
              label: const Text('Pay Now'),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: primaryGreen,
                foregroundColor: const Color(0xFF062116),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillDetail extends StatelessWidget {
  final String label;
  final String value;
  final bool isRed;

  const _BillDetail({
    required this.label,
    required this.value,
    this.isRed = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isRed ? const Color(0xFFFFB4AB) : const Color(0xFFB8FFE2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.58),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryBillCard extends StatelessWidget {
  final Map<String, dynamic> bill;
  final String Function(dynamic) formatRupiah;

  const _HistoryBillCard({
    required this.bill,
    required this.formatRupiah,
  });

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF34D399);

    final paidDateText = bill['paid_date'] == null ||
        '${bill['paid_date']}'.isEmpty ||
        '${bill['paid_date']}' == 'null'
        ? '-'
        : '${bill['paid_date']}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: _GlassSimpleCard(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.16),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                ),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: color,
                size: 25,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${bill['billing_month']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Paid on $paidDateText',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.62),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              formatRupiah(bill['total_amount']),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF6EE7B7),
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return _GlassSimpleCard(
      child: Center(
        child: Text(
          'No paid bills yet',
          style: TextStyle(
            color: Colors.white.withOpacity(0.68),
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PaymentApp {
  final String name;
  final String packageName;
  final IconData icon;
  final Color color;

  const _PaymentApp({
    required this.name,
    required this.packageName,
    required this.icon,
    required this.color,
  });
}

class _PaymentOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const _PaymentOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 35,
            sigmaY: 35,
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.13),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.24),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        iconColor,
                        iconColor.withOpacity(0.72),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF062116),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.62),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.55),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimarySheetButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _PrimarySheetButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.textColor = const Color(0xFF062116),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: textColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetDragHandle extends StatelessWidget {
  const _SheetDragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.35),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _GlassBottomSheet extends StatelessWidget {
  final Widget child;
  final double maxHeightFactor;

  const _GlassBottomSheet({
    required this.child,
    this.maxHeightFactor = 0.70,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(30),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 45,
          sigmaY: 45,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * maxHeightFactor,
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: BoxDecoration(
            color: const Color(0xFF0F3D2E).withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(30),
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 28,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _GlassSimpleCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _GlassSimpleCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 85,
          sigmaY: 85,
        ),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: Colors.white.withOpacity(0.26),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.13),
                Colors.white.withOpacity(0.07),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _TopScrollShield extends StatelessWidget {
  const _TopScrollShield();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: MediaQuery.of(context).padding.top + 10,
      child: IgnorePointer(
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 35,
              sigmaY: 35,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0F3D2E).withOpacity(0.96),
                    const Color(0xFF0F3D2E).withOpacity(0.82),
                    const Color(0xFF0F3D2E).withOpacity(0.00),
                  ],
                  stops: const [0.0, 0.72, 1.0],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}