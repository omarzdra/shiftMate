import 'package:flutter/material.dart';

void main() {
  runApp(const ShiftMateApp());
}

class ShiftMateApp extends StatelessWidget {
  const ShiftMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShiftMate Business',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3158D9)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ShiftMate Business')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_outlined, size: 64),
            SizedBox(height: 16),
            Text(
              'Dobrodošli v ShiftMate Business',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text('Upravljanje delovnih izmen'),
          ],
        ),
      ),
    );
  }
}
