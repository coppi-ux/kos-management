import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/kos_provider.dart';

class AddRoomScreen extends StatefulWidget {
  final int kosId;

  const AddRoomScreen({
    super.key,
    required this.kosId,
  });

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final _roomNumberController = TextEditingController();

  int? _selectedRoomTypeId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).token;

      if (token == null) return;

      Provider.of<KosProvider>(
        context,
        listen: false,
      ).fetchRoomTypes(
        token,
        widget.kosId,
      );
    });
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    super.dispose();
  }

  Future<void> _addRoom() async {
    if (_selectedRoomTypeId == null) {
      _showSnackBar(
        'Please select a room type',
        const Color(0xFFFF3B30),
      );
      return;
    }

    if (_roomNumberController.text.trim().isEmpty) {
      _showSnackBar(
        'Room number cannot be empty',
        const Color(0xFFFF3B30),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    final kos = Provider.of<KosProvider>(
      context,
      listen: false,
    );

    if (auth.token == null) {
      _showSnackBar(
        'Session expired, please login again',
        const Color(0xFFFF3B30),
      );
      return;
    }

    final success = await kos.createRoom(
      auth.token!,
      widget.kosId,
      _selectedRoomTypeId!,
      _roomNumberController.text.trim(),
    );

    if (success && mounted) {
      final messenger = ScaffoldMessenger.of(context);

      Navigator.pop(context);

      messenger.showSnackBar(
        SnackBar(
          content: const Text('Room added successfully!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }

    if (!success && mounted) {
      _showSnackBar(
        kos.errorMessage ?? 'Failed to add room',
        const Color(0xFFFF3B30),
      );
    }
  }

  void _showSnackBar(
      String message,
      Color color,
      ) {
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

  String _formatPrice(dynamic price) {
    if (price == null) return '0';

    String raw = price.toString().trim();

    if (raw.contains('.') && raw.split('.').last.length == 2) {
      raw = raw.split('.').first;
    }

    raw = raw.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (raw.isEmpty) return '0';

    final buffer = StringBuffer();
    int count = 0;

    for (int i = raw.length - 1; i >= 0; i--) {
      buffer.write(raw[i]);
      count++;

      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }

    return buffer.toString().split('').reversed.join();
  }

  @override
  Widget build(BuildContext context) {
    final kos = Provider.of<KosProvider>(context);

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
                          'Add Room',
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 100,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 430,
                        ),
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
                                        Icons.meeting_room_rounded,
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
                                            'Create Room',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 21,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Add a new room to your kos property',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
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
                            ),
                            const SizedBox(height: 22),
                            _LiquidGlassCard(
                              borderRadius: 30,
                              child: Padding(
                                padding: const EdgeInsets.all(22),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _GlassTextField(
                                      label: 'Room Number',
                                      hintText: 'A01',
                                      controller: _roomNumberController,
                                      icon: Icons.door_front_door_outlined,
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      'Room Type',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.86),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 9),
                                    _RoomTypeSelector(
                                      value: _selectedRoomTypeId,
                                      roomTypes: kos.roomTypes,
                                      formatPrice: _formatPrice,
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedRoomTypeId = val;
                                        });
                                      },
                                    ),
                                    if (kos.roomTypes.isEmpty) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        'No room types available. Please create a room type first in Kos Setup.',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.62),
                                          fontSize: 12.5,
                                          height: 1.35,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 26),
                                    _LiquidButton(
                                      text: 'Add Room',
                                      loadingText: 'Adding...',
                                      isLoading: kos.isLoading,
                                      onTap: kos.isLoading ? null : _addRoom,
                                    ),
                                  ],
                                ),
                              ),
                            ),
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

class _GlassTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final IconData icon;

  const _GlassTextField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.icon,
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

class _RoomTypeSelector extends StatelessWidget {
  final int? value;
  final List<dynamic> roomTypes;
  final String Function(dynamic price) formatPrice;
  final ValueChanged<int?> onChanged;

  const _RoomTypeSelector({
    required this.value,
    required this.roomTypes,
    required this.formatPrice,
    required this.onChanged,
  });

  dynamic _selectedRoomType() {
    for (final rt in roomTypes) {
      final id = rt['id'];
      final parsedId = id is int ? id : int.tryParse('$id');

      if (parsedId == value) {
        return rt;
      }
    }

    return null;
  }

