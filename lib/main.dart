import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/widgets/auth_wrapper.dart';
import 'services/multi_tenant_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print('✅ Firebase initialized successfully in main');
    
    // Initialize default app owner on first run
    print('🔄 Initializing default app owner...');
    final ownerId = await MultiTenantService.initializeDefaultAppOwner();
    print('🎯 App owner initialization result: $ownerId');
  } catch (e) {
    print('❌ Firebase initialization failed in main: $e');
    print('❌ Stack trace: ${e.toString()}');
  }
  runApp(const VaadlyMainApp());
}

class VaadlyMainApp extends StatelessWidget {
  const VaadlyMainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vaadly - ועד-לי',
      useInheritedMediaQuery: true,
      // Hebrew locale and RTL support
      locale: const Locale('he'),
      supportedLocales: const [
        Locale('he'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        textTheme: GoogleFonts.notoSansHebrewTextTheme(),
        fontFamily: GoogleFonts.notoSansHebrew().fontFamily,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        cardTheme: const CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
      onGenerateRoute: (settings) {
        final routeName = settings.name ?? '/';
        print('🔗 Route requested: $routeName');
        
        final uri = Uri.parse(routeName);
        
        // Handle building-specific URLs: /building/{buildingCode}
        if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'building') {
          final buildingCode = uri.pathSegments[1];
          print('🏢 Building route: $buildingCode');
          return MaterialPageRoute(
            builder: (context) => AuthWrapper(buildingCode: buildingCode),
            settings: settings,
          );
        }
        
        // Handle management URLs: /manage/{buildingCode}
        if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'manage') {
          final buildingCode = uri.pathSegments[1];
          print('🏢 Management route: $buildingCode');
          return MaterialPageRoute(
            builder: (context) => AuthWrapper(
              buildingCode: buildingCode,
              isManagementPortal: true,
            ),
            settings: settings,
          );
        }
        
        // Default routes
        switch (routeName) {
          case '/':
          case '/dashboard':
            return MaterialPageRoute(
              builder: (context) => const AuthWrapper(),
              settings: settings,
            );
          default:
            print('🔗 Default route for: $routeName');
            return MaterialPageRoute(
              builder: (context) => const AuthWrapper(),
              settings: settings,
            );
        }
      },
    );
  }
}

