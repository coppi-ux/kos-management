import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';
import 'role_select_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final auth = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        ),
      );
    }
  }

  void _goBackToRoleSelect() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const RoleSelectScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _goBackToRoleSelect();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: const Color(0xFF0F3D2E),
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

            // Back button floating
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 14,
              child: _GlassIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: _goBackToRoleSelect,
              ),
            ),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 48,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 430),
                          child: Transform.translate(
                            offset: const Offset(0, -38),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _LiquidGlassCard(
                                  borderRadius: 34,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 22,
                                      vertical: 30,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                      children: [
                                        const _KostInLogo(),
                                        const SizedBox(height: 24),
                                        const SizedBox(
                                          width: double.infinity,
                                          child: Text(
                                            'KostIn.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.8,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          width: double.infinity,
                                          child: Text(
                                            'Login to your account',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color:
                                              Colors.white.withOpacity(0.68),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: -0.1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _LiquidGlassCard(
                                  borderRadius: 30,
                                  child: Padding(
                                    padding: const EdgeInsets.all(22),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Email',
                                          style: TextStyle(
                                            color:
                                            Colors.white.withOpacity(0.86),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            letterSpacing: -0.1,
                                          ),
                                        ),
                                        const SizedBox(height: 9),
                                        _GlassTextField(
                                          controller: _emailController,
                                          hintText: 'owner@kos.com',
                                          icon: Icons.email_outlined,
                                          keyboardType:
                                          TextInputType.emailAddress,
                                        ),
                                        const SizedBox(height: 18),
                                        Text(
                                          'Password',
                                          style: TextStyle(
                                            color:
                                            Colors.white.withOpacity(0.86),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            letterSpacing: -0.1,
                                          ),
                                        ),
                                        const SizedBox(height: 9),
                                        _GlassTextField(
                                          controller: _passwordController,
                                          hintText: '••••••••',
                                          icon: Icons.lock_outline_rounded,
                                          obscureText: _obscurePassword,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_off_rounded
                                                  : Icons.visibility_rounded,
                                              color:
                                              Colors.white.withOpacity(0.70),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                !_obscurePassword;
                                              });
                                            },
                                          ),
                                        ),
                                        if (auth.errorMessage != null) ...[
                                          const SizedBox(height: 16),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFF3B30)
                                                  .withOpacity(0.14),
                                              borderRadius:
                                              BorderRadius.circular(18),
                                              border: Border.all(
                                                color: const Color(0xFFFF3B30)
                                                    .withOpacity(0.35),
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
                                                    auth.errorMessage!,
                                                    style: const TextStyle(
                                                      color: Color(0xFFFFDAD6),
                                                      fontSize: 13,
                                                      fontWeight:
                                                      FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 26),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 54,
                                          child: ElevatedButton(
                                            onPressed:
                                            auth.isLoading ? null : _login,
                                            style: ElevatedButton.styleFrom(
                                              elevation: 0,
                                              backgroundColor:
                                              const Color(0xFF34D399),
                                              disabledBackgroundColor:
                                              Colors.white.withOpacity(0.20),
                                              foregroundColor:
                                              const Color(0xFF062116),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                BorderRadius.circular(18),
                                              ),
                                            ),
                                            child: auth.isLoading
                                                ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child:
                                              CircularProgressIndicator(
                                                strokeWidth: 2.4,
                                                color: Color(0xFF062116),
                                              ),
                                            )
                                                : const Text(
                                              'Login',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                FontWeight.w800,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Don't have an account? ",
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.62),
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                  const RegisterScreen(),
                                                ),
                                              ),
                                              child: const Text(
                                                'Register',
                                                style: TextStyle(
                                                  color: Color(0xFF6EE7B7),
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
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
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KostInLogo extends StatelessWidget {
  const _KostInLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.30),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF34D399).withOpacity(0.32),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.asset(
          'assets/images/kostin_logo.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.home_work_rounded,
              color: Color(0xFF6EE7B7),
              size: 48,
            );
          },
        ),
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const _GlassTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
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
        suffixIcon: suffixIcon,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.red.withOpacity(0.50),
            width: 1,
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 75,
          sigmaY: 75,
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.045),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 19,
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