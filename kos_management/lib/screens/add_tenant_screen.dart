import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/kos_provider.dart';

class AddTenantScreen extends StatefulWidget {
  final int kosId;

  const AddTenantScreen({
    super.key,
    required this.kosId,
  });

  @override
  State<AddTenantScreen> createState() => _AddTenantScreenState();
}

class _AddTenantScreenState extends State<AddTenantScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  int? _selectedRoomId;
  DateTime _startDate = DateTime.now();

  final Color primaryGreen = const Color(0xFF34D399);
  final Color secondaryGreen = const Color(0xFF10B981);
  final Color darkGreen = const Color(0xFF0F3D2E);
  final Color softGreen = const Color(0xFF6EE7B7);

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
      ).fetchRooms(
        token,
        widget.kosId,
      );
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _pickDate() async {
    final picked = await showDialog<DateTime>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) {
        return _LiquidGlassDatePickerDialog(
          initialDate: _startDate,
          firstDate: DateTime(2024),
          lastDate: DateTime(2027),
          primaryGreen: primaryGreen,
          secondaryGreen: secondaryGreen,
          darkGreen: darkGreen,
          softGreen: softGreen,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _addTenant() async {
    if (_selectedRoomId == null) {
      _showSnackBar(
        'Please select a room',
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
        'Session expired, please login again.',
        const Color(0xFFFF3B30),
      );
      return;
    }

    final success = await kos.addTenant(
      auth.token!,
      _nameController.text.trim(),
      _emailController.text.trim(),
      _phoneController.text.trim(),
      _selectedRoomId!,
      _formatDate(_startDate),
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tenant added successfully!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } else {
      _showSnackBar(
        kos.errorMessage ?? 'Failed to add tenant.',
        const Color(0xFFFF3B30),
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

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

  InputDecoration _glassInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: label,
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.72),
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        letterSpacing: 1.1,
      ),
      prefixIcon: Icon(
        icon,
        color: Colors.white.withOpacity(0.72),
      ),
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.00),
          width: 0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: softGreen.withOpacity(0.90),
          width: 1.4,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _liquidGlassContainer({
    required Widget child,
    double borderRadius = 30,
    EdgeInsets padding = const EdgeInsets.all(22),
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

  Widget _glassFieldBox({
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 45,
          sigmaY: 45,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.20),
                Colors.white.withOpacity(0.11),
                Colors.white.withOpacity(0.07),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.26),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.025),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
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
    final kos = Provider.of<KosProvider>(context);

    final availableRooms = kos.rooms.where((r) {
      return r['status'] == 'available';
    }).toList();

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
                          'Add Tenant',
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _liquidGlassContainer(
                    borderRadius: 34,
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
                            Icons.person_add_rounded,
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
                                'Tenant Info',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Add tenant details and assign an available room.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.68),
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
                  _liquidGlassContainer(
                    child: Column(
                      children: [
                        _glassFieldBox(
                          child: TextField(
                            controller: _nameController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            cursorColor: softGreen,
                            decoration: _glassInputDecoration(
                              label: 'Full Name',
                              icon: Icons.person_outline_rounded,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _glassFieldBox(
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            cursorColor: softGreen,
                            decoration: _glassInputDecoration(
                              label: 'Email',
                              icon: Icons.email_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _glassFieldBox(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            cursorColor: softGreen,
                            decoration: _glassInputDecoration(
                              label: 'Phone Number',
                              icon: Icons.phone_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _glassFieldBox(
                          child: DropdownButtonFormField<int>(
                            value: _selectedRoomId,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF123C2D),
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white.withOpacity(0.80),
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            decoration: _glassInputDecoration(
                              label: 'Assign Room (available only)',
                              icon: Icons.meeting_room_outlined,
                            ),
                            items: availableRooms.map<DropdownMenuItem<int>>(
                                  (room) {
                                final roomId = _parseInt(room['id']);

                                return DropdownMenuItem<int>(
                                  value: roomId,
                                  child: Text(
                                    'Room ${room['room_number']} - ${room['type_name']}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedRoomId = val;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                        GestureDetector(
                          onTap: _pickDate,
                          child: _glassFieldBox(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    color: Colors.white.withOpacity(0.72),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Start Date: ${_formatDate(_startDate)}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: kos.isLoading
                                  ? [
                                Colors.white.withOpacity(0.18),
                                Colors.white.withOpacity(0.10),
                              ]
                                  : [
                                primaryGreen,
                                secondaryGreen,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryGreen.withOpacity(0.28),
                                blurRadius: 18,
                                offset: const Offset(0, 7),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                              width: 1,
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: kos.isLoading ? null : _addTenant,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: Colors.transparent,
                              disabledBackgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: const Color(0xFF062116),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: kos.isLoading
                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Color(0xFF062116),
                                strokeWidth: 2.6,
                              ),
                            )
                                : const Text(
                              'Add Tenant',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ],
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

class _LiquidGlassDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Color primaryGreen;
  final Color secondaryGreen;
  final Color darkGreen;
  final Color softGreen;

  const _LiquidGlassDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.primaryGreen,
    required this.secondaryGreen,
    required this.darkGreen,
    required this.softGreen,
  });

  @override
  State<_LiquidGlassDatePickerDialog> createState() =>
      _LiquidGlassDatePickerDialogState();
}

class _LiquidGlassDatePickerDialogState
    extends State<_LiquidGlassDatePickerDialog> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();

    _selectedDate = widget.initialDate;
    _displayedMonth = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
    );
  }

  int _daysInMonth(DateTime month) {
    return DateTime(
      month.year,
      month.month + 1,
      0,
    ).day;
  }

  int _firstWeekdayOffset(DateTime month) {
    final firstDay = DateTime(
      month.year,
      month.month,
      1,
    );

    return firstDay.weekday % 7;
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isDisabled(DateTime date) {
    final cleanDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final first = DateTime(
      widget.firstDate.year,
      widget.firstDate.month,
      widget.firstDate.day,
    );

    final last = DateTime(
      widget.lastDate.year,
      widget.lastDate.month,
      widget.lastDate.day,
    );

    return cleanDate.isBefore(first) || cleanDate.isAfter(last);
  }

  void _previousMonth() {
    final previous = DateTime(
      _displayedMonth.year,
      _displayedMonth.month - 1,
    );

    final minMonth = DateTime(
      widget.firstDate.year,
      widget.firstDate.month,
    );

    if (previous.isBefore(minMonth)) return;

    setState(() {
      _displayedMonth = previous;
    });
  }

  void _nextMonth() {
    final next = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
    );

    final maxMonth = DateTime(
      widget.lastDate.year,
      widget.lastDate.month,
    );

    if (next.isAfter(maxMonth)) return;

    setState(() {
      _displayedMonth = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = DateFormat('EEE, MMM d').format(_selectedDate);
    final subtitle = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final monthTitle = DateFormat('MMMM yyyy').format(_displayedMonth);

    final totalDays = _daysInMonth(_displayedMonth);
    final offset = _firstWeekdayOffset(_displayedMonth);

    final cells = <Widget>[];

    for (int i = 0; i < offset; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= totalDays; day++) {
      final date = DateTime(
        _displayedMonth.year,
        _displayedMonth.month,
        day,
      );

      final selected = _isSameDate(date, _selectedDate);
      final disabled = _isDisabled(date);

      cells.add(
        GestureDetector(
          onTap: disabled
              ? null
              : () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: selected
                  ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.primaryGreen,
                  widget.secondaryGreen,
                ],
              )
                  : null,
              color: selected ? null : Colors.white.withOpacity(0.00),
              boxShadow: selected
                  ? [
                BoxShadow(
                  color: widget.primaryGreen.withOpacity(0.34),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.20),
                  blurRadius: 1,
                  offset: const Offset(0, -0.5),
                ),
              ]
                  : [],
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                color: disabled
                    ? Colors.white.withOpacity(0.22)
                    : selected
                    ? const Color(0xFF062116)
                    : Colors.white.withOpacity(0.90),
                fontWeight: FontWeight.w900,
                fontSize: selected ? 16 : 15,
                fontStyle: FontStyle.italic,
              ),
              child: Text('$day'),
            ),
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 24,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 95,
            sigmaY: 95,
          ),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: Colors.white.withOpacity(0.34),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 34,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(
                  color: widget.primaryGreen.withOpacity(0.16),
                  blurRadius: 34,
                  offset: const Offset(0, 8),
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.24),
                  widget.primaryGreen.withOpacity(0.16),
                  widget.darkGreen.withOpacity(0.44),
                  Colors.white.withOpacity(0.07),
                ],
                stops: const [0.0, 0.34, 0.74, 1.0],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(34),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -95,
                            left: -95,
                            child: _SoftGlowBlob(
                              size: 260,
                              color: widget.softGreen.withOpacity(0.22),
                              blur: 58,
                            ),
                          ),
                          Positioned(
                            top: 145,
                            right: -125,
                            child: _SoftGlowBlob(
                              size: 300,
                              color: widget.primaryGreen.withOpacity(0.16),
                              blur: 70,
                            ),
                          ),
                          Positioned(
                            bottom: -125,
                            right: -140,
                            child: _SoftGlowBlob(
                              size: 340,
                              color: widget.secondaryGreen.withOpacity(0.18),
                              blur: 78,
                            ),
                          ),
                          Positioned(
                            bottom: 80,
                            left: -140,
                            child: _SoftGlowBlob(
                              size: 300,
                              color: widget.darkGreen.withOpacity(0.38),
                              blur: 74,
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(34),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.18),
                                    Colors.white.withOpacity(0.08),
                                    widget.darkGreen.withOpacity(0.18),
                                    Colors.white.withOpacity(0.05),
                                  ],
                                  stops: const [0.0, 0.34, 0.72, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _GlassCalendarHeader(
                        title: title,
                        subtitle: subtitle,
                        softGreen: widget.softGreen,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              monthTitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.86),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _previousMonth,
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          IconButton(
                            onPressed: _nextMonth,
                            icon: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Row(
                        children: [
                          _WeekdayText('S'),
                          _WeekdayText('M'),
                          _WeekdayText('T'),
                          _WeekdayText('W'),
                          _WeekdayText('T'),
                          _WeekdayText('F'),
                          _WeekdayText('S'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 7,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 6,
                        children: cells,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white.withOpacity(0.72),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, _selectedDate);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: widget.softGreen,
                            ),
                            child: const Text(
                              'OK',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                              ),
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
        ),
      ),
    );
  }
}

class _SoftGlowBlob extends StatelessWidget {
  final double size;
  final Color color;
  final double blur;

  const _SoftGlowBlob({
    required this.size,
    required this.color,
    this.blur = 55,
  });

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: blur,
        sigmaY: blur,
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _GlassCalendarHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color softGreen;

  const _GlassCalendarHeader({
    required this.title,
    required this.subtitle,
    required this.softGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.10),
        border: Border.all(
          color: Colors.white.withOpacity(0.22),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.18),
            Colors.white.withOpacity(0.08),
            softGreen.withOpacity(0.10),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: softGreen.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
              ),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: softGreen,
              size: 26,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select date',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.64),
                    fontSize: 12,
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

class _WeekdayText extends StatelessWidget {
  final String text;

  const _WeekdayText(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.74),
            fontSize: 14,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
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
