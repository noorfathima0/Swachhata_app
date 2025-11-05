import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'routes/app_router.dart';
import 'ui/auth/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SwachhataApp());
}

class SwachhataApp extends StatelessWidget {
  const SwachhataApp({super.key});

  Future<String?> _getRole(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return snap.data()?['role'];
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            title: 'Swachhata App',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(primarySwatch: Colors.green),
            locale: localeProvider.locale,
            supportedLocales: const [Locale('en'), Locale('kn')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            onGenerateRoute: AppRouter.generateRoute,
            initialRoute: AppRouter.login,
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (!snapshot.hasData) return const LoginPage();
                final user = snapshot.data!;

                return FutureBuilder<String?>(
                  future: _getRole(user.uid),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return NavigatorPage(
                      route: snap.data == 'admin'
                          ? AppRouter.adminDashboard
                          : AppRouter.userDashboard,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class NavigatorPage extends StatelessWidget {
  final String route;

  const NavigatorPage({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, route);
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
