import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_pantry/pantry.dart';
import 'package:my_pantry/shopping.dart';
import 'package:my_pantry/widgets/appdrawer.dart';
import 'package:my_pantry/widgets/swirl_bg.dart';

class HomePager extends StatefulWidget {
  const HomePager({super.key});

  @override
  State<HomePager> createState() => _HomePagerState();
}

class _HomePagerState extends State<HomePager> {
  late PageController _controller = PageController(initialPage: 0);
  int _currentPage = 0;
  late AnimationController _swirlController;


  final pantryKey = GlobalKey<PantryPageState>();
  final shoppingKey = GlobalKey<ShoppingListPageState>();

  bool _showListName = false;
  bool _animateTitle = false;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final initialPage = args != null && args['initialPage'] != null
        ? args['initialPage'] as int
        : 0;

    _controller = PageController(initialPage: initialPage);
    _currentPage = initialPage;
  }
  

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

void _onPageChanged(int index) {
  _timer?.cancel();

  setState(() {
    _currentPage = index;
    _showListName = false;
    _animateTitle = false;
  });

  _timer = Timer(const Duration(milliseconds: 1000), () {
    if (!mounted) return;

    // Double check again, just in case
    if (_currentPage == index) {
      setState(() {
        _showListName = true;
      });
    }
  });
}

  void _openDrawer() {
    Scaffold.of(context).openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final pantryState = pantryKey.currentState;
    final shoppingState = shoppingKey.currentState;

    // ✅ Compute title text once
    final String titleText = _showListName
        ? (_currentPage == 0
            ? (pantryState?.selectedListName ?? 'Pantry')
            : (shoppingState?.selectedListName ?? 'Shopping List'))
        : (_currentPage == 0 ? 'Pantry' : 'Shopping List');

  return Scaffold(
  appBar: AppBar(
    title: AnimatedSwitcher(
      duration: _showListName ? const Duration(milliseconds: 300) : Duration.zero,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: Text(
        titleText,
        key: ValueKey<String>(titleText),
      ),
    ),
  ),
  endDrawer: AppDrawer(pageController: _controller),
  body: Stack(
    children: [
      const SwirlBackground(),

      // Main content
      Positioned.fill(
        child: PageView(
          controller: _controller,
          onPageChanged: _onPageChanged,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: PantryPage(key: pantryKey),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: ShoppingListPage(key: shoppingKey),
            ),
          ],
        ),
      ),

      // Bottom nav dots OVER the swirl
      Positioned(
        bottom: 25,
        left: 0,
        right: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) {
            return GestureDetector(
              onTap: () {
                if (_currentPage != index) {
                  _controller.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 12 : 8,
                height: _currentPage == index ? 12 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index ? Colors.blue : Colors.grey.shade400,
                ),
              ),
            );
          }),
        ),
      ),
    ],
  ),
);

  }
}
