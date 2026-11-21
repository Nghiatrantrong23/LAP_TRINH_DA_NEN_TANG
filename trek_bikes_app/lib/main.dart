import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'api_client.dart';
import 'session_helper.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'profile_page.dart';
import 'change_password_page.dart';
import 'admin_member_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(isOptional: true);
  const override = String.fromEnvironment('API_URL');
  final session = SessionHelper(
    ApiClient(
      override.isNotEmpty
          ? override
          : dotenv.env['API_URL'] ?? 'http://localhost:5290',
    ),
  );
  runApp(MyApp(session: session));
  await session.restore();
}

class MyApp extends StatelessWidget {
  final SessionHelper session;
  const MyApp({super.key, required this.session});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SportBooking',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff176448)),
    ),
    home: HomePage(session: session),
    routes: {
      '/login': (_) => LoginPage(session: session),
      '/register': (_) => RegisterPage(repository: session.repository),
      '/profile': (_) => ProfilePage(session: session),
      '/password': (_) => ChangePasswordPage(session: session),
      '/admin/member': (_) => AdminMemberPage(session: session),
    },
  );
}
