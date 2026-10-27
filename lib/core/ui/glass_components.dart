import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LinerColors {
  static const Color background = Color(0xFF08090C);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color spotifyNeon = Color(0xFF1DB954);
  static const Color soundcloudNeon = Color(0xFFFF5500);
  static const Color youtubeNeon = Color(0xFFFF0000);
  static const Color appleNeon = Color(0xFFFA243C);
  static const Color yandexNeon = Color(0xFFFFCC00);
}

/// Кастомный контейнер с эффектом матового стекла (Frosted Glass)
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double opacity;
  final double blurSigma;
  final Color? glowColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.padding,
    this.margin,
    this.opacity = 0.06,
    this.blurSigma = 24.0,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withOpacity(0.25),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1.0,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(opacity + 0.03),
                  Colors.white.withOpacity(opacity - 0.02),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Динамическая фоновая подложка, меняющая цвет под обложку трека/альбома
class DynamicBackgroundWrapper extends StatefulWidget {
  final String? imageUrl;
  final Widget child;

  const DynamicBackgroundWrapper({
    super.key,
    required this.imageUrl,
    required this.child,
  });

  @override
  State<DynamicBackgroundWrapper> createState() => _DynamicBackgroundWrapperState();
}

class _DynamicBackgroundWrapperState extends State<DynamicBackgroundWrapper> {
  Color _dominantColor = const Color(0xFF1A233A);
  Color _vibrantColor = const Color(0xFF3A1A28);

  @override
  void initState() {
    super.initState();
    _extractPalette(widget.imageUrl);
  }

  @override
  void didUpdateWidget(covariant DynamicBackgroundWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _extractPalette(widget.imageUrl);
    }
  }

  Future<void> _extractPalette(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(url),
        maximumColorCount: 12,
      );
      if (mounted) {
        setState(() {
          _dominantColor = palette.dominantColor?.color ?? const Color(0xFF1A233A);
          _vibrantColor = palette.vibrantColor?.color ??
              palette.mutedColor?.color ??
              const Color(0xFF3A1A28);
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LinerColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Цветовые пятна
          AnimatedPositioned(
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            top: -100,
            left: -80,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 900),
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _dominantColor.withOpacity(0.45),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            bottom: 80,
            right: -100,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 900),
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _vibrantColor.withOpacity(0.35),
              ),
            ),
          ),
          // Размытие (sigmaX: 45, sigmaY: 45)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 45.0, sigmaY: 45.0),
            child: Container(color: Colors.transparent),
          ),
          // Основной контент
          SafeArea(child: widget.child),
        ],
      ),
    );
  }
}