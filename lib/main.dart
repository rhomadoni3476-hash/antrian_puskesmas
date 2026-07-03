import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'firebase_options.dart';
import 'antrian_provider.dart';
import 'privacy_provider.dart';
import 'theme_provider.dart';
import 'home_nav_screen.dart';
import 'login_pasien_screen.dart';
import 'notification_service.dart';
import 'admin_dashboard_screen.dart';
import 'profile_screen.dart';

// Navigator key untuk akses navigasi tanpa context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Logging error global
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint("Flutter Error: ${details.exceptionAsString()}");
  };

  // Inisialisasi Firebase & Service
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    await initializeDateFormatting('id_ID', null);
    if (!kIsWeb) {
      await NotificationService.initialize();
    }
  } catch (e) {
    debugPrint("Gagal Inisialisasi Firebase: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AntrianProvider()),
        ChangeNotifierProvider(create: (_) => PrivacyProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Puskesmas Digital',
          navigatorKey: navigatorKey,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.redAccent,
            brightness: Brightness.light,
            textTheme: GoogleFonts.poppinsTextTheme(),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.redAccent,
            brightness: Brightness.dark,
            textTheme:
                GoogleFonts.poppinsTextTheme(Typography.whiteMountainView),
          ),
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginPasienScreen(),
            '/home': (context) => const HomeNavScreen(),
            '/admin': (context) => const AdminDashboardScreen(),
            '/profile': (context) => const ProfileScreen(),
          },
          onGenerateRoute: (settings) {
            // Logika fallback jika rute salah
            return MaterialPageRoute(
                builder: (context) => const SplashScreen());
          },
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Memberikan waktu minimal untuk animasi splash
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Menggunakan timeout untuk mencegah request gantung
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 5));

        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data() as Map<String, dynamic>;
          final String role = data['role'] ?? 'pasien';

          if (role == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin');
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } catch (e) {
        debugPrint("Error saat cek role: $e");
        // Jika gagal ambil data, tetap arahkan ke home sebagai fallback aman
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.redAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animasi_utama.json',
              width: 200,
              height: 200,
              repeat: true,
              errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.medical_services,
                  size: 100,
                  color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              "PUSKESMAS DIGITAL",
              style: GoogleFonts.poppins(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
