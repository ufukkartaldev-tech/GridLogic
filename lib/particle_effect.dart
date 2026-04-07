import 'package:flutter/material.dart';
import 'dart:math';

class Particle {
  final double x;
  final double y;
  final double size;
  final Color color;
  final double velocityX;
  final double velocityY;
  final double life;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    this.velocityX = (Random().nextDouble() - 0.5) * 2,
    this.velocityY = (Random().nextDouble() - 0.5) * 2,
    this.life = 1.0,
  });

  void update(double deltaTime) {
    x += velocityX * deltaTime;
    y += velocityY * deltaTime;
    life -= deltaTime;
  }

  bool isAlive() {
    return life > 0;
  }
}

class ParticleEffect extends StatefulWidget {
  final List<Particle> particles;
  final Duration duration;

  const ParticleEffect({
    super.key,
    required this.particles,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<ParticleEffect> createState() => _ParticleEffectState();
}

class _ParticleEffectState extends State<ParticleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(particles: widget.particles, progress: _animation.value),
          size: Size.infinite,
          child: Container(),
        );
      },
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (Particle particle in particles) {
      double opacity = (1.0 - particle.life) * (1.0 - progress);
      if (opacity <= 0) continue;
      
      final paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size * (1.0 - particle.life * 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
