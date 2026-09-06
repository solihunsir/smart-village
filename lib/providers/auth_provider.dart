import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends InheritedWidget {
  final AuthService authService;

  const AuthProvider({
    Key? key,
    required this.authService,
    required Widget child,
  }) : super(key: key, child: child);

  static AuthProvider of(BuildContext context) {
    final AuthProvider? result = context
        .dependOnInheritedWidgetOfExactType<AuthProvider>();
    assert(result != null, 'No AuthProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AuthProvider oldWidget) {
    return authService != oldWidget.authService;
  }
}
