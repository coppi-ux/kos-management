import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/addon_provider.dart';

class AddonManagementScreen extends StatefulWidget {
  final int kosId;

  const AddonManagementScreen({
    super.key,
    required this.kosId,
  });

  @override
  State<AddonManagementScreen> createState() => _AddonManagementScreenState();
}

class _AddonManagementScreenState extends State<AddonManagementScreen> {
  final Color primaryGreen = const Color(0xFF34D399);
  final Color secondaryGreen = const Color(0xFF10B981);
  final Color darkGreen = const Color(0xFF0F3D2E);

  final Set<String> _selectedPresetNames = {};
  dynamic _selectedTenant;

  final List<Map<String, dynamic>> presetAddons = [
    {
      'name': 'Bedding Set',
      'description': 'Mattress, pillow, bolster, blanket, and bedsheet.',
      'price': 75000,
      'icon': Icons.bed_rounded,
    },
    {
      'name': 'Bath Essentials',
      'description':
      'Towel, soap, shampoo, toothbrush, toothpaste, and toiletries.',
      'price': 50000,
      'icon': Icons.bathtub_rounded,
    },
    {
      'name': 'Dining Set',
      'description':
      'Plate, bowl, glass, spoon, fork, small knife, and drinking bottle.',
      'price': 35000,
      'icon': Icons.restaurant_rounded,
    },
    {
      'name': 'Cleaning Kit',
      'description': 'Sponge, brush, broom, mop, bucket, and detergent.',
      'price': 45000,
      'icon': Icons.cleaning_services_rounded,
    },
    {
      'name': 'Cooking Tools',
      'description':
      'Pot, pan, spatula, soup ladle, kitchen knife, and cutting board.',
      'price': 80000,
      'icon': Icons.soup_kitchen_rounded,
    },
    {
      'name': 'Rice Cooker',
      'description': 'Mini rice cooker for daily cooking needs.',
      'price': 60000,
      'icon': Icons.rice_bowl_rounded,
    },
    {
      'name': 'Iron',
      'description': 'Electric iron for keeping clothes neat and tidy.',
      'price': 40000,
      'icon': Icons.iron_rounded,
    },
    {
      'name': 'Power Strip & Emergency Light',
      'description': 'Power extension and emergency light for power outages.',
      'price': 45000,
      'icon': Icons.electrical_services_rounded,
    },
    {
      'name': 'First Aid Kit',
      'description':
      'Bandage, plaster, antiseptic, and basic first aid supplies.',
      'price': 30000,
      'icon': Icons.medical_services_rounded,
    },
    {
      'name': 'Clothes Hangers',
      'description': 'Hangers to keep clothes organized and tidy.',
      'price': 20000,
      'icon': Icons.checkroom_rounded,
    },
    {
      'name': 'Laundry Basket',
      'description': 'Basket for storing dirty clothes before laundry.',
      'price': 25000,
      'icon': Icons.local_laundry_service_rounded,
    },
    {
      'name': 'Clothing & Daily Accessories',
      'description':
      'Additional daily accessories such as umbrella, cap, or gloves.',
      'price': 50000,
      'icon': Icons.shopping_bag_rounded,
    },
    {
      'name': 'Sewing Kit',
      'description': 'Needle, thread, scissors, and small sewing tools.',
      'price': 20000,
      'icon': Icons.content_cut_rounded,
    },
    {
      'name': 'Prayer Kit',
      'description':
      'Prayer mat, holy book holder, or other worship essentials.',
      'price': 35000,
      'icon': Icons.menu_book_rounded,
    },
    {
      'name': 'Trash Bin',
      'description': 'Room trash bin to keep the room clean and organized.',
      'price': 20000,
      'icon': Icons.delete_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _resetUiSelections();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshAddons();
    });
  }

  @override
  void dispose() {
    _resetUiSelections();
    super.dispose();
  }

  void _resetUiSelections() {
    _selectedPresetNames.clear();
    _selectedTenant = null;
  }

  Future<void> _handleBack() async {
    _resetUiSelections();

    if (!mounted) return;

    if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    }
  }

  String _normalizeName(String value) {
    return value
        .replaceAll('&amp;amp;amp;amp;', '&')
        .replaceAll('&amp;amp;amp;', '&')
        .replaceAll('&amp;amp;', '&')
        .replaceAll('&amp;', '&')
        .replaceAll('  ', ' ')
        .trim()
        .toLowerCase();
  }

  int _parseId(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0.0;
  }

  String _safeText(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty || text == 'null') return fallback;

    return text
        .replaceAll('&amp;amp;amp;amp;', '&')
        .replaceAll('&amp;amp;amp;', '&')
        .replaceAll('&amp;amp;', '&')
        .replaceAll('&amp;', '&');
  }

  bool _isTenantSelected(dynamic tenant) {
    if (_selectedTenant == null) return false;

    final selectedId = _parseId(_selectedTenant['id']);
    final tenantId = _parseId(tenant['id']);

    return selectedId == tenantId;
  }

  String _formatRupiah(dynamic amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return formatter.format(_toDouble(amount));
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
    if (lowerName.contains('laundry')) {
      return Icons.local_laundry_service_rounded;
    }
    if (lowerName.contains('parking')) return Icons.local_parking_rounded;
    if (lowerName.contains('electric') || lowerName.contains('listrik')) {
      return Icons.bolt_rounded;
    }
    if (lowerName.contains('water') || lowerName.contains('air')) {
      return Icons.water_drop_rounded;
    }
    if (lowerName.contains('ac')) return Icons.ac_unit_rounded;

    return Icons.extension_rounded;
  }

  bool _isAddonAlreadyAdded(
      AddonProvider addonProvider,
      String name,
      ) {
    final targetName = _normalizeName(name);

    return addonProvider.kosAddons.any((addon) {
      final currentName = _safeText(
        addon['name'] ?? addon['addon_name'],
        '',
      );

      return _normalizeName(currentName) == targetName;
    });
  }

  int _getAddonIdByName(
      AddonProvider addonProvider,
      String name,
      ) {
    final targetName = _normalizeName(name);

    for (final addon in addonProvider.kosAddons) {
      final currentName = _safeText(
        addon['name'] ?? addon['addon_name'],
        '',
      );

      if (_normalizeName(currentName) == targetName) {
        return _parseId(addon['id'] ?? addon['addon_id']);
      }
    }

    return 0;
  }

  void _togglePreset(
      String name,
      bool disabled,
      ) {
    if (disabled) return;

    setState(() {
      if (_selectedPresetNames.contains(name)) {
        _selectedPresetNames.remove(name);
      } else {
        _selectedPresetNames.add(name);
      }
    });
  }

  double _getSelectedPresetTotal() {
    double total = 0.0;

    for (final preset in presetAddons) {
      final name = preset['name'].toString();

      if (_selectedPresetNames.contains(name)) {
        total += _toDouble(preset['price']);
      }
    }

    return total;
  }

  Future<void> _refreshAddons() async {
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
        'Session expired, please login again.',
        const Color(0xFFFF3B30),
      );
      return;
    }

    await addon.fetchKosAddons(
      token,
      widget.kosId,
    );

    await addon.fetchTenantsForAddon(
      token,
      widget.kosId,
    );

    if (_selectedTenant != null) {
      final tenantId = _parseId(_selectedTenant['id']);

      if (tenantId > 0) {
        await addon.fetchTenantAddons(
          token,
          tenantId,
        );
      }
    }
  }

  Future<void> _addSelectedAddonsToSelectedTenant() async {
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
        'Session expired, please login again.',
        const Color(0xFFFF3B30),
      );
      return;
    }

    if (_selectedTenant == null) {
      _showSnackBar(
        'Please select a tenant first.',
        const Color(0xFFFBBF24),
      );
      return;
    }

    if (_selectedPresetNames.isEmpty) {
      _showSnackBar(
        'Please select at least one add-on.',
        const Color(0xFFFBBF24),
      );
      return;
    }

    final tenantId = _parseId(_selectedTenant['id']);
    final tenantName = _safeText(_selectedTenant['name'], 'tenant');

    if (tenantId <= 0) {
      _showSnackBar(
        'Invalid tenant selected.',
        const Color(0xFFFF3B30),
      );
      return;
    }

    final selectedPresets = presetAddons.where((preset) {
      final name = preset['name'].toString();
      return _selectedPresetNames.contains(name);
    }).toList();

    for (final preset in selectedPresets) {
      final name = preset['name'].toString();
      final price = _toDouble(preset['price']);

      final alreadyAdded = _isAddonAlreadyAdded(
        addon,
        name,
      );

      if (!alreadyAdded) {
        final success = await addon.createAddon(
          token,
          widget.kosId,
          name,
          price,
        );

        if (!success) {
          if (!mounted) return;

          _showSnackBar(
            addon.errorMessage ?? 'Failed to create add-on "$name".',
            const Color(0xFFFF3B30),
          );
          return;
        }
      }
    }

    await addon.fetchKosAddons(
      token,
      widget.kosId,
    );

    final addonIds = selectedPresets
        .map<int>((preset) {
      final name = preset['name'].toString();

      return _getAddonIdByName(
        addon,
        name,
      );
    })
        .where((id) => id > 0)
        .toSet()
        .toList();

    if (addonIds.isEmpty) {
      _showSnackBar(
        'No valid add-ons selected.',
        const Color(0xFFFBBF24),
      );
      return;
    }

    final success = await addon.addAddonsToBill(
      token: token,
      kosId: widget.kosId,
      tenantId: tenantId,
      addonIds: addonIds,
    );

    if (!mounted) return;

    if (success) {
      await addon.fetchTenantAddons(
        token,
        tenantId,
      );

      await addon.fetchKosAddons(
        token,
        widget.kosId,
      );

      await addon.fetchTenantsForAddon(
        token,
        widget.kosId,
      );

      if (!mounted) return;

      setState(() {
        _selectedPresetNames.clear();
        _selectedTenant = null;
      });

      _showSnackBar(
        '${addonIds.length} add-on(s) added to bill for $tenantName.',
        const Color(0xFF10B981),
      );
    } else {
      _showSnackBar(
        addon.errorMessage ?? 'Failed to add selected add-ons to bill.',
        const Color(0xFFFF3B30),
      );
    }
  }

  void _showSnackBar(
      String message,
      Color color,
      ) {
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

  @override
  Widget build(BuildContext context) {
    final addon = Provider.of<AddonProvider>(context);
    final selectedTotal = _getSelectedPresetTotal();

    return WillPopScope(
      onWillPop: () async {
        _resetUiSelections();
        return true;
      },
      child: Scaffold(
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
                            onPressed: _handleBack,
                          ),
                        ),
                        const Center(
                          child: Text(
                            'Add-on Management',
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
                            icon: addon.isLoading
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : const Icon(
                              Icons.refresh_rounded,
                              color: Colors.white,
                            ),
                            splashRadius: 20,
                            onPressed: addon.isLoading ? null : _refreshAddons,
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
              child: RefreshIndicator(
                color: primaryGreen,
                backgroundColor: darkGreen,
                onRefresh: _refreshAddons,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _GlassBox(
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
                                Icons.extension_rounded,
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
                                    'Tenant Add-ons',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Choose a tenant first, then select add-ons for that tenant only.',
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
                      const SizedBox(height: 22),
                      _SectionHeader(
                        title: 'Choose Tenant',
                        trailing: _selectedTenant == null ? null : 'Selected',
                      ),
                      const SizedBox(height: 12),
                      if (addon.isFetchingTenants && addon.addonTenants.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator.adaptive(
                              backgroundColor: Colors.white,
                            ),
                          ),
                        )
                      else if (addon.addonTenants.isEmpty)
                        const _EmptyTenantState()
                      else
                        ...addon.addonTenants.map((tenant) {
                          return _TenantBillCard(
                            tenantName: _safeText(tenant['name'], '-'),
                            roomNumber: _safeText(
                              tenant['room_number'],
                              '-',
                            ),
                            selected: _isTenantSelected(tenant),
                            onTap: () {
                              setState(() {
                                _selectedTenant = tenant;
                                _selectedPresetNames.clear();
                              });
                            },
                          );
                        }),
                      const SizedBox(height: 24),
                      _SectionHeader(
                        title: _selectedTenant == null
                            ? 'Select Tenant First'
                            : 'Select Add-ons',
                        trailing: _selectedPresetNames.isEmpty
                            ? null
                            : '${_selectedPresetNames.length} selected',
                      ),
                      const SizedBox(height: 12),
                      ...presetAddons.map((preset) {
                        final name = preset['name'].toString();
                        final alreadyAdded = _isAddonAlreadyAdded(addon, name);
                        final isSelected = _selectedPresetNames.contains(name);
                        final disabled = addon.isLoading || _selectedTenant == null;

                        return _PresetAddonCard(
                          name: name,
                          description: preset['description'].toString(),
                          price: _formatRupiah(preset['price']),
                          icon: preset['icon'] as IconData,
                          isSelected: isSelected,
                          isAdded: alreadyAdded,
                          isLoading: disabled,
                          onTap: () => _togglePreset(name, disabled),
                        );
                      }),
                      const SizedBox(height: 10),
                      _TotalAddonCard(
                        totalText: _formatRupiah(selectedTotal),
                        selectedTenantName: _selectedTenant == null
                            ? null
                            : _safeText(_selectedTenant['name'], 'tenant'),
                        addonCount: _selectedPresetNames.length,
                        isLoading:
                        addon.isAddingToBill || addon.isCreatingAddon,
                        onAddToBill: _addSelectedAddonsToSelectedTenant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const _TopScrollShield(),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;

  const _SectionHeader({
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white.withOpacity(0.90),
            ),
          ),
        ),
        if (trailing != null)
          _SmallPill(
            text: trailing!,
            color: const Color(0xFFB8FFE2),
            backgroundColor: const Color(0xFF34D399).withOpacity(0.18),
          ),
      ],
    );
  }
}

class _SmallPill extends StatelessWidget {
  final String text;
  final Color color;
  final Color backgroundColor;

  const _SmallPill({
    required this.text,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.35),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PresetAddonCard extends StatelessWidget {
  final String name;
  final String description;
  final String price;
  final IconData icon;
  final bool isSelected;
  final bool isAdded;
  final bool isLoading;
  final VoidCallback onTap;

  const _PresetAddonCard({
    required this.name,
    required this.description,
    required this.price,
    required this.icon,
    required this.isSelected,
    required this.isAdded,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF34D399);
    final bool active = isSelected;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
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
                  color: active
                      ? activeColor.withOpacity(0.95)
                      : Colors.white.withOpacity(0.26),
                  width: active ? 2 : 1,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: active
                      ? [
                    activeColor.withOpacity(0.24),
                    Colors.white.withOpacity(0.16),
                    Colors.white.withOpacity(0.08),
                  ]
                      : [
                    Colors.white.withOpacity(isLoading ? 0.12 : 0.25),
                    Colors.white.withOpacity(isLoading ? 0.08 : 0.13),
                    Colors.white.withOpacity(0.07),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: active
                        ? activeColor.withOpacity(0.24)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: active ? 20 : 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _IconBox(
                    icon: icon,
                    iconColor: active
                        ? const Color(0xFF062116)
                        : isLoading
                        ? Colors.white.withOpacity(0.42)
                        : const Color(0xFF6EE7B7),
                    backgroundColor: active
                        ? activeColor
                        : const Color(0xFF34D399).withOpacity(
                      isLoading ? 0.08 : 0.18,
                    ),
                    useGradient: active,
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
                          style: TextStyle(
                            color: isLoading
                                ? Colors.white.withOpacity(0.45)
                                : Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15.5,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(
                              isLoading ? 0.36 : 0.62,
                            ),
                            fontSize: 12,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '$price / month',
                          style: TextStyle(
                            color: isLoading
                                ? Colors.white.withOpacity(0.38)
                                : const Color(0xFF6EE7B7),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _SmallPill(
                    text: isLoading
                        ? 'Locked'
                        : isSelected
                        ? 'Selected'
                        : isAdded
                        ? 'Ready'
                        : 'Select',
                    color: isSelected
                        ? const Color(0xFFB8FFE2)
                        : isLoading
                        ? Colors.white.withOpacity(0.45)
                        : Colors.white.withOpacity(0.78),
                    backgroundColor: isSelected
                        ? activeColor.withOpacity(0.20)
                        : Colors.white.withOpacity(0.10),
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

class _TenantBillCard extends StatelessWidget {
  final String tenantName;
  final String roomNumber;
  final bool selected;
  final VoidCallback onTap;

  const _TenantBillCard({
    required this.tenantName,
    required this.roomNumber,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF34D399);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: _GlassBox(
          borderRadius: 24,
          padding: const EdgeInsets.all(15),
          borderColor: selected
              ? activeColor.withOpacity(0.95)
              : Colors.white.withOpacity(0.24),
          borderWidth: selected ? 2 : 1,
          child: Row(
            children: [
              _IconBox(
                icon: Icons.person_rounded,
                iconColor: selected
                    ? const Color(0xFF062116)
                    : const Color(0xFF6EE7B7),
                backgroundColor: selected
                    ? activeColor
                    : const Color(0xFF34D399).withOpacity(0.16),
                useGradient: selected,
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
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Room $roomNumber',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.64),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _SmallPill(
                text: selected ? 'Selected' : 'Choose',
                color: selected
                    ? const Color(0xFFB8FFE2)
                    : Colors.white.withOpacity(0.78),
                backgroundColor: selected
                    ? activeColor.withOpacity(0.20)
                    : Colors.white.withOpacity(0.10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalAddonCard extends StatelessWidget {
  final String totalText;
  final String? selectedTenantName;
  final int addonCount;
  final bool isLoading;
  final VoidCallback onAddToBill;

  const _TotalAddonCard({
    required this.totalText,
    required this.selectedTenantName,
    required this.addonCount,
    required this.isLoading,
    required this.onAddToBill,
  });

  @override
  Widget build(BuildContext context) {
    final primaryGreen = const Color(0xFF34D399);

    return _GlassBox(
      borderRadius: 26,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _IconBox(
            icon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFF6EE7B7),
            backgroundColor: primaryGreen.withOpacity(0.18),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedTenantName == null
                      ? '$addonCount selected add-on(s)'
                      : '$addonCount add-on(s) for $selectedTenantName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.68),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6EE7B7),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: isLoading ? null : onAddToBill,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: primaryGreen,
              disabledBackgroundColor: primaryGreen.withOpacity(0.35),
              foregroundColor: const Color(0xFF062116),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              isLoading ? 'Adding...' : 'Add to Bill',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTenantState extends StatelessWidget {
  const _EmptyTenantState();

  @override
  Widget build(BuildContext context) {
    return const _EmptyGlassState(
      icon: Icons.person_off_outlined,
      text: 'No active tenants found.',
    );
  }
}

class _EmptyGlassState extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyGlassState({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassBox(
      borderRadius: 28,
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        height: 250,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 34,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconBox(
                  icon: icon,
                  iconColor: const Color(0xFF6EE7B7),
                  backgroundColor: const Color(0xFF34D399).withOpacity(0.18),
                  size: 72,
                  iconSize: 36,
                  radius: 22,
                ),
                const SizedBox(height: 20),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.74),
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
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

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final bool useGradient;
  final double size;
  final double iconSize;
  final double radius;

  const _IconBox({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    this.useGradient = false,
    this.size = 52,
    this.iconSize = 27,
    this.radius = 17,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: useGradient
            ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF34D399),
            Color(0xFF10B981),
          ],
        )
            : null,
        color: useGradient ? null : backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color:
          useGradient ? Colors.transparent : Colors.white.withOpacity(0.18),
        ),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: iconSize,
      ),
    );
  }
}

class _GlassBox extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final Color? borderColor;
  final double borderWidth;

  const _GlassBox({
    required this.child,
    this.borderRadius = 28,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 85,
          sigmaY: 85,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: borderColor ?? Colors.white.withOpacity(0.30),
              width: borderWidth,
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
                    borderRadius: radius,
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
                      borderRadius: radius,
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