import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_screen.dart';
import 'chat_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider(),
      child: MaterialApp(
        title: 'Cogo Chat App',
        theme: ThemeData(
          colorScheme: const ColorScheme.light(
            brightness: Brightness.light,
            primary: Color(0xFF000000), // Black
            secondary: Color(0xFF666666), // Gray
            surface: Color(0xFFFFFFFF), // White background
            background: Color(0xFFFFFFFF), // White background
            onSurface: Color(0xFF000000), // Black text
            onBackground: Color(0xFF000000), // Black text
            onPrimary: Color(0xFFFFFFFF), // White on black
            onSecondary: Color(0xFFFFFFFF), // White on gray
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFFFFFFF), // White background
        ),
        home: const Scaffold(
          backgroundColor: Color(0xFFFFFFFF),
          body: ChatScreen(),
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
