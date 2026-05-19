import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/clay_theme.dart';
import 'features/auth/auth_wrapper.dart';
import 'providers/auth_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/cashier_shift_provider.dart';
import 'providers/product_provider.dart';
import 'providers/stock_provider.dart';
import 'providers/transaction_provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CashierShiftProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => StockProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'BANGJUN SPOT',
        theme: ClayTheme.light(),
        home: const AuthWrapper(),
      ),
    );
  }
}
