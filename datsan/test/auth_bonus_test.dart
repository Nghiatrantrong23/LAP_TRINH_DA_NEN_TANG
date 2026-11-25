import 'dart:convert';

import 'package:datsan/api_client.dart';
import 'package:datsan/login_page.dart';
import 'package:datsan/session_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('Forgot password submits email, then OTP and new password', (
    tester,
  ) async {
    final paths = <String>[];
    final payloads = <Object?>[];
    final session = SessionHelper(
      ApiClient(
        'http://example.test',
        client: MockClient((request) async {
          paths.add(request.url.path);
          payloads.add(jsonDecode(request.body));
          return http.Response('', 204);
        }),
      ),
    );
    await tester.pumpWidget(MaterialApp(home: LoginPage(session: session)));
    await tester.tap(find.text('Quên mật khẩu?'));
    await tester.pumpAndSettle();
    Finder dialogFields() => find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dialogFields().first, 'test@example.com');
    await tester.tap(find.text('Gửi mã xác nhận'));
    await tester.pumpAndSettle();
    await tester.enterText(dialogFields().first, '012345');
    await tester.enterText(dialogFields().last, 'New-Test@123');
    await tester.tap(find.text('Đổi mật khẩu'));
    await tester.pumpAndSettle();
    expect(paths.map((path) => path.split('/').last), [
      'forgot-password',
      'reset-password',
    ]);
    expect(payloads, [
      {'email': 'test@example.com'},
      {
        'email': 'test@example.com',
        'otp': '012345',
        'newPassword': 'New-Test@123',
      },
    ]);
    expect(find.text('Đã đổi mật khẩu. Bạn có thể đăng nhập.'), findsOneWidget);
  });
}
