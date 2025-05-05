import 'package:flutter/material.dart';
import '../shared/widgets/custom_button.dart';

class SignupChoiceScreen extends StatelessWidget {
  const SignupChoiceScreen({super.key});

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
                Image.asset(
                  'assets/images/illustration.png',
                  height: 200,
                ),
                const SizedBox(height: 40.0),
                Text(
                  'REMEMBER ME',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 40.0),
                CustomButton(
                  text: "S'inscrire en tant que médecin",
                  onPressed: () {
                    Navigator.pushNamed(context, '/doctor-register');
                  },
                ),
                const SizedBox(height: 16.0),
                CustomButton(
                  text: "S'inscrire en tant que patient",
                  onPressed: () {
                    Navigator.pushNamed(context, '/patient-register');
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