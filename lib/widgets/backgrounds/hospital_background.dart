import 'package:flutter/material.dart';
import 'package:hospital_management_app/utils/app_theme.dart';
import 'dart:math' as math;

import '../../utils/constants.dart';

// Base Hospital Background
class HospitalBackground extends StatelessWidget {
  final Widget child;
  final BackgroundStyle style;

  const HospitalBackground({
    super.key,
    required this.child,
    this.style = BackgroundStyle.simple,
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case BackgroundStyle.simple:
        return SimpleBackground(child: child);
      case BackgroundStyle.dots:
        return DotsBackground(child: child);
      case BackgroundStyle.gradient:
        return GradientBackground(child: child);
      case BackgroundStyle.circles:
        return CirclesBackground(child: child);
      case BackgroundStyle.lines:
        return LinesBackground(child: child);
    }
  }
}

enum BackgroundStyle {
  simple,
  dots,
  gradient,
  circles,
  lines,
}

// 1. Simple Clean Background (Default)
class SimpleBackground extends StatelessWidget {
  final Widget child;

  const SimpleBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FD), // Very light blue-gray
      ),
      child: Stack(
        children: [
          // Subtle top-right decoration
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withOpacity(0.03),
              ),
            ),
          ),
          // Subtle bottom-left decoration
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentTeal.withOpacity(0.02),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// 2. Dots Pattern Background
class DotsBackground extends StatelessWidget {
  final Widget child;

  const DotsBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAFBFD),
      child: Stack(
        children: [
          CustomPaint(
            painter: DotsPainter(),
            size: Size.infinite,
          ),
          child,
        ],
      ),
    );
  }
}

class DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryBlue.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    const spacing = 40.0;
    const dotRadius = 2.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 3. Soft Gradient Background
class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF0F4F8), // Very light blue
            Color(0xFFFFFFFFF), // White
            Color(0xFFF5F8FA), // Very light gray-blue
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }
}

// 4. Circles Pattern Background
class CirclesBackground extends StatelessWidget {
  final Widget child;

  const CirclesBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFCFCFD),
      child: Stack(
        children: [
          CustomPaint(
            painter: CirclesPainter(),
            size: Size.infinite,
          ),
          child,
        ],
      ),
    );
  }
}

class CirclesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw random circles with very light colors
    final random = math.Random(42);

    for (int i = 0; i < 8; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 50 + random.nextDouble() * 150;

      paint.color = [
        AppColors.primaryBlue.withOpacity(0.02),
        AppColors.accentTeal.withOpacity(0.02),
        AppColors.lightBlue.withOpacity(0.02),
      ][i % 3];

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 5. Simple Lines Pattern Background
class LinesBackground extends StatelessWidget {
  final Widget child;

  const LinesBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAFBFD),
      child: Stack(
        children: [
          CustomPaint(
            painter: LinesPainter(),
            size: Size.infinite,
          ),
          child,
        ],
      ),
    );
  }
}

class LinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryBlue.withOpacity(0.03)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const spacing = 50.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Bonus: Custom Wave Background (Simple version)
class SimpleWaveBackground extends StatelessWidget {
  final Widget child;

  const SimpleWaveBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: Colors.white),
        CustomPaint(
          painter: SimpleWavePainter(),
          size: Size.infinite,
        ),
        child,
      ],
    );
  }
}

class SimpleWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryBlue.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.15);

    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.10,
      size.width * 0.5,
      size.height * 0.15,
    );

    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.20,
      size.width,
      size.height * 0.15,
    );

    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Medical Card Pattern (For specific cards)
class MedicalCardBackground extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;

  const MedicalCardBackground({
    super.key,
    required this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Small medical cross in corner
          Positioned(
            top: 10,
            right: 10,
            child: CustomPaint(
              painter: SmallCrossPainter(),
              size: const Size(20, 20),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class SmallCrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryBlue.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final horizontalRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width,
        height: size.height * 0.3,
      ),
      const Radius.circular(2),
    );

    final verticalRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.3,
        height: size.height,
      ),
      const Radius.circular(2),
    );

    canvas.drawRRect(horizontalRect, paint);
    canvas.drawRRect(verticalRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}