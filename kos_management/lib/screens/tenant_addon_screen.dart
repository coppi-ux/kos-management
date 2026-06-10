import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/addon_provider.dart';

class TenantAddonScreen extends StatefulWidget {
  final int tenantId;
  final String tenantName;
  final int kosId;

  const TenantAddonScreen({
    super.key,
    required this.tenantId,
    required this.tenantName,
    required this.kosId,
  });

  @override
  State<TenantAddonScreen> createState() => _TenantAddonScreenState();
}

class _TenantAddonScreenState extends State<TenantAddonScreen> {
  final Color primaryGreen = const Color(0xFF34D399);
  final Color secondaryGreen = const Color(0xFF10B981);
  final Color darkGreen = const Color(0xFF0F3D2E);

  int? _removingAddonId;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshData();
    });
  }

  String _normalizeName(String value) {
    return value
        .replaceAll('&amp;amp;amp;', '&')
        .replaceAll('&amp;amp;', '&')
        .replaceAll('&amp;', '&')
        .replaceAll('  ', ' ')
        .trim()
        .toLowerCase();
  }

  String _safeText(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty || text == 'null') {
      return fallback;
    }

    return text
        .replaceAll('&amp;amp;amp;', '&')
        .replaceAll('&amp;amp;', '&')
        .replaceAll('&amp;', '&');
  }

  int _parseId(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0.0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 1;
  }

  String _getAddonName(dynamic item) {
    return _safeText(
      item['name'] ??
          item['addon_name'] ??
          item['addonName'] ??
          item['item_name'] ??
          item['title'],
      'Unknown Add-on',
    );
  }

  double _getAddonPrice(dynamic item) {
    return _toDouble(
      item['price'] ??
          item['addon_price'] ??
          item['amount'] ??
          item['monthly_price'] ??
          item['subtotal'] ??
          0,
    );
  }

  int _getAddonQuantity(dynamic item) {
    final quantity = _toInt(
      item['quantity'] ??
          item['qty'] ??
          item['addon_quantity'] ??
          item['addon_qty'] ??
          1,
    );

    if (quantity <= 0) return 1;
    return quantity;
  }

  int _getAddonId(dynamic item) {
    return _parseId(
      item['addon_id'] ??
          item['addonId'] ??
          item['id'] ??
          item['tenant_addon_id'] ??
          item['tenantAddonId'],
    );
  }

  int _getTenantIdFromAddon(dynamic item) {
    return _parseId(
      item['tenant_id'] ??
          item['tenantId'] ??
          item['room_tenant_id'] ??
          item['roomTenantId'],
    );
  }

  bool _belongsToCurrentTenant(dynamic item) {
    final itemTenantId = _getTenantIdFromAddon(item);

    if (itemTenantId == 0) {
      return true;
    }

    return itemTenantId == widget.tenantId;
  }

  List<dynamic> _getCurrentTenantAddons(List<dynamic> rawTenantAddons) {
    return rawTenantAddons.where(_belongsToCurrentTenant).toList();
  }

  String _formatRupiah(dynamic amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return formatter.format(_toDouble(amount));
  }

  double _getTotalAddonPrice(List<dynamic> tenantAddons) {
    return tenantAddons.fold(0.0, (sum, item) {
      final price = _getAddonPrice(item);
      final quantity = _getAddonQuantity(item);

      return sum + (price * quantity);
    });
  }

  IconData _getAddonIconByName(String name) {
    final lowerName = _normalizeName(name);

    if (lowerName == 'bedding set') return Icons.bed_rounded;
    if (lowerName == 'bath essentials') return Icons.bathtub_rounded;
    if (lowerName == 'dining set') return Icons.restaurant_rounded;
    if (lowerName == 'cleaning kit') return Icons.cleaning_services_rounded;
    if (lowerName == 'cooking tools') return Icons.soup_kitchen_rounded;
    if (lowerName == 'rice cooker') return Icons.rice_bowl_rounded;
    if (lowerName == 'iron') return Icons.iron_rounded;
    if (lowerName == 'power strip & emergency light') {
      return Icons.electrical_services_rounded;
    }
    if (lowerName == 'first aid kit') return Icons.medical_services_rounded;
    if (lowerName == 'clothes hangers') return Icons.checkroom_rounded;
    if (lowerName == 'laundry basket') {
      return Icons.local_laundry_service_rounded;
    }
    if (lowerName == 'clothing & daily accessories') {
      return Icons.shopping_bag_rounded;
    }
    if (lowerName == 'sewing kit') return Icons.content_cut_rounded;
    if (lowerName == 'prayer kit') return Icons.menu_book_rounded;
    if (lowerName == 'trash bin') return Icons.delete_rounded;
    if (lowerName.contains('wifi')) return Icons.wifi_rounded;
    if (lowerName.contains('parking')) return Icons.local_parking_rounded;
    if (lowerName.contains('laundry')) {
      return Icons.local_laundry_service_rounded;
    }
    if (lowerName.contains('electric') || lowerName.contains('listrik')) {
      return Icons.bolt_rounded;
    }
    if (lowerName.contains('water') || lowerName.contains('air')) {
      return Icons.water_drop_rounded;
    }
    if (lowerName.contains('clean')) return Icons.cleaning_services_rounded;
    if (lowerName.contains('ac')) return Icons.ac_unit_rounded;

    return Icons.extension_rounded;
  }

  Future<void> _refreshData() async {
    final auth = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    final addon = Provider.of<AddonProvider>(
      context,
      listen: false,
    );

    final token = auth.token;

    if (token == null || token.isEmpty) {
      _showSnackBar(
        'Session expired, please login again',
        const Color(0xFFFF3B30),
      );
      return;
    }

    await addon.fetchTenantAddons(
      token,
      widget.tenantId,
    );

    await addon.fetchKosAddons(
      token,
      widget.kosId,
    );
  }

  Future<void> _removeTenantAddon(
      int addonId,
      String addonName,
      ) async {
    final auth = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    final addon = Provider.of<AddonProvider>(
      context,
      listen: false,
    );

    final token = auth.token;

    if (token == null || token.isEmpty) {
      _showSnackBar(
        'Session expired, please login again',
        const Color(0xFFFF3B30),
      );
      return;
    }

    if (addonId <= 0) {
      _showSnackBar(
        'Invalid add-on selected.',
        const Color(0xFFFF3B30),
      );
      return;
    }

    setState(() {
      _removingAddonId = addonId;
    });

    final success = await addon.removeAddon(
      token,
      widget.tenantId,
      addonId,
    );

    if (!mounted) return;

    if (success) {
      await _refreshData();

      if (!mounted) return;

      _showSnackBar(
        '$addonName removed',
        const Color(0xFFFBBF24),
      );
    } else {
      _showSnackBar(
        addon.errorMessage ?? 'Failed to remove add-on',
        const Color(0xFFFF3B30),
      );
    }

    if (!mounted) return;

    setState(() {
      _removingAddonId = null;
    });
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
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
    final addon = Provider.of<AddonProvider>(context);

    final tenantAddons = _getCurrentTenantAddons(addon.tenantAddons);
    final totalAddonPrice = _getTotalAddonPrice(tenantAddons);

    final isInitialLoading =
        addon.isFetchingTenantAddons && tenantAddons.isEmpty;

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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 58),
                        child: Center(
                          child: Text(
                            'Add-ons — ${widget.tenantName}',
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
                      Positioned(
                        right: 6,
                        child: IconButton(
                          icon: addon.isFetchingTenantAddons
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                          ),
                          splashRadius: 20,
                          onPressed:
                          addon.isFetchingTenantAddons ? null : _refreshData,
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
            child: isInitialLoading
                ? const Center(
              child: CircularProgressIndicator.adaptive(
                backgroundColor: Colors.white,
              ),
            )
                : RefreshIndicator(
              color: primaryGreen,
              backgroundColor: darkGreen,
              onRefresh: _refreshData,
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
                              Icons.person_rounded,
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
                                Text(
                                  widget.tenantName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${tenantAddons.length} add-on(s) assigned to this tenant',
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
                              color: primaryGreen.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                              ),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Color(0xFF6EE7B7),
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
                                  'Monthly add-on total',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.68),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _formatRupiah(totalAddonPrice),
                                  style: const TextStyle(
                                    color: Color(0xFF6EE7B7),
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
                    const SizedBox(height: 22),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        'Assigned Add-ons',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withOpacity(0.90),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        'These are add-ons currently assigned to ${widget.tenantName}.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.62),
                          fontSize: 12.5,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (addon.errorMessage != null) ...[
                      _GlassMessageBox(
                        message: addon.errorMessage!,
                        isError: true,
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (tenantAddons.isEmpty)
                      _EmptyTenantAddonState(
                        tenantName: widget.tenantName,
                      )
                    else
                      ...tenantAddons.map((item) {
                        final addonId = _getAddonId(item);
                        final addonName = _getAddonName(item);
                        final addonPrice = _getAddonPrice(item);
                        final addonQuantity = _getAddonQuantity(item);
                        final itemTotal = addonPrice * addonQuantity;

                        return _TenantAddonCard(
                          name: addonName,
                          price: _formatRupiah(addonPrice),
                          totalPrice: _formatRupiah(itemTotal),
                          quantity: addonQuantity,
                          icon: _getAddonIconByName(addonName),
                          isLoading: _removingAddonId == addonId,
                          onRemove: () {
                            _removeTenantAddon(
                              addonId,
                              addonName,
                            );
                          },
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

class _TenantAddonCard extends StatelessWidget {
  final String name;
  final String price;
  final String totalPrice;
  final int quantity;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onRemove;

  const _TenantAddonCard({
    required this.name,
    required this.price,
    required this.totalPrice,
    required this.quantity,
    required this.icon,
    required this.isLoading,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF34D399);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 85,
            sigmaY: 85,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: activeColor.withOpacity(0.70),
                width: 1.4,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  activeColor.withOpacity(0.22),
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.07),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withOpacity(0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
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
                        color: activeColor.withOpacity(0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF062116),
                    size: 27,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        quantity > 1
                            ? '$price x $quantity = $totalPrice / month'
                            : '$price / month',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.70),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: isLoading ? null : onRemove,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withOpacity(0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFFFF6B6B).withOpacity(0.40),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFFB4AB),
                      ),
                    )
                        : const Text(
                      'Remove',
                      style: TextStyle(
                        color: Color(0xFFFFB4AB),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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

class _GlassMessageBox extends StatelessWidget {
  final String message;
  final bool isError;

  const _GlassMessageBox({
    required this.message,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFFF3B30) : const Color(0xFF34D399);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 45,
          sigmaY: 45,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withOpacity(0.35),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: isError
                    ? const Color(0xFFFFB4AB)
                    : const Color(0xFF6EE7B7),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: isError
                        ? const Color(0xFFFFDAD6)
                        : const Color(0xFFD7FFF0),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTenantAddonState extends StatelessWidget {
  final String tenantName;

  const _EmptyTenantAddonState({
    required this.tenantName,
  });

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
                  Icons.extension_off_outlined,
                  size: 32,
                  color: Color(0xFF6EE7B7),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '$tenantName has no assigned add-ons yet',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'If add-ons already appear in bills but not here, the add-ons may only be saved as bill items, not as tenant add-ons.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.68),
                  fontSize: 12.8,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
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