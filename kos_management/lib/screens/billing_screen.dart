import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/bill_provider.dart';
import '../utils/whatsapp_helper.dart';
import '../utils/email_helper.dart';

class BillingScreen extends StatefulWidget {
  final int kosId;

  const BillingScreen({
    super.key,
    required this.kosId,
  });

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  String _filter = 'all';
  bool _isGenerating = false;
  final Set<int> _payingBillIds = {};

  final Color primaryGreen = const Color(0xFF34D399);
  final Color secondaryGreen = const Color(0xFF10B981);
  final Color darkGreen = const Color(0xFF0F3D2E);

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshBills();
    });
  }

  double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  int? _toInt(dynamic value) {
    return int.tryParse(value?.toString() ?? '');
  }

  String _formatRupiah(dynamic amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final value = _toDouble(amount);
    return formatter.format(value);
  }

  List<dynamic> _getFilteredBills(List<dynamic> bills) {
    final now = DateTime.now();

    switch (_filter) {
      case 'unpaid':
        return bills.where((b) => b['status'] == 'unpaid').toList();

      case 'paid':
        return bills.where((b) => b['status'] == 'paid').toList();

      case 'overdue':
        return bills.where((b) {
          final dueDate = DateTime.tryParse('${b['due_date']}');
          if (dueDate == null) return false;

          return b['status'] == 'unpaid' && dueDate.isBefore(now);
        }).toList();

      default:
        return bills;
    }
  }

  Future<void> _refreshBills() async {
    final auth = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    final bill = Provider.of<BillProvider>(
      context,
      listen: false,
    );

    if (auth.token == null) return;

    await bill.fetchBills(
      auth.token!,
      widget.kosId,
    );
  }

  Future<void> _markPaid(int billId) async {
    if (_payingBillIds.contains(billId)) return;

    final auth = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    final bill = Provider.of<BillProvider>(
      context,
      listen: false,
    );

    if (auth.token == null) return;

    setState(() {
      _payingBillIds.add(billId);
    });

    final success = await bill.markPaid(
      auth.token!,
      billId,
      widget.kosId,
    );

    await bill.fetchBills(
      auth.token!,
      widget.kosId,
    );

    if (!mounted) return;

    setState(() {
      _payingBillIds.remove(billId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Bill marked as paid!'
              : (bill.errorMessage ?? 'Failed to mark bill as paid'),
        ),
        backgroundColor:
        success ? const Color(0xFF10B981) : const Color(0xFFFF3B30),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Future<void> _generateBills() async {
    if (_isGenerating) return;

    final auth = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    final bill = Provider.of<BillProvider>(
      context,
      listen: false,
    );

    if (auth.token == null) return;

    setState(() {
      _isGenerating = true;
    });

    final success = await bill.generateBills(
      auth.token!,
      widget.kosId,
    );

    await bill.fetchBills(
      auth.token!,
      widget.kosId,
    );

    if (!mounted) return;

    setState(() {
      _isGenerating = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Bills generated successfully!'
              : (bill.errorMessage ?? 'Failed to generate bills'),
        ),
        backgroundColor:
        success ? const Color(0xFF10B981) : const Color(0xFFFF3B30),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
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

  Widget _liquidGlassContainer({
    required Widget child,
    double borderRadius = 28,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 85,
          sigmaY: 85,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.30),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.22),
                blurRadius: 1,
                offset: const Offset(0, -0.5),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.30),
                Colors.white.withOpacity(0.16),
                Colors.white.withOpacity(0.08),
              ],
              stops: const [0.0, 0.48, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.24),
                          Colors.white.withOpacity(0.07),
                          Colors.white.withOpacity(0.00),
                        ],
                        stops: const [0.0, 0.42, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: padding,
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bill = Provider.of<BillProvider>(context);
    final filtered = _getFilteredBills(bill.bills);
    final now = DateTime.now();

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
                      Positioned(
                        left: 6,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                          splashRadius: 20,
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                      const Center(
                        child: Text(
                          'Billing',
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
                            Icons.refresh_rounded,
                            color: Colors.white,
                          ),
                          splashRadius: 20,
                          onPressed: bill.isLoading ? null : _refreshBills,
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
            child: bill.isLoading && bill.bills.isEmpty
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
                    _liquidGlassContainer(
                      borderRadius: 34,
                      padding: const EdgeInsets.all(22),
                      child: Row(
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
                                  color: primaryGreen.withOpacity(0.32),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: Color(0xFF062116),
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Billing Summary',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Track bills, payments, and overdue tenants',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.68),
                                    fontSize: 13,
                                    height: 1.25,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _SummaryCard(
                          label: 'Total Bills',
                          value: bill.totalBills.toString(),
                          color: const Color(0xFF60A5FA),
                          icon: Icons.receipt_long_rounded,
                        ),
                        const SizedBox(width: 10),
                        _SummaryCard(
                          label: 'Unpaid',
                          value: bill.unpaidCount.toString(),
                          color: const Color(0xFFFBBF24),
                          icon: Icons.pending_actions_rounded,
                        ),
                        const SizedBox(width: 10),
                        _SummaryCard(
                          label: 'Paid',
                          value: bill.paidCount.toString(),
                          color: const Color(0xFF34D399),
                          icon: Icons.check_circle_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _liquidGlassContainer(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B6B)
                                  .withOpacity(0.18),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                              ),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Color(0xFFFFB4AB),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Unpaid Amount',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.68),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _formatRupiah(
                                    bill.totalUnpaidAmount,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFFFB4AB),
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: bill.isLoading || _isGenerating
                            ? null
                            : _generateBills,
                        icon: _isGenerating
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Color(0xFF062116),
                          ),
                        )
                            : const Icon(Icons.auto_awesome_rounded),
                        label: Text(
                          _isGenerating
                              ? 'Generating Bills...'
                              : 'Generate Bills Now',
                        ),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: primaryGreen,
                          disabledBackgroundColor:
                          primaryGreen.withOpacity(0.35),
                          foregroundColor: const Color(0xFF062116),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        'Bills',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withOpacity(0.90),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All',
                            selected: _filter == 'all',
                            onTap: () {
                              setState(() => _filter = 'all');
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Unpaid',
                            selected: _filter == 'unpaid',
                            onTap: () {
                              setState(() => _filter = 'unpaid');
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Paid',
                            selected: _filter == 'paid',
                            onTap: () {
                              setState(() => _filter = 'paid');
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Overdue',
                            selected: _filter == 'overdue',
                            onTap: () {
                              setState(() => _filter = 'overdue');
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (filtered.isEmpty)
                      _EmptyBillState(filter: _filter)
                    else
                      ...filtered.map((b) {
                        final isPaid = b['status'] == 'paid';

                        final dueDate =
                            DateTime.tryParse('${b['due_date']}') ??
                                DateTime.now();

                        final isOverdue =
                            !isPaid && dueDate.isBefore(now);

                        final penalty = _toDouble(b['penalty_amount']);
                        final hasPenalty = penalty > 0;

                        final billId = _toInt(b['id']);
                        final isPaying = billId != null &&
                            _payingBillIds.contains(billId);

                        return _BillGlassCard(
                          bill: b,
                          isPaid: isPaid,
                          isOverdue: isOverdue,
                          hasPenalty: hasPenalty,
                          formatRupiah: _formatRupiah,
                          dueDate: dueDate,
                          isPaying: isPaying,
                          onMarkPaid: billId == null
                              ? null
                              : () => _markPaid(billId),
                        );
                      }),
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

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 70,
            sigmaY: 70,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.26),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.22),
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.07),
                ],
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 23,
                ),
                const SizedBox(height: 7),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.white.withOpacity(0.66),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF34D399);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withOpacity(0.24)
              : Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? activeColor : Colors.white.withOpacity(0.22),
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected
              ? [
            BoxShadow(
              color: activeColor.withOpacity(0.20),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white.withOpacity(0.64),
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _BillGlassCard extends StatelessWidget {
  final dynamic bill;
  final bool isPaid;
  final bool isOverdue;
  final bool hasPenalty;
  final String Function(dynamic amount) formatRupiah;
  final DateTime dueDate;
  final bool isPaying;
  final VoidCallback? onMarkPaid;

  const _BillGlassCard({
    required this.bill,
    required this.isPaid,
    required this.isOverdue,
    required this.hasPenalty,
    required this.formatRupiah,
    required this.dueDate,
    required this.isPaying,
    required this.onMarkPaid,
  });

  double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  String _safeText(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty || text == 'null' ? fallback : text;
  }

  double _getAddonAmount({
    required double baseAmount,
    required double penaltyAmount,
    required double rawAddonAmount,
    required double totalAmount,
  }) {
    final inferredAddonAmount = totalAmount - baseAmount - penaltyAmount;

    if (rawAddonAmount > 0) {
      return rawAddonAmount;
    }

    if (inferredAddonAmount > 0) {
      return inferredAddonAmount;
    }

    return 0.0;
  }

  double _getDisplayTotalAmount({
    required double baseAmount,
    required double addonAmount,
    required double penaltyAmount,
    required double totalAmount,
  }) {
    if (totalAmount > 0) {
      return totalAmount;
    }

    return baseAmount + addonAmount + penaltyAmount;
  }

  void _openWhatsApp(BuildContext context) {
    final tenantName = _safeText(bill['tenant_name'], 'Tenant');
    final phone = _safeText(bill['phone'], '');
    final billingMonth = _safeText(bill['billing_month'], '-');
    final dueDateText = DateFormat('dd MMM yyyy').format(dueDate);

    final baseAmount = _toDouble(bill['base_amount']);
    final penaltyAmount = _toDouble(bill['penalty_amount']);
    final rawAddonAmount = _toDouble(bill['addon_amount']);
    final totalAmount = _toDouble(bill['total_amount']);

    final addonAmount = _getAddonAmount(
      baseAmount: baseAmount,
      penaltyAmount: penaltyAmount,
      rawAddonAmount: rawAddonAmount,
      totalAmount: totalAmount,
    );

    final displayTotalAmount = _getDisplayTotalAmount(
      baseAmount: baseAmount,
      addonAmount: addonAmount,
      penaltyAmount: penaltyAmount,
      totalAmount: totalAmount,
    );

    if (isPaid) {
      WhatsAppHelper.openPaymentReceivedMessage(
        context: context,
        phone: phone,
        tenantName: tenantName,
        billingMonth: billingMonth,
        totalAmount: formatRupiah(displayTotalAmount),
        paidDate: _safeText(
          bill['paid_date'],
          DateFormat('dd MMM yyyy').format(DateTime.now()),
        ),
      );
      return;
    }

    WhatsAppHelper.openBillReminder(
      context: context,
      phone: phone,
      tenantName: tenantName,
      billingMonth: billingMonth,
      totalAmount: formatRupiah(displayTotalAmount),
      dueDate: dueDateText,
      baseRent: formatRupiah(baseAmount),
      addonAmount: formatRupiah(addonAmount),
      penaltyAmount: penaltyAmount > 0 ? formatRupiah(penaltyAmount) : null,
    );
  }

  void _openEmail(BuildContext context) {
    final tenantName = _safeText(bill['tenant_name'], 'Tenant');

    final email = _safeText(
      bill['email'] ?? bill['tenant_email'],
      '',
    );

    final billingMonth = _safeText(bill['billing_month'], '-');
    final dueDateText = DateFormat('dd MMM yyyy').format(dueDate);

    final baseAmount = _toDouble(bill['base_amount']);
    final penaltyAmount = _toDouble(bill['penalty_amount']);
    final rawAddonAmount = _toDouble(bill['addon_amount']);
    final totalAmount = _toDouble(bill['total_amount']);

    final addonAmount = _getAddonAmount(
      baseAmount: baseAmount,
      penaltyAmount: penaltyAmount,
      rawAddonAmount: rawAddonAmount,
      totalAmount: totalAmount,
    );

    final displayTotalAmount = _getDisplayTotalAmount(
      baseAmount: baseAmount,
      addonAmount: addonAmount,
      penaltyAmount: penaltyAmount,
      totalAmount: totalAmount,
    );

    if (isPaid) {
      EmailHelper.openPaymentReceivedEmail(
        context: context,
        email: email,
        tenantName: tenantName,
        billingMonth: billingMonth,
        totalAmount: formatRupiah(displayTotalAmount),
        paidDate: _safeText(
          bill['paid_date'],
          DateFormat('dd MMM yyyy').format(DateTime.now()),
        ),
      );
      return;
    }

    EmailHelper.openBillReminderEmail(
      context: context,
      email: email,
      tenantName: tenantName,
      billingMonth: billingMonth,
      totalAmount: formatRupiah(displayTotalAmount),
      dueDate: dueDateText,
      baseRent: formatRupiah(baseAmount),
      addonAmount: formatRupiah(addonAmount),
      penaltyAmount: penaltyAmount > 0 ? formatRupiah(penaltyAmount) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseAmount = _toDouble(bill['base_amount']);
    final penaltyAmount = _toDouble(bill['penalty_amount']);
    final rawAddonAmount = _toDouble(bill['addon_amount']);
    final totalAmount = _toDouble(bill['total_amount']);

    final addonAmount = _getAddonAmount(
      baseAmount: baseAmount,
      penaltyAmount: penaltyAmount,
      rawAddonAmount: rawAddonAmount,
      totalAmount: totalAmount,
    );

    final displayTotalAmount = _getDisplayTotalAmount(
      baseAmount: baseAmount,
      addonAmount: addonAmount,
      penaltyAmount: penaltyAmount,
      totalAmount: totalAmount,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 85,
            sigmaY: 85,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: isOverdue
                    ? const Color(0xFFFF6B6B).withOpacity(0.70)
                    : Colors.white.withOpacity(0.26),
                width: isOverdue ? 1.4 : 1,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _safeText(bill['tenant_name'], 'Tenant'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15.5,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Room ${_safeText(bill['room_number'], '-')} • ${_safeText(bill['billing_month'], '-')}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.62),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(
                      isPaid: isPaid,
                      isOverdue: isOverdue,
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Divider(
                  height: 1,
                  color: Colors.white.withOpacity(0.16),
                ),
                const SizedBox(height: 13),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BillRow(
                      label: 'Base rent',
                      value: formatRupiah(baseAmount),
                    ),
                    _BillRow(
                      label: 'Add-ons',
                      value: formatRupiah(addonAmount),
                    ),
                    if (penaltyAmount > 0)
                      _BillRow(
                        label: 'Late penalty',
                        value: formatRupiah(penaltyAmount),
                        isRed: true,
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Divider(
                        height: 1,
                        color: Colors.white.withOpacity(0.14),
                      ),
                    ),
                    _BillRow(
                      label: 'Total bill',
                      value: formatRupiah(displayTotalAmount),
                      isBold: true,
                    ),
                    const SizedBox(height: 4),
                    _BillRow(
                      label: 'Due date',
                      value: DateFormat('dd MMM yyyy').format(dueDate),
                      isRed: isOverdue,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openWhatsApp(context),
                        icon: const Icon(
                          Icons.chat_rounded,
                          size: 17,
                        ),
                        label: Text(
                          isPaid ? 'WA Receipt' : 'WA',
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: const Color(0xFF062116),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 13,
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openEmail(context),
                        icon: const Icon(
                          Icons.email_rounded,
                          size: 17,
                        ),
                        label: Text(
                          isPaid ? 'Email Receipt' : 'Email',
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFF60A5FA),
                          foregroundColor: const Color(0xFF061626),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 13,
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isPaid) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isPaying ? null : onMarkPaid,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF34D399),
                        disabledBackgroundColor:
                        const Color(0xFF34D399).withOpacity(0.35),
                        foregroundColor: const Color(0xFF062116),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 13,
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      child: isPaying
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Color(0xFF062116),
                        ),
                      )
                          : const Text('Mark Paid'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isPaid;
  final bool isOverdue;

  const _StatusBadge({
    required this.isPaid,
    required this.isOverdue,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    if (isPaid) {
      color = const Color(0xFF34D399);
      label = 'Paid';
    } else if (isOverdue) {
      color = const Color(0xFFFF6B6B);
      label = 'Overdue';
    } else {
      color = const Color(0xFFFBBF24);
      label = 'Unpaid';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.38),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isRed;

  const _BillRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isRed = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = isRed
        ? const Color(0xFFFFB4AB)
        : isBold
        ? const Color(0xFF6EE7B7)
        : Colors.white.withOpacity(0.86);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.58),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.48),
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isBold ? 13 : 12,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBillState extends StatelessWidget {
  final String filter;

  const _EmptyBillState({
    required this.filter,
  });

  String get _emptyText {
    switch (filter) {
      case 'unpaid':
        return 'No unpaid bills';
      case 'paid':
        return 'No paid bills';
      case 'overdue':
        return 'No overdue bills';
      default:
        return 'No bills yet\nTap "Generate Bills Now" to start';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 85,
          sigmaY: 85,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 34,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.26),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.24),
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.07),
              ],
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                  ),
                ),
                child: const Icon(
                  Icons.receipt_outlined,
                  size: 32,
                  color: Color(0xFF6EE7B7),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _emptyText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.70),
                  fontSize: 13.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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