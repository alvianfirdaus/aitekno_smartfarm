import 'package:flutter/material.dart';
import 'package:aitekno_smartfarm/Pages/dashboard.dart';
import 'package:aitekno_smartfarm/Pages/splashscreen.dart';
import 'package:aitekno_smartfarm/Pages/settings.dart';
import 'package:aitekno_smartfarm/Pages/addcatatan.dart';
import 'package:aitekno_smartfarm/Pages/editcatatan.dart';
import 'package:aitekno_smartfarm/Pages/akun.dart';
import 'package:aitekno_smartfarm/Pages/login.dart';
import 'package:aitekno_smartfarm/Pages/register.dart';
import 'package:aitekno_smartfarm/Pages/daftarAlat.dart';
import 'package:aitekno_smartfarm/Pages/tambahAlat.dart';

class Routes {
  static const String splash = '/';
  static const String dashboard = '/dashboard';
  static const String akun = '/akun';
  static const String settings = '/settings';
  static const String addCatatan = '/addcatatan';
  static const String editCatatan = '/editcatatan';
  static const String loginPage = '/loginpage';
  static const String registerPage = '/registerpage';
  static const String daftarAlatPage = '/daftaralatpage';
  static const String tambahAlatPage = '/tambahalatpage';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => SplashScreen(),
    dashboard: (context) => DashboardScreen(),
    loginPage: (context) => LoginPage(),
    registerPage:(context) => RegisterPage(),
    daftarAlatPage:(context) => DaftarAlatPage(),
    tambahAlatPage:(context) => TambahAlatPage(),
    akun: (context) => AkunScreen(),
    settings: (context) => SettingsPage(),
    addCatatan: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        return AddCatatanScreen(selectedPlot: args);
      } else {
        return AddCatatanScreen(selectedPlot: ''); // Nilai default jika null
      }
    },
    editCatatan: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        return EditCatatanScreen(
          selectedPlot: args['selectedPlot'] ?? '',
          catatanKey: args['catatanKey'] ?? '',
          initialCatatan: args['initialCatatan'] ?? '',
          initialTanggal: args['initialTanggal'] ?? '',
          initialWaktu: args['initialWaktu'] ?? '',
        );
      } else {
        return EditCatatanScreen(
          selectedPlot: '',
          catatanKey: '',
          initialCatatan: '',
          initialTanggal: '',
          initialWaktu: '',
        ); // Nilai default jika `arguments` tidak sesuai
      }
    },
  };
}
