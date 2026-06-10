import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/kos_provider.dart';

class KosSetupScreen extends StatefulWidget {
  const KosSetupScreen({super.key});

  @override
  State<KosSetupScreen> createState() => _KosSetupScreenState();
}

class _KosSetupScreenState extends State<KosSetupScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _roomTypeNameController = TextEditingController();
  final _roomTypePriceController = TextEditingController();

  String? _selectedCapacity;
  String? _selectedCooling;
  String? _selectedBathroom;
  String? _selectedWindow;
  String? _selectedElectricity;
  String? _selectedFurnished;
  String? _selectedWifi;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final kos = Provider.of<KosProvider>(context, listen: false);

      if (auth.token == null) {
        debugPrint("TOKEN NULL DI INIT KOS SETUP");
        return;
      }

      await kos.fetchMyKos(auth.token!);

      if (kos.selectedKos != null) {
        await kos.fetchRoomTypes(
          auth.token!,
          kos.selectedKos['id'],
        );
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _roomTypeNameController.dispose();
    _roomTypePriceController.dispose();
    super.dispose();
  }

  void _updateRoomTypeName() {
    final parts = [
      _selectedCapacity,
      _selectedCooling,
      _selectedBathroom,
      _selectedWindow,
      _selectedElectricity,
      _selectedFurnished,
      _selectedWifi,
    ].whereType<String>().toList();

    _roomTypeNameController.text = parts.join(' - ');
  }

  void _toggleCapacity(String value) {
    setState(() {
      _selectedCapacity = _selectedCapacity == value ? null : value;
      _updateRoomTypeName();
    });
  }

  void _toggleCooling(String value) {
    setState(() {
      _selectedCooling = _selectedCooling == value ? null : value;
      _updateRoomTypeName();
    });
  }

  void _toggleBathroom(String value) {
    setState(() {
      _selectedBathroom = _selectedBathroom == value ? null : value;
      _updateRoomTypeName();
    });
  }

  void _toggleWindow(String value) {
    setState(() {
      _selectedWindow = _selectedWindow == value ? null : value;
      _updateRoomTypeName();
    });
  }

  void _toggleElectricity(String value) {
    setState(() {
      _selectedElectricity = _selectedElectricity == value ? null : value;
      _updateRoomTypeName();
    });
  }

  void _toggleFurnished(String value) {
    setState(() {
      _selectedFurnished = _selectedFurnished == value ? null : value;
      _updateRoomTypeName();
    });
  }

  void _toggleWifi(String value) {
    setState(() {
      _selectedWifi = _selectedWifi == value ? null : value;
      _updateRoomTypeName();
    });
  }

  Future<void> _createKos() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final kos = Provider.of<KosProvider>(context, listen: false);

    if (_nameController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      _showSnackBar(
        context,
        'Name and address cannot be empty',
        const Color(0xFFFF3B30),
      );
      return;
    }

    if (auth.token == null) {
      _showSnackBar(
        context,
        'Session expired, please login again',
        const Color(0xFFFF3B30),
      );
      return;
    }

    final success = await kos.createKos(
      auth.token!,
      _nameController.text.trim(),
      _addressController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      if (kos.selectedKos != null) {
        await kos.fetchRoomTypes(
          auth.token!,
          kos.selectedKos['id'],
        );
      }

      _showSnackBar(
        context,
        'Kos created successfully!',
        const Color(0xFF10B981),
      );

      _nameController.clear();
      _addressController.clear();
    } else {
      _showSnackBar(
        context,
        kos.errorMessage ?? 'Failed to create kos',
        const Color(0xFFFF3B30),
      );
    }
  }

  Future<void> _createRoomType() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final kos = Provider.of<KosProvider>(context, listen: false);

    if (auth.token == null) {
      _showSnackBar(
        context,
        'Session expired, please login again',
        const Color(0xFFFF3B30),
      );
      return;
    }

    if (kos.selectedKos == null) {
      _showSnackBar(
        context,
        'Please create/select kos property first',
        const Color(0xFFFF3B30),
      );
      return;
    }

    if (_selectedCapacity == null ||
        _selectedCooling == null ||
        _selectedBathroom == null ||
        _selectedWindow == null ||
        _selectedElectricity == null ||
        _selectedFurnished == null ||
        _selectedWifi == null) {
      _showSnackBar(
        context,
        'Please complete all room criteria',
        const Color(0xFFFF3B30),
      );
      return;
    }

    _updateRoomTypeName();

    if (_roomTypePriceController.text.trim().isEmpty) {
      _showSnackBar(
        context,
        'Base price cannot be empty',
        const Color(0xFFFF3B30),
      );
      return;
    }

    final rawPrice = _roomTypePriceController.text
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();

    final price = double.tryParse(rawPrice);

    if (price == null || price <= 0) {
      _showSnackBar(
        context,
        'Please enter valid price',
        const Color(0xFFFF3B30),
      );
      return;
    }

    final success = await kos.createRoomType(
      auth.token!,
      kos.selectedKos['id'],
      _roomTypeNameController.text.trim(),
      price,
    );

    if (!mounted) return;

    if (success) {
      _showSnackBar(
        context,
        'Room type created successfully!',
        const Color(0xFF10B981),
      );

      _roomTypeNameController.clear();
      _roomTypePriceController.clear();

      setState(() {
        _selectedCapacity = null;
        _selectedCooling = null;
        _selectedBathroom = null;
        _selectedWindow = null;
        _selectedElectricity = null;
        _selectedFurnished = null;
        _selectedWifi = null;
      });

      await kos.fetchRoomTypes(
        auth.token!,
        kos.selectedKos['id'],
      );
    } else {
      _showSnackBar(
        context,
        kos.errorMessage ?? 'Failed to create room type',
        const Color(0xFFFF3B30),
      );
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
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

  @override
  Widget build(BuildContext context) {
    final kos = Provider.of<KosProvider>(context);

    final hasKos = kos.kosList.isNotEmpty;
    final hasSelectedKos = kos.selectedKos != null;

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
                          'Kos Setup',
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 120,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
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
                                        Icons.home_work_rounded,
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
                                            'Property Info',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 21,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            hasKos
                                                ? '${kos.kosList.length} property available'
                                                : 'Add your first kos property',
                                            style: TextStyle(
                                              color:
                                              Colors.white.withOpacity(0.68),
                                              fontSize: 13,
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
                            if (kos.errorMessage != null) ...[
                              const SizedBox(height: 16),
                              _GlassErrorBox(message: kos.errorMessage!),
                            ],
                            if (kos.isFetchingKos && !kos.isCreatingKos) ...[
                              const SizedBox(height: 16),
                              _GlassInfoBox(message: 'Loading property data...'),
                            ],
                            if (hasKos) ...[
                              const SizedBox(height: 30),
                              Text(
                                'Your Properties',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: Colors.white.withOpacity(0.88),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...kos.kosList.map(
                                    (k) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _PropertyGlassCard(
                                    name: '${k['name']}',
                                    address: '${k['address']}',
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Text(
                              'Add New Property',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                                color: Colors.white.withOpacity(0.88),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _LiquidGlassCard(
                              borderRadius: 30,
                              child: Padding(
                                padding: const EdgeInsets.all(22),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _GlassTextField(
                                      label: 'Kos Name',
                                      hintText: 'Kos Mawar',
                                      controller: _nameController,
                                      icon: Icons.apartment_rounded,
                                    ),
                                    const SizedBox(height: 18),
                                    _GlassTextField(
                                      label: 'Address',
                                      hintText: 'Jl. Merdeka No. 10, Bandung',
                                      controller: _addressController,
                                      icon: Icons.location_on_outlined,
                                      maxLines: 1,
                                    ),
                                    const SizedBox(height: 26),
                                    _LiquidButton(
                                      text: 'Create Kos',
                                      loadingText: 'Creating...',
                                      isLoading: kos.isCreatingKos,
                                      onTap: kos.isCreatingKos
                                          ? null
                                          : _createKos,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (hasSelectedKos) ...[
                              const SizedBox(height: 30),
                              Text(
                                'Room Types',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: Colors.white.withOpacity(0.88),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _LiquidGlassCard(
                                borderRadius: 30,
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Room Type Criteria',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Choose room criteria below. Tap again to undo the selected one.',
                                        style: TextStyle(
                                          color:
                                          Colors.white.withOpacity(0.68),
                                          fontSize: 13,
                                          height: 1.3,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      _CriteriaSection(
                                        title: 'Capacity',
                                        left: _CriteriaChip(
                                          label: 'Private',
                                          icon: Icons.person_rounded,
                                          selected:
                                          _selectedCapacity == 'Private',
                                          onTap: () =>
                                              _toggleCapacity('Private'),
                                        ),
                                        right: _CriteriaChip(
                                          label: 'Shared',
                                          icon: Icons.people_rounded,
                                          selected:
                                          _selectedCapacity == 'Shared',
                                          onTap: () =>
                                              _toggleCapacity('Shared'),
                                        ),
                                      ),
                                      _CriteriaSection(
                                        title: 'Cooling',
                                        left: _CriteriaChip(
                                          label: 'AC',
                                          icon: Icons.ac_unit_rounded,
                                          selected: _selectedCooling == 'AC',
                                          onTap: () => _toggleCooling('AC'),
                                        ),
                                        right: _CriteriaChip(
                                          label: 'Non-AC',
                                          icon: Icons.air_rounded,
                                          selected:
                                          _selectedCooling == 'Non-AC',
                                          onTap: () =>
                                              _toggleCooling('Non-AC'),
                                        ),
                                      ),
                                      _CriteriaSection(
                                        title: 'Bathroom',
                                        left: _CriteriaChip(
                                          label: 'Private Bath',
                                          icon: Icons.bathtub_rounded,
                                          selected: _selectedBathroom ==
                                              'Private Bath',
                                          onTap: () => _toggleBathroom(
                                            'Private Bath',
                                          ),
                                        ),
                                        right: _CriteriaChip(
                                          label: 'Shared Bath',
                                          icon: Icons.shower_rounded,
                                          selected: _selectedBathroom ==
                                              'Shared Bath',
                                          onTap: () => _toggleBathroom(
                                            'Shared Bath',
                                          ),
                                        ),
                                      ),
                                      _CriteriaSection(
                                        title: 'Window',
                                        left: _CriteriaChip(
                                          label: 'Window',
                                          icon: Icons.window_rounded,
                                          selected:
                                          _selectedWindow == 'Window',
                                          onTap: () => _toggleWindow('Window'),
                                        ),
                                        right: _CriteriaChip(
                                          label: 'No Window',
                                          icon: Icons.disabled_visible_rounded,
                                          selected:
                                          _selectedWindow == 'No Window',
                                          onTap: () =>
                                              _toggleWindow('No Window'),
                                        ),
                                      ),
                                      _CriteriaSection(
                                        title: 'Electricity',
                                        left: _CriteriaChip(
                                          label: 'Included',
                                          icon: Icons.electric_bolt_rounded,
                                          selected: _selectedElectricity ==
                                              'Electricity Included',
                                          onTap: () => _toggleElectricity(
                                            'Electricity Included',
                                          ),
                                        ),
                                        right: _CriteriaChip(
                                          label: 'Separate',
                                          icon: Icons.power_off_rounded,
                                          selected: _selectedElectricity ==
                                              'Separate Electricity',
                                          onTap: () => _toggleElectricity(
                                            'Separate Electricity',
                                          ),
                                        ),
                                      ),
                                      _CriteriaSection(
                                        title: 'Furnishing',
                                        left: _CriteriaChip(
                                          label: 'Furnished',
                                          icon: Icons.chair_rounded,
                                          selected: _selectedFurnished ==
                                              'Furnished',
                                          onTap: () => _toggleFurnished(
                                            'Furnished',
                                          ),
                                        ),
                                        right: _CriteriaChip(
                                          label: 'Unfurnished',
                                          icon: Icons.crop_square_rounded,
                                          selected: _selectedFurnished ==
                                              'Unfurnished',
                                          onTap: () => _toggleFurnished(
                                            'Unfurnished',
                                          ),
                                        ),
                                      ),
                                      _CriteriaSection(
                                        title: 'WiFi',
                                        left: _CriteriaChip(
                                          label: 'WiFi',
                                          icon: Icons.wifi_rounded,
                                          selected: _selectedWifi == 'WiFi',
                                          onTap: () => _toggleWifi('WiFi'),
                                        ),
                                        right: _CriteriaChip(
                                          label: 'No WiFi',
                                          icon: Icons.wifi_off_rounded,
                                          selected:
                                          _selectedWifi == 'No WiFi',
                                          onTap: () => _toggleWifi('No WiFi'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              _LiquidGlassCard(
                                borderRadius: 30,
                                child: Padding(
                                  padding: const EdgeInsets.all(22),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      _GlassTextField(
                                        label: 'Base Price',
                                        hintText: '750.000',
                                        controller: _roomTypePriceController,
                                        icon: Icons.payments_outlined,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          RupiahInputFormatter(),
                                        ],
                                      ),
                                      const SizedBox(height: 26),
                                      _LiquidButton(
                                        text: 'Create Room Type',
                                        loadingText: 'Creating...',
                                        isLoading: kos.isMutatingRoomType,
                                        onTap: kos.isMutatingRoomType
                                            ? null
                                            : _createRoomType,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const _TopScrollShield(),
        ],
      ),
    );
  }
}

class _CriteriaSection extends StatelessWidget {
  final String title;
  final Widget left;
  final Widget right;

  const _CriteriaSection({
    required this.title,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: left),
              const SizedBox(width: 10),
              Expanded(child: right),
            ],
          ),
        ],
      ),
    );
  }
}

class _PropertyGlassCard extends StatelessWidget {
  final String name;
  final String address;

  const _PropertyGlassCard({
    required this.name,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return _LiquidGlassCard(
      borderRadius: 26,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF34D399).withOpacity(0.22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                ),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF6EE7B7),
                size: 26,
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
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 12.5,
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
    );
  }
}

class _CriteriaChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CriteriaChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = const Color(0xFF34D399);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 78,
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withOpacity(0.22)
              : Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : Colors.white.withOpacity(0.22),
            width: selected ? 1.7 : 1,
          ),
          boxShadow: selected
              ? [
            BoxShadow(
              color: activeColor.withOpacity(0.24),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 12,
              offset: const Offset(0, 5),
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
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(selected ? 0.26 : 0.18),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (selected)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6EE7B7).withOpacity(0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFFB8FFE2),
                    size: 15,
                  ),
                ),
              ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: selected
                            ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF34D399),
                            Color(0xFF10B981),
                          ],
                        )
                            : null,
                        color: selected ? null : Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? Colors.transparent
                              : Colors.white.withOpacity(0.18),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: selected
                            ? const Color(0xFF062116)
                            : Colors.white.withOpacity(0.72),
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : Colors.white.withOpacity(0.76),
                          fontSize: 12.8,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (selected) const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _GlassTextField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.86),
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          cursorColor: const Color(0xFF6EE7B7),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.42),
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              icon,
              color: Colors.white.withOpacity(0.70),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.12),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.22),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Color(0xFF6EE7B7),
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LiquidButton extends StatefulWidget {
  final String text;
  final String loadingText;
  final bool isLoading;
  final VoidCallback? onTap;

  const _LiquidButton({
    required this.text,
    required this.loadingText,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_LiquidButton> createState() => _LiquidButtonState();
}

class _LiquidButtonState extends State<_LiquidButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _scale = Tween(begin: 1.0, end: 0.97).animate(
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
      onTapDown: widget.onTap == null ? null : (_) => _ctrl.forward(),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
        _ctrl.reverse();
        widget.onTap!();
      },
      onTapCancel: widget.onTap == null ? null : () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.onTap == null
                  ? [
                Colors.white.withOpacity(0.18),
                Colors.white.withOpacity(0.10),
              ]
                  : const [
                Color(0xFF34D399),
                Color(0xFF10B981),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF34D399).withOpacity(
                  widget.onTap == null ? 0.08 : 0.28,
                ),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
              width: 1,
            ),
          ),
          child: Center(
            child: widget.isLoading
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFF062116),
                    strokeWidth: 2.3,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.loadingText,
                  style: const TextStyle(
                    color: Color(0xFF062116),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            )
                : Text(
              widget.text,
              style: const TextStyle(
                color: Color(0xFF062116),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassErrorBox extends StatelessWidget {
  final String message;

  const _GlassErrorBox({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFF3B30).withOpacity(0.14),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFFF3B30).withOpacity(0.35),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFFFB4AB),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFFFFDAD6),
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

class _GlassInfoBox extends StatelessWidget {
  final String message;

  const _GlassInfoBox({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF34D399).withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF34D399).withOpacity(0.26),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Color(0xFF6EE7B7),
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFFD7FFF0),
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
        filter: ImageFilter.blur(sigmaX: 85, sigmaY: 85),
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
            filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
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

class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    String formatted = _formatWithDot(digits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatWithDot(String value) {
    final buffer = StringBuffer();
    int count = 0;

    for (int i = value.length - 1; i >= 0; i--) {
      buffer.write(value[i]);
      count++;

      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }

    return buffer.toString().split('').reversed.join();
  }
}