import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'session.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FdpApp());
}

class FdpApp extends StatefulWidget {
  const FdpApp({super.key});

  @override
  State<FdpApp> createState() => _FdpAppState();
}

class _FdpAppState extends State<FdpApp> {
  final _session = Session();

  @override
  void initState() {
    super.initState();
    _session.load();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chapersons',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B3F24)),
        scaffoldBackgroundColor: const Color(0xFFF6F1EA),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(),
        ),
        useMaterial3: true,
      ),
      home: ListenableBuilder(
        listenable: _session,
        builder: (context, _) {
          if (!_session.ready) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (_session.token == null || _session.user == null) {
            return LoginScreen(session: _session);
          }
          return HomeScreen(session: _session);
        },
      ),
    );
  }
}
