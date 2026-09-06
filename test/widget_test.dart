import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Pastikan import ini benar (sesuaikan path jika perlu):
import 'package:desaku/main.dart';
import 'package:desaku/services/auth_service.dart'; // Dibutuhkan oleh AuthProvider

Widget createTestWidget() {
  return AuthProvider(
    // Dalam tes, kita menggunakan instance AuthService yang sama.
    authService: AuthService(),
    child: const MyApp(
      // Menyediakan properti 'initialRoute' yang wajib.
      initialRoute: '/',
    ),
  );
}

// -------------------------------------------------------------
void main() {
  testWidgets('App boots and shows splash', (WidgetTester tester) async {
    // ✅ Menggunakan wrapper widget untuk menjalankan MyApp dengan argumen lengkap
    await tester.pumpWidget(createTestWidget());

    // Ensure MaterialApp is built
    expect(find.byType(MaterialApp), findsOneWidget);

    // Splash screen title should be visible
    expect(find.text('e-Village'), findsOneWidget);

    // Let the 3s timer run to completion to avoid pending timers
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
