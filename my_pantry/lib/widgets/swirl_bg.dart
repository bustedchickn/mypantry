import 'package:flutter/material.dart';

class SwirlBackground extends StatelessWidget {
  final List<Color> swirlColors;

  const SwirlBackground({
    super.key,
    this.swirlColors = const [
      Color.fromARGB(255, 128, 17, 17),  // Dark Crimson
      Color.fromARGB(255, 0, 24, 145),   // Deep Red-Orange
      Color.fromARGB(255, 193, 91, 2), // Warm Gold-Orange
      Color.fromARGB(255, 128, 17, 17),  // Back to Crimson
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: SweepGradient(
          center: Alignment.center,
          startAngle: 0.0,
          endAngle: 6.28,
          colors: swirlColors,
          stops: [0.0, 0.4, 0.8, 1.0],
        ),
      ),
    );
  }
}
