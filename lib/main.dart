import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/tflite_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OliveCounterApp());
}

class OliveCounterApp extends StatelessWidget {
  const OliveCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => TfliteService())],
      child: MaterialApp(
        title: 'Olive Counter',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
        home: const HomeScreen(),
      ),
    );
  }
}
