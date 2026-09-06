// File: lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:device_wrapper/device_wrapper.dart';

import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/profile_page.dart';
import 'pages/splash_screen.dart';
import 'pages/village_profile_page.dart';

// 🛑 MODIFIKASI: Impor AuthService tetapi HIDE AuthProvider
// (karena Anda sudah mengimpornya dari providers/auth_provider.dart)
import 'services/auth_service.dart' hide AuthProvider;

import 'pages/simple_product_detail_page.dart';
import 'models/product.dart';
import 'providers/theme_provider.dart';

// 🛑 MODIFIKASI: Impor AuthProvider dari folder providers
import 'providers/auth_provider.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AuthService untuk restore session
  AuthService().initialize().whenComplete(() {
    // Tentukan rute awal berdasarkan status login
    final initialRoute = AuthService().isLoggedIn ? '/home' : '/';

    // Wrap the application with the ThemeProvider
    runApp(
      ChangeNotifierProvider(
        create: (context) => ThemeProvider()
          ..fetchActiveTheme(), // Memuat tema saat aplikasi dimulai
        child: MyApp(initialRoute: initialRoute),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  final String initialRoute; // Tambahkan properti untuk rute awal
  const MyApp({super.key, required this.initialRoute});

  // 🎯 Fungsi Pembungkus (Wrapper) Utama
  Widget _buildMaterialApp(BuildContext context) {
    // 💡 Tentukan skema teks untuk Inter (Font Display)
    final interTextTheme = const TextTheme().apply(fontFamily: 'Inter');

    return MaterialApp(
      title: 'Smart Village',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50],
        fontFamily: 'Roboto',
        textTheme: interTextTheme.copyWith(
          displayLarge: interTextTheme.displayLarge,
          displayMedium: interTextTheme.displayMedium,
          displaySmall: interTextTheme.displaySmall,
          headlineLarge: interTextTheme.headlineLarge,
          headlineMedium: interTextTheme.headlineMedium,
          headlineSmall: interTextTheme.headlineSmall,
          titleLarge: interTextTheme.titleLarge,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          titleTextStyle: interTextTheme.titleLarge?.copyWith(
                color: Colors.black,
                fontSize: 19,
                fontWeight: FontWeight.normal,
              ) ??
              const TextStyle(
                fontFamily: 'Inter',
                color: Colors.black,
                fontSize: 19,
                fontWeight: FontWeight.normal,
              ),
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const MainScreen(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/profile': (context) => const ProfilePage(),
        '/village_profile': (context) => const VillageProfilePage(),
        '/product_detail': (context) {
          final product = ModalRoute.of(context)!.settings.arguments as Product;
          return SimpleProductDetailPage(product: product);
        },
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Definisikan MaterialApp
    final materialApp = _buildMaterialApp(context);

    // 2. Bungkus dengan AuthProvider
    final authWrappedApp = AuthProvider(
      authService: AuthService(),
      child: materialApp,
    );

    // 3. Terapkan logika DeviceWrapper HANYA jika berjalan di web
    if (kIsWeb) {
      // 🚀 KOREKSI AKHIR: Menghapus properti initialMode yang bermasalah.
      return DeviceWrapper(
        // initialMode Dihapus
        showModeToggle: true,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: authWrappedApp,
        ),
      );
    }

    // 4. Jika bukan di web, kembalikan aplikasi yang dibungkus AuthProvider
    return authWrappedApp;
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: HomePage());
  }
}
