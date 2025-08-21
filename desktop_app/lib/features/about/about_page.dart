import 'package:flutter/material.dart';
import '../../shared/utils/constants.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.aboutTitle)),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('This is a sample Flutter desktop app scaffold.'),
        ),
      ),
    );
  }
}