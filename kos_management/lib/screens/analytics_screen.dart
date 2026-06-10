import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/analytics_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  final int kosId;

  const AnalyticsScreen({
    super.key,
    required this.kosId,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final Color primaryGreen = const Color(0xFF34D399);
  final Color secondaryGreen = const Color(0xFF10B981);
  final Color darkGreen = const Color(0xFF0F3D2E);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAnalytics();
    });
  }

  Future<void> _fetchAnalytics() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final analytics = Provider.of<AnalyticsProvider>(context, listen: false);

    if (auth.token == null) return;

    await analytics.fetchStats(
      auth.token!,
      widget.kosId,
    );
  }

  String _formatRupiah(dynamic amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final value = double.tryParse(amount.toString()) ?? 0;
    return formatter.format(value);
  }

  double _toDouble(dynamic value) {
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Color _getOccupancyColor(num rate) {
    if (rate >= 80) return const Color(0xFF34D399);
    if (rate >= 50) return const Color(0xFFFBBF24);
    return const Color(0xFFFF6B6B);
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
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
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
                ),
              ),
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
    final analytics = Provider.of<AnalyticsProvider>(context);

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
                          'Analytics',
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
                          onPressed: _fetchAnalytics,
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
            child: analytics.isLoading
                ? const Center(
              child: CircularProgressIndicator.adaptive(
                backgroundColor: Colors.white,
              ),
            )
                : RefreshIndicator(
              color: primaryGreen,
              backgroundColor: darkGreen,
              onRefresh: _fetchAnalytics,
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
                              Icons.analytics_rounded,
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
                                  'Kos Performance',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Track income, unpaid bills, occupancy, and recent billing activity.',
                                  style: TextStyle(
                                    color:
                                    Colors.white.withOpacity(0.68),
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
                        _StatCard(
                          label: 'Monthly Income',
                          value: _formatRupiah(
                            analytics.monthlyIncome,
                          ),
                          icon: Icons.trending_up_rounded,
                          color: const Color(0xFF34D399),
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          label: 'Unpaid',
                          value: _formatRupiah(
                            analytics.unpaidAmount,
                          ),
                          icon: Icons.pending_actions_rounded,
                          color: const Color(0xFFFF6B6B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StatCard(
                          label: 'Total Tenants',
                          value: analytics.totalTenants.toString(),
                          icon: Icons.people_rounded,
                          color: const Color(0xFF60A5FA),
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          label: 'Unpaid Bills',
                          value: analytics.unpaidCount.toString(),
                          icon: Icons.receipt_long_rounded,
                          color: const Color(0xFFFBBF24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _OccupancyGlassCard(
                      totalRooms: analytics.totalRooms,
                      occupiedRooms: analytics.occupiedRooms,
                      availableRooms: analytics.availableRooms,
                      occupancyRate: analytics.occupancyRate,
                      color: _getOccupancyColor(
                        analytics.occupancyRate,
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (analytics.chartData.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          'Monthly Billing',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withOpacity(0.90),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _liquidGlassContainer(
                        borderRadius: 28,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children:
                          analytics.chartData.map<Widget>((month) {
                            final paid = _toDouble(month['paid']);
                            final unpaid = _toDouble(month['unpaid']);
                            final total = paid + unpaid;
                            final paidRatio =
                            total > 0 ? paid / total : 0.0;

                            return _MonthlyBillingRow(
                              month:
                              '${month['billing_month'] ?? '-'}',
                              totalText: _formatRupiah(total),
                              paidText: _formatRupiah(paid),
                              unpaidText: _formatRupiah(unpaid),
                              paidRatio: paidRatio,
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],
                    if (analytics.recentActivity.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withOpacity(0.90),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...analytics.recentActivity.map((activity) {
                        final isPaid = activity['status'] == 'paid';

                        return _RecentActivityCard(
                          tenantName:
                          '${activity['tenant_name'] ?? '-'}',
                          roomNumber:
                          '${activity['room_number'] ?? '-'}',
                          billingMonth:
                          '${activity['billing_month'] ?? '-'}',
                          totalAmount: _formatRupiah(
                            _toDouble(activity['total_amount']),
                          ),
                          isPaid: isPaid,
                        );
                      }),
                    ],
                    if (analytics.chartData.isEmpty &&
                        analytics.recentActivity.isEmpty)
                      const _EmptyAnalyticsState(),
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
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
              horizontal: 12,
              vertical: 15,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
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

class _OccupancyGlassCard extends StatelessWidget {
  final int totalRooms;
  final int occupiedRooms;
  final int availableRooms;
  final num occupancyRate;
  final Color color;

  const _OccupancyGlassCard({
    required this.totalRooms,
    required this.occupiedRooms,
    required this.availableRooms,
    required this.occupancyRate,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (occupancyRate / 100).clamp(0.0, 1.0).toDouble();

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 85,
          sigmaY: 85,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.28),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.26),
                Colors.white.withOpacity(0.13),
                Colors.white.withOpacity(0.07),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
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
                  const Expanded(
                    child: Text(
                      'Room Occupancy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '$occupancyRate%',
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 13,
                      color: Colors.white.withOpacity(0.14),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 13,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _OccupancyPill(
                    label: 'Total',
                    value: totalRooms,
                    color: Colors.white.withOpacity(0.72),
                  ),
                  const SizedBox(width: 8),
                  _OccupancyPill(
                    label: 'Occupied',
                    value: occupiedRooms,
                    color: const Color(0xFF34D399),
                  ),
                  const SizedBox(width: 8),
                  _OccupancyPill(
                    label: 'Available',
                    value: availableRooms,
                    color: const Color(0xFF60A5FA),
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

class _OccupancyPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _OccupancyPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withOpacity(0.18),
          ),
        ),
        child: Text(
          '$label: $value',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.5,
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MonthlyBillingRow extends StatelessWidget {
  final String month;
  final String totalText;
  final String paidText;
  final String unpaidText;
  final double paidRatio;

  const _MonthlyBillingRow({
    required this.month,
    required this.totalText,
    required this.paidText,
    required this.unpaidText,
    required this.paidRatio,
  });

  @override
  Widget build(BuildContext context) {
    final safeRatio = paidRatio.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  month,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                totalText,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.66),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(
                  height: 11,
                  width: double.infinity,
                  color: const Color(0xFFFF6B6B).withOpacity(0.28),
                ),
                FractionallySizedBox(
                  widthFactor: safeRatio,
                  child: Container(
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF34D399),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _ChartLegend(
                color: const Color(0xFF34D399),
                label: 'Paid $paidText',
              ),
              _ChartLegend(
                color: const Color(0xFFFF6B6B),
                label: 'Unpaid $unpaidText',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: Colors.white.withOpacity(0.64),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  final String tenantName;
  final String roomNumber;
  final String billingMonth;
  final String totalAmount;
  final bool isPaid;

  const _RecentActivityCard({
    required this.tenantName,
    required this.roomNumber,
    required this.billingMonth,
    required this.totalAmount,
    required this.isPaid,
  });

  @override
  Widget build(BuildContext context) {
    final color =
    isPaid ? const Color(0xFF34D399) : const Color(0xFFFBBF24);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 80,
            sigmaY: 80,
          ),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.24),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.22),
                  Colors.white.withOpacity(0.11),
                  Colors.white.withOpacity(0.06),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
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
                  child: Icon(
                    isPaid
                        ? Icons.check_circle_rounded
                        : Icons.pending_actions_rounded,
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
                        tenantName,
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
                        'Room $roomNumber • $billingMonth',
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      totalAmount,
                      style: const TextStyle(
                        color: Color(0xFF6EE7B7),
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: color.withOpacity(0.38),
                        ),
                      ),
                      child: Text(
                        isPaid ? 'Paid' : 'Unpaid',
                        style: TextStyle(
                          color: color,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyAnalyticsState extends StatelessWidget {
  const _EmptyAnalyticsState();

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
                  Icons.analytics_outlined,
                  size: 32,
                  color: Color(0xFF6EE7B7),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'No analytics data yet\nGenerate bills or add tenant activity to view analytics',
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