  Future<void> _openRoomTypeSheet(BuildContext context) async {
    if (roomTypes.isEmpty) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) {
        return _RoomTypeBottomSheet(
          roomTypes: roomTypes,
          selectedId: value,
          formatPrice: formatPrice,
          onSelected: (id) {
            onChanged(id);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedRoomType();

    return GestureDetector(
      onTap: () => _openRoomTypeSheet(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 45,
            sigmaY: 45,
          ),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected == null
                    ? Colors.white.withOpacity(0.22)
                    : const Color(0xFF6EE7B7).withOpacity(0.78),
                width: selected == null ? 1 : 1.4,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.16),
                            Colors.white.withOpacity(0.04),
                            Colors.white.withOpacity(0.00),
                          ],
                          stops: const [0.0, 0.35, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: selected == null
                              ? Colors.white.withOpacity(0.12)
                              : const Color(0xFF34D399).withOpacity(0.20),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                        child: Icon(
                          Icons.bed_rounded,
                          color: selected == null
                              ? Colors.white.withOpacity(0.70)
                              : const Color(0xFF6EE7B7),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: selected == null
                            ? Padding(
                          padding: const EdgeInsets.only(top: 11),
                          child: Text(
                            'Select room type',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.42),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        )
                            : _SelectedRoomTypePreview(
                          name: '${selected['name']}',
                          price: formatPrice(selected['base_price']),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 9),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white.withOpacity(0.82),
                          size: 26,
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
    );
  }
}

class _SelectedRoomTypePreview extends StatelessWidget {
  final String name;
  final String price;

  const _SelectedRoomTypePreview({
    required this.name,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    final facilities = name.split(' - ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: facilities.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF34D399).withOpacity(0.16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF34D399).withOpacity(0.28),
                ),
              ),
              child: Text(
                item,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'Rp $price',
          style: TextStyle(
            color: const Color(0xFF6EE7B7).withOpacity(0.92),
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _RoomTypeBottomSheet extends StatelessWidget {
  final List<dynamic> roomTypes;
  final int? selectedId;
  final String Function(dynamic price) formatPrice;
  final ValueChanged<int> onSelected;

  const _RoomTypeBottomSheet({
    required this.roomTypes,
    required this.selectedId,
    required this.formatPrice,
    required this.onSelected,
  });

  int _parseId(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    const double sheetRadius = 30;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(sheetRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 55,
              sigmaY: 55,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.72,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0F3D2E).withOpacity(0.92),
                borderRadius: BorderRadius.circular(sheetRadius),
                border: Border.all(
                  color: Colors.white.withOpacity(0.24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.22),
                    blurRadius: 28,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(sheetRadius),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.18),
                              Colors.white.withOpacity(0.06),
                              Colors.white.withOpacity(0.00),
                            ],
                            stops: const [0.0, 0.16, 0.42],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.36),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Select Room Type',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Flexible(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                          itemCount: roomTypes.length,
                          itemBuilder: (context, index) {
                            final rt = roomTypes[index];
                            final currentId = _parseId(rt['id']);
                            final isSelected = currentId == selectedId;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _RoomTypeSheetItem(
                                name: '${rt['name']}',
                                price: formatPrice(rt['base_price']),
                                selected: isSelected,
                                onTap: () => onSelected(currentId),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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

class _RoomTypeSheetItem extends StatelessWidget {
  final String name;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  const _RoomTypeSheetItem({
    required this.name,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final facilities = name.split(' - ');
    const double itemRadius = 22;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(itemRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 42,
            sigmaY: 42,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(itemRadius),
              border: Border.all(
                color: selected
                    ? const Color(0xFF34D399).withOpacity(0.90)
                    : Colors.white.withOpacity(0.18),
                width: selected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(itemRadius),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: selected
                            ? [
                          const Color(0xFF34D399).withOpacity(0.22),
                          Colors.white.withOpacity(0.14),
                          Colors.white.withOpacity(0.07),
                        ]
                            : [
                          Colors.white.withOpacity(0.18),
                          Colors.white.withOpacity(0.10),
                          Colors.white.withOpacity(0.05),
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
                        borderRadius: BorderRadius.circular(itemRadius),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(selected ? 0.20 : 0.14),
                            Colors.white.withOpacity(0.04),
                            Colors.white.withOpacity(0.00),
                          ],
                          stops: const [0.0, 0.32, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          Icons.bed_rounded,
                          color: selected
                              ? const Color(0xFF062116)
                              : Colors.white.withOpacity(0.72),
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: facilities.map((item) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.18),
                                    ),
                                  ),
                                  child: Text(
                                    item,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      height: 1.15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              'Rp $price',
                              style: TextStyle(
                                color: const Color(0xFF6EE7B7).withOpacity(0.95),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF6EE7B7),
                          size: 22,
                        ),
                      ],
                    ],
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

    _scale = Tween(
      begin: 1.0,
      end: 0.97,
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
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.22),
                          Colors.white.withOpacity(0.06),
                          Colors.white.withOpacity(0.00),
                        ],
                        stops: const [0.0, 0.35, 1.0],
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
      height: MediaQuery.of(context).padding.top,
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