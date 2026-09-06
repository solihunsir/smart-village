import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../pages/login_page.dart';
class AuthGuard {
static Future<bool> checkAuth(BuildContext context) async {
final authService = AuthService();
if (!authService.isLoggedIn) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Anda harus login terlebih dahulu'),
duration: Duration(seconds: 2),
),
);
await Navigator.push(
context,
MaterialPageRoute(builder: (context) => const LoginPage()),
);
return authService.isLoggedIn;
}
return true;
}
}

