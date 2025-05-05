import 'package:flutter/material.dart';
import '../shared/widgets/custom_button.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // Départ du bas
      end: Offset.zero, // Arrivée à la position normale
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SlideTransition(
                  position: _slideAnimation,
                  child: Image.asset(
                    'assets/images/illustration.png',
                    height: 200,
                  ),
                ),
                const SizedBox(height: 40.0),
                Text(
                  'REMEMBER ME',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 40.0),
                CustomButton(
                  text: 'SE CONNECTER',
                  onPressed: () {
                    Navigator.pushNamed(context, '/auth');
                  },
                ),
                const SizedBox(height: 16.0),
                CustomButton(
                  text: "S'INSCRIRE",
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup-choice');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}