import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/analytics_provider.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final int tenantId;
  final String tenantName;

  const PaymentHistoryScreen({
    super.key,
    required this.tenantId,
    required this.tenantName,
  });

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token;

      if (token == null) return;

      Provider.of<AnalyticsProvider>(context, listen: false)
          .fetchPaymentHistory(token, widget.tenantId);
    });
  }

  String _formatRupiah(dynamic amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(double.parse(amount.toString()));
  }

  DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;

    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    return double.tryParse(value.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final analytics = Provider.of<AnalyticsProvider>(context);
    final history = analytics.paymentHistory;

    final totalPaid = history
        .where((b) => b['status'] == 'paid')
        .fold(0.0, (sum, b) => sum + _toDouble(b['total_amount']));

    final totalUnpaid = history
        .where((b) => b['status'] == 'unpaid')
        .fold(0.0, (sum, b) => sum + _toDouble(b['total_amount']));

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F3D2E),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(82),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 38, sigmaY: 38),
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
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 58),
                          child: Text(
                            'Payment History',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: Colors.white,
                            ),
                          ),
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
            color: const Color(0xFF0F3D2E),
          ),

          Positioned(
            top: -120,
            left: -90,
            child: _BlurBlob(
              size: 310,
              color: const Color(0xFF6EE7B7).withOpacity(0.55),
            ),
          ),

          Positioned(
            top: 130,
            right: -130,
            child: _BlurBlob(
              size: 390,
              color: const Color(0xFF22C55E).withOpacity(0.45),
            ),
          ),

          Positioned(
            bottom: 70,
            left: -140,
            child: _BlurBlob(
              size: 360,
              color: const Color(0xFF10B981).withOpacity(0.42),
            ),
          ),

          Positioned(
            bottom: -130,
            right: -90,
            child: _BlurBlob(
              size: 340,
              color: const Color(0xFFA7F3D0).withOpacity(0.35),
            ),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
              child: Container(
                color: Colors.white.withOpacity(0.015),
              ),
            ),
          ),

          SafeArea(
            child: analytics.isLoading
                ? const Center(
              child: CircularProgressIndicator.adaptive(
                backgroundColor: Colors.white,
              ),
            )
                : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTenantHeader(),

                  const SizedBox(height: 16),

                  _buildSummaryRow(
                    totalPaid: totalPaid,
                    totalUnpaid: totalUnpaid,
                  ),

                  const SizedBox(height: 22),

                  Padding(
                    padding: const EdgeInsets.only(
                      left: 4,
                      bottom: 12,
                    ),
                    child: Text(
                      'Billing Records',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: Colors.white.withOpacity(0.86),
                      ),
                    ),
                  ),

                  if (history.isEmpty)
                    _buildEmptyState()
                  else
                    Column(
                      children: history.map<Widget>((bill) {
                        return _buildHistoryCard(bill);
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantHeader() {
    return _LiquidGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF34D399),
                    Color(0xFF10B981),
                  ],
                ),
                borderRadius: BorderRadius.circular(17),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF34D399).withOpacity(0.32),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment history for',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    widget.tenantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Row(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        color: Colors.white.withOpacity(0.62),
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Monthly billing records',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.68),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required double totalPaid,
    required double totalUnpaid,
  }) {
    return Row(
      children: [
        Expanded(
          child: _SummaryGlassCard(
            title: 'Total Paid',
            amount: _formatRupiah(totalPaid),
            icon: Icons.check_circle_rounded,
            iconColor: const Color(0xFF34D399),
            tintColor: const Color(0xFF34D399).withOpacity(0.18),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _SummaryGlassCard(
            title: 'Total Unpaid',
            amount: _formatRupiah(totalUnpaid),
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFFF6B6B),
            tintColor: const Color(0xFFFF6B6B).withOpacity(0.15),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return _LiquidGlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 34,
        ),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.22),
                ),
              ),
              child: Icon(
                Icons.history_rounded,
                size: 34,
                color: Colors.white.withOpacity(0.82),
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'No payment history yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Billing records will appear here once available.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.66),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(dynamic bill) {
    final isPaid = bill['status'] == 'paid';

    final dueDate = _tryParseDate(bill['due_date']);
    final isOverdue = !isPaid &&
        dueDate != null &&
        dueDate.isBefore(DateTime.now());

    final penaltyAmount = _toDouble(bill['penalty_amount']);
    final addonAmount = _toDouble(bill['addon_amount']);

    final hasPenalty = penaltyAmount > 0;
    final hasAddon = addonAmount > 0;

    final Color statusColor = isPaid
        ? const Color(0xFF34D399)
        : isOverdue
        ? const Color(0xFFFF6B6B)
        : const Color(0xFFFFB74D);

    final String statusText = isPaid
        ? 'Paid'
        : isOverdue
        ? 'Overdue'
        : 'Unpaid';

    final IconData statusIcon = isPaid
        ? Icons.check_circle_rounded
        : isOverdue
        ? Icons.error_rounded
        : Icons.schedule_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: _LiquidGlassCard(
        tintColor: isOverdue
            ? const Color(0xFFFF6B6B).withOpacity(0.12)
            : Colors.white.withOpacity(0.13),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          statusColor,
                          statusColor.withOpacity(0.72),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      statusIcon,
                      color: const Color(0xFF062116),
                      size: 24,
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
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.2,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 13,
                              color: isOverdue
                                  ? const Color(0xFFFFB4B4)
                                  : Colors.white.withOpacity(0.60),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Due: ${bill['due_date']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isOverdue
                                      ? const Color(0xFFFFB4B4)
                                      : Colors.white.withOpacity(0.62),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatRupiah(bill['total_amount']),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: -0.3,
                        ),
                      ),

                      const SizedBox(height: 7),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: statusColor.withOpacity(0.35),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 10,
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (hasPenalty || hasAddon) ...[
                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  color: Colors.white.withOpacity(0.18),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _BillMiniInfo(
                        label: 'Base',
                        value: _formatRupiah(bill['base_amount']),
                        color: Colors.white.withOpacity(0.76),
                      ),
                    ),

                    if (hasAddon)
                      Expanded(
                        child: _BillMiniInfo(
                          label: 'Addons',
                          value: _formatRupiah(addonAmount),
                          color: const Color(0xFF2DD4BF),
                        ),
                      ),

                    if (hasPenalty)
                      Expanded(
                        child: _BillMiniInfo(
                          label: 'Penalty',
                          value: _formatRupiah(penaltyAmount),
                          color: const Color(0xFFFF6B6B),
                        ),
                      ),
                  ],
                ),
              ],

              if (isPaid && bill['paid_date'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34D399).withOpacity(0.13),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: const Color(0xFF34D399).withOpacity(0.28),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF34D399),
                        size: 15,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Paid on ${bill['paid_date']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB7F7D4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryGlassCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color iconColor;
  final Color tintColor;

  const _SummaryGlassCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    return _LiquidGlassCard(
      tintColor: tintColor,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.20),
                ),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.68),
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              amount,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontSize: 14,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillMiniInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BillMiniInfo({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.55),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final Color? tintColor;

  const _LiquidGlassCard({
    required this.child,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 95, sigmaY: 95),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: tintColor ?? Colors.white.withOpacity(0.16),
            border: Border.all(
              color: Colors.white.withOpacity(0.28),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 26,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.22),
                blurRadius: 1,
                offset: const Offset(0, -0.5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 42,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.26),
                        Colors.white.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),

              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _BlurBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _BlurBlob({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}