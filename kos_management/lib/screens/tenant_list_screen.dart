import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../providers/kos_provider.dart';
import 'add_tenant_screen.dart';
import 'payment_history_screen.dart';
import 'tenant_addon_screen.dart';

class TenantListScreen extends StatefulWidget {
  final int kosId;

  const TenantListScreen({
    super.key,
    required this.kosId,
  });

  @override
  State<TenantListScreen> createState() => _TenantListScreenState();
}

class _TenantListScreenState extends State<TenantListScreen> {
  bool _showActiveOnly = true;
  int? _deletingTenantId;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTenants(activeOnly: true);
    });
  }

  Future<void> _loadTenants({required bool activeOnly}) async {
    final auth = context.read<AuthProvider>();
    final kos = context.read<KosProvider>();

    final token = auth.token;

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      _showSnackBar(
        'Session expired. Please login again.',
        const Color(0xFFFF3B30),
      );
      return;
    }

    await kos.fetchTenants(
      token,
      widget.kosId,
      activeOnly: activeOnly,
    );
  }

  String _formatRupiah(dynamic amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final value = double.tryParse(amount?.toString() ?? '0') ?? 0;
    return formatter.format(value);
  }

  bool _isTenantActive(dynamic tenant) {
    final value = tenant['is_active'];
    return value == 1 || value == true || value == '1' || value == 'true';
  }

  Future<void> _confirmDeactivate(
      BuildContext context,
      dynamic tenant,
      AuthProvider auth,
      KosProvider kos,
      ) async {
    final tenantId = tenant['id'];
    final tenantName = tenant['name'] ?? '-';
    final roomNumber = tenant['room_number'] ?? '-';

    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F3D2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.white.withOpacity(0.22),
            ),
          ),
          title: const Text(
            'Remove Tenant',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Remove $tenantName from Room $roomNumber?\n\nThe room will become available again.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B30),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Remove',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    final token = auth.token;

    if (token == null || token.isEmpty) {
      _showSnackBar(
        'Session expired. Please login again.',
        const Color(0xFFFF3B30),
      );
      return;
    }

    setState(() {
      _deletingTenantId = tenantId;
    });

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/rooms/tenants/$tenantId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showSnackBar(
          '$tenantName removed successfully',
          const Color(0xFF10B981),
        );

        await kos.fetchTenants(
          token,
          widget.kosId,
          activeOnly: _showActiveOnly,
        );
      } else {
        _showSnackBar(
          'Failed to remove tenant',
          const Color(0xFFFF3B30),
        );
      }
    } catch (_) {
      if (!mounted) return;

      _showSnackBar(
        'Network error. Please try again.',
        const Color(0xFFFF3B30),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _deletingTenantId = null;
      });
    }
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

  void _goToAddTenant(AuthProvider auth, KosProvider kos) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTenantScreen(
          kosId: widget.kosId,
        ),
      ),
    ).then((_) {
      if (!mounted) return;

      final token = auth.token;
      if (token == null || token.isEmpty) return;

      kos.fetchTenants(
        token,
        widget.kosId,
        activeOnly: _showActiveOnly,
      );
    });
  }

  void _changeFilter(bool activeOnly) {
    if (_showActiveOnly == activeOnly) return;

    setState(() {
      _showActiveOnly = activeOnly;
    });

    _loadTenants(activeOnly: activeOnly);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final kos = context.watch<KosProvider>();

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
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                      const Center(
                        child: Text(
                          'Tenants',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: Colors.white,
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
      floatingActionButton: _GlassFloatingButton(
        onTap: () => _goToAddTenant(auth, kos),
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
            top: 140,
            right: -140,
            child: _BlurBlob(
              size: 390,
              color: const Color(0xFF22C55E).withOpacity(0.45),
            ),
          ),
          Positioned(
            bottom: 90,
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LiquidGlassCard(
                    borderRadius: 34,
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Row(
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF34D399),
                                  Color(0xFF10B981),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF34D399)
                                      .withOpacity(0.32),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.people_rounded,
                              color: Color(0xFF062116),
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tenant List',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _showActiveOnly
                                      ? 'Showing active tenants only'
                                      : 'Showing all tenants',
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
                  ),
                  const SizedBox(height: 18),
                  _LiquidGlassCard(
                    borderRadius: 26,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Text(
                            'Show',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.72),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _FilterChipGlass(
                            label: 'Active',
                            selected: _showActiveOnly,
                            onTap: () => _changeFilter(true),
                          ),
                          const SizedBox(width: 8),
                          _FilterChipGlass(
                            label: 'All',
                            selected: !_showActiveOnly,
                            onTap: () => _changeFilter(false),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: kos.isLoading
                        ? const Center(
                      child: CircularProgressIndicator.adaptive(
                        backgroundColor: Colors.white,
                      ),
                    )
                        : kos.tenants.isEmpty
                        ? const _EmptyTenantState()
                        : RefreshIndicator(
                      color: const Color(0xFF10B981),
                      onRefresh: () => _loadTenants(
                        activeOnly: _showActiveOnly,
                      ),
                      child: ListView.builder(
                        physics:
                        const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding:
                        const EdgeInsets.fromLTRB(0, 0, 0, 100),
                        itemCount: kos.tenants.length,
                        itemBuilder: (context, index) {
                          final tenant = kos.tenants[index];
                          final isActive = _isTenantActive(tenant);
                          final tenantId = tenant['id'];

                          return Padding(
                            padding:
                            const EdgeInsets.only(bottom: 14),
                            child: _TenantGlassCard(
                              tenant: tenant,
                              isActive: isActive,
                              isRemoving:
                              _deletingTenantId == tenantId,
                              price: _formatRupiah(
                                tenant['base_price'],
                              ),
                              onAddOns: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TenantAddonScreen(
                                    tenantId: tenant['id'],
                                    tenantName:
                                    '${tenant['name'] ?? '-'}',
                                    kosId: widget.kosId,
                                  ),
                                ),
                              ),
                              onHistory: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PaymentHistoryScreen(
                                        tenantId: tenant['id'],
                                        tenantName:
                                        '${tenant['name'] ?? '-'}',
                                      ),
                                ),
                              ),
                              onRemove: isActive &&
                                  _deletingTenantId == null
                                  ? () => _confirmDeactivate(
                                context,
                                tenant,
                                auth,
                                kos,
                              )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const _TopScrollShield(),
        ],
      ),
    );
  }
}

class _TenantGlassCard extends StatelessWidget {
  final dynamic tenant;
  final bool isActive;
  final bool isRemoving;
  final String price;
  final VoidCallback onAddOns;
  final VoidCallback onHistory;
  final VoidCallback? onRemove;

  const _TenantGlassCard({
    required this.tenant,
    required this.isActive,
    required this.isRemoving,
    required this.price,
    required this.onAddOns,
    required this.onHistory,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final tenantName = '${tenant['name'] ?? '-'}';
    final firstLetter =
    tenantName.isNotEmpty ? tenantName.substring(0, 1).toUpperCase() : '?';

    return _LiquidGlassCard(
      borderRadius: 26,
      tintColor: isActive
          ? Colors.white.withOpacity(0.15)
          : Colors.white.withOpacity(0.09),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF34D399),
                        Color(0xFF10B981),
                      ],
                    )
                        : null,
                    color: isActive ? null : Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isActive
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.18),
                    ),
                    boxShadow: [
                      if (isActive)
                        BoxShadow(
                          color: const Color(0xFF34D399).withOpacity(0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      firstLetter,
                      style: TextStyle(
                        color: isActive
                            ? const Color(0xFF062116)
                            : Colors.white.withOpacity(0.62),
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Text(
                            tenantName,
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.52),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (!isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.16),
                                ),
                              ),
                              child: Text(
                                'Inactive',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.62),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.meeting_room_rounded,
                            color: Colors.white.withOpacity(0.62),
                            size: 15,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'Room ${tenant['room_number'] ?? '-'} • ${tenant['room_type'] ?? '-'}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.66),
                                fontSize: 12.5,
                                height: 1.25,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  price,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xFF6EE7B7)
                        : Colors.white.withOpacity(0.42),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(26),
                bottomRight: Radius.circular(26),
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.13),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TenantActionButton(
                    icon: Icons.extension_rounded,
                    label: 'Add-ons',
                    color: const Color(0xFF2DD4BF),
                    onTap: onAddOns,
                  ),
                ),
                Expanded(
                  child: _TenantActionButton(
                    icon: Icons.history_rounded,
                    label: 'History',
                    color: const Color(0xFF60A5FA),
                    onTap: onHistory,
                  ),
                ),
                if (isActive)
                  Expanded(
                    child: _TenantActionButton(
                      icon: isRemoving
                          ? Icons.hourglass_top_rounded
                          : Icons.person_off_rounded,
                      label: isRemoving ? 'Removing' : 'Remove',
                      color: const Color(0xFFFF6B6B),
                      onTap: onRemove,
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

class _TenantActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _TenantActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 16,
        color: onTap == null ? color.withOpacity(0.45) : color,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: onTap == null ? color.withOpacity(0.45) : color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        foregroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

class _FilterChipGlass extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipGlass({
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
          horizontal: 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withOpacity(0.24)
              : Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? activeColor : Colors.white.withOpacity(0.20),
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
            color: selected ? Colors.white : Colors.white.withOpacity(0.62),
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _EmptyTenantState extends StatelessWidget {
  const _EmptyTenantState();

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -140),
      child: Center(
        child: _LiquidGlassCard(
          borderRadius: 30,
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 38,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      color: const Color(0xFF34D399).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFF6EE7B7).withOpacity(0.30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF34D399).withOpacity(0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.people_outline_rounded,
                      size: 34,
                      color: Color(0xFF6EE7B7),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'No tenants yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Tap + to add a tenant',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.64),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassFloatingButton extends StatefulWidget {
  final VoidCallback onTap;

  const _GlassFloatingButton({
    required this.onTap,
  });

  @override
  State<_GlassFloatingButton> createState() => _GlassFloatingButtonState();
}

class _GlassFloatingButtonState extends State<_GlassFloatingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _scale = Tween(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF34D399),
                Color(0xFF10B981),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.20),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF34D399).withOpacity(0.28),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_add_rounded,
            color: Color(0xFF062116),
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final Color? tintColor;
  final double borderRadius;

  const _LiquidGlassCard({
    required this.child,
    this.tintColor,
    this.borderRadius = 28,
  });

  @override
  Widget build(BuildContext context) {
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
            color: tintColor ?? Colors.white.withOpacity(0.15),
            border: Border.all(
              color: Colors.white.withOpacity(0.28),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
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
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 48,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(borderRadius),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.28),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
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