import 'package:flutter/material.dart';

class SwirlBackground extends StatelessWidget {
  const SwirlBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final swirlColors = isDark
        ? const [
            Color.fromARGB(255, 128, 17, 17),
            Color.fromARGB(255, 0, 24, 145),
            Color.fromARGB(255, 193, 91, 2),
            Color.fromARGB(255, 128, 17, 17),
          ]
        : const [
            Color.fromARGB(255, 255, 151, 151),
            Color.fromARGB(255, 156, 172, 255),
            Color.fromARGB(255, 232, 179, 132),
            Color.fromARGB(255, 255, 151, 151),
          ];

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
