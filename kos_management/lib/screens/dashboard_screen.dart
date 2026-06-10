import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/kos_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/property_switcher.dart';
import 'addon_management_screen.dart';
import 'analytics_screen.dart';
import 'billing_screen.dart';
import 'export_screen.dart';
import 'kos_setup_screen.dart';
import 'notification_screen.dart';
import 'role_select_screen.dart';
import 'room_list_screen.dart';
import 'tenant_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token;

      if (token == null || auth.user == null) return;

      Provider.of<KosProvider>(context, listen: false).fetchMyKos(token);

      Provider.of<NotificationProvider>(context, listen: false)
          .fetchNotifications(token, auth.user!.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final kos = Provider.of<KosProvider>(context);
    final notif = Provider.of<NotificationProvider>(context);

    final hasKos = kos.selectedKos != null;
    final kosData = kos.selectedKos;

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
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),

                      const Center(
                        child: Text(
                          'KostIn.',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      Positioned(
                        right: 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _TopBarIconButton(
                              icon: Icons.notifications_rounded,
                              iconColor: notif.unreadCount > 0
                                  ? const Color(0xFFFFD34D)
                                  : Colors.white,
                              badgeCount: notif.unreadCount,
                              onTap: () {
                                if (auth.token == null || auth.user == null) {
                                  return;
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => NotificationScreen(
                                      ownerId: auth.user!.id,
                                      token: auth.token!,
                                    ),
                                  ),
                                ).then((_) {
                                  Provider.of<NotificationProvider>(
                                    context,
                                    listen: false,
                                  ).fetchNotifications(
                                    auth.token!,
                                    auth.user!.id,
                                  );
                                });
                              },
                            ),

                            const SizedBox(width: 6),

                            _TopBarIconButton(
                              icon: Icons.logout_rounded,
                              iconColor: Colors.white,
                              onTap: () async {
                                await auth.logout();

                                if (context.mounted) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                      const RoleSelectScreen(),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
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
            child: Column(
              children: [
                const SizedBox(height: 10),

                const PropertySwitcher(),

                Expanded(
                  child: kos.isLoading
                      ? const Center(
                    child: CircularProgressIndicator.adaptive(
                      backgroundColor: Colors.white,
                    ),
                  )
                      : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileCard(
                          auth: auth,
                          kos: kos,
                          hasKos: hasKos,
                          kosData: kosData,
                        ),

                        const SizedBox(height: 16),

                        if (!hasKos)
                          _buildNoKosCard(
                            context: context,
                            auth: auth,
                            kos: kos,
                          ),

                        if (!hasKos) const SizedBox(height: 16),

                        Padding(
                          padding: const EdgeInsets.only(
                            left: 4,
                            bottom: 12,
                          ),
                          child: Text(
                            'Menu',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                              color: Colors.white.withOpacity(0.86),
                            ),
                          ),
                        ),

                        _buildMenuGrid(
                          context: context,
                          auth: auth,
                          kos: kos,
                          hasKos: hasKos,
                          kosData: kosData,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard({
    required AuthProvider auth,
    required KosProvider kos,
    required bool hasKos,
    required dynamic kosData,
  }) {
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
              child: Center(
                child: Text(
                  (auth.user?.name ?? 'O').substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome! 👋',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    auth.user?.name ?? 'Owner',
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
                        Icons.home_work_rounded,
                        color: Colors.white.withOpacity(0.62),
                        size: 14,
                      ),

                      const SizedBox(width: 5),

                      Flexible(
                        child: Text(
                          hasKos ? '${kosData['name']}' : 'No property yet',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.68),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),

                      if (kos.kosList.length > 1) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                            ),
                          ),
                          child: Text(
                            '${kos.kosList.length} properties',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildNoKosCard({
    required BuildContext context,
    required AuthProvider auth,
    required KosProvider kos,
  }) {
    return _LiquidGlassCard(
      tintColor: const Color(0xFFFFB74D).withOpacity(0.16),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB74D).withOpacity(0.20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.20),
                ),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFFFFCC80),
                size: 21,
              ),
            ),

            const SizedBox(width: 12),

            const Expanded(
              child: Text(
                'Setup your kos property to get started.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                ),
              ),
            ),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const KosSetupScreen(),
                  ),
                ).then((_) {
                  if (auth.token != null) {
                    kos.fetchMyKos(auth.token!);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB74D).withOpacity(0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Setup',
                  style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGrid({
    required BuildContext context,
    required AuthProvider auth,
    required KosProvider kos,
    required bool hasKos,
    required dynamic kosData,
  }) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: [
        _LiquidGlassMenuCard(
          icon: Icons.home_work_rounded,
          label: 'Kos Setup',
          iconColor: const Color(0xFF34D399),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const KosSetupScreen(),
              ),
            ).then((_) {
              if (auth.token != null) {
                kos.fetchMyKos(auth.token!);
              }
            });
          },
        ),

        _LiquidGlassMenuCard(
          icon: Icons.meeting_room_rounded,
          label: 'Rooms',
          iconColor: const Color(0xFF60A5FA),
          onTap: hasKos
              ? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RoomListScreen(
                  kosId: kosData['id'],
                ),
              ),
            );
          }
              : () => _showNoKosSnackbar(context),
        ),

        _LiquidGlassMenuCard(
          icon: Icons.people_rounded,
          label: 'Tenants',
          iconColor: const Color(0xFFC084FC),
          onTap: hasKos
              ? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TenantListScreen(
                  kosId: kosData['id'],
                ),
              ),
            );
          }
              : () => _showNoKosSnackbar(context),
        ),

        _LiquidGlassMenuCard(
          icon: Icons.extension_rounded,
          label: 'Add-ons',
          iconColor: const Color(0xFF2DD4BF),
          onTap: hasKos
              ? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddonManagementScreen(
                  kosId: kosData['id'],
                ),
              ),
            );
          }
              : () => _showNoKosSnackbar(context),
        ),

        _LiquidGlassMenuCard(
          icon: Icons.receipt_long_rounded,
          label: 'Billing',
          iconColor: const Color(0xFFFBBF24),
          onTap: hasKos
              ? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BillingScreen(
                  kosId: kosData['id'],
                ),
              ),
            );
          }
              : () => _showNoKosSnackbar(context),
        ),

        _LiquidGlassMenuCard(
          icon: Icons.bar_chart_rounded,
          label: 'Analytics',
          iconColor: const Color(0xFF818CF8),
          onTap: hasKos
              ? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AnalyticsScreen(
                  kosId: kosData['id'],
                ),
              ),
            );
          }
              : () => _showNoKosSnackbar(context),
        ),

        _LiquidGlassMenuCard(
          icon: Icons.download_rounded,
          label: 'Export',
          iconColor: const Color(0xFFE5E7EB),
          onTap: hasKos
              ? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExportScreen(
                  kosId: kosData['id'],
                ),
              ),
            );
          }
              : () => _showNoKosSnackbar(context),
        ),
      ],
    );
  }

  void _showNoKosSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Please setup your kos property first!',
          style: TextStyle(fontWeight: FontWeight.w500),
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
}

class _TopBarIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final int badgeCount;
  final VoidCallback onTap;

  const _TopBarIconButton({
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasBadge = badgeCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.24),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: iconColor,
                ),
              ),
            ),
          ),

          if (hasBadge)
            Positioned(
              right: -2,
              top: -4,
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 17,
                  minHeight: 17,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white,
                    width: 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF3B30).withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
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

class _LiquidGlassMenuCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  const _LiquidGlassMenuCard({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  @override
  State<_LiquidGlassMenuCard> createState() => _LiquidGlassMenuCardState();
}

class _LiquidGlassMenuCardState extends State<_LiquidGlassMenuCard>
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

    _scale = Tween<double>(
      begin: 1,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeOut,
      ),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 95, sigmaY: 95),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.13),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.035),
                    blurRadius: 22,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 34,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.22),
                            Colors.white.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                widget.iconColor,
                                widget.iconColor.withOpacity(0.72),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: widget.iconColor.withOpacity(0.28),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.icon,
                            color: const Color(0xFF062116),
                            size: 26,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          widget.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            letterSpacing: -0.2,
                            color: Colors.white,
                          ),
                        ),
                      ],
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