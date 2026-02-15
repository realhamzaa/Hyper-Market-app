import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'utils/theme.dart';
import 'providers/product_provider.dart';
import 'providers/invoice_provider.dart';
import 'screens/pin_login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تعيين اتجاه الشاشة عمودي فقط
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // تعيين شريط الحالة شفاف
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const HyperMarketApp());
}

class HyperMarketApp extends StatelessWidget {
  const HyperMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
      ],
      child: MaterialApp(
        title: 'هايبر - نظام إدارة السوبرماركت',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        
        // دعم RTL للعربية
        locale: const Locale('ar', 'PS'),
        supportedLocales: const [
          Locale('ar', 'PS'),
        ],
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
        
        home: const PinLoginScreen(),
      ),
    );
  }
}
