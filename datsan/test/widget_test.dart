import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:datsan/main.dart';
import 'package:datsan/api_client.dart';
import 'package:datsan/member.dart';
import 'package:datsan/session_helper.dart';

const memberJson = {
  'id': 'member-id',
  'email': 'test@example.com',
  'givenName': 'An',
  'surname': 'Nguyen',
  'phone': '0900000000',
  'roleId': 1,
  'role': 'Member',
  'isLocked': false,
  'emailConfirmed': false,
  'rowVersion': 'AAAAAAAB',
};
Map<String, dynamic> tokens({String role = 'Member'}) => {
  'success': true,
  'message': 'OK',
  'token': 'new-access',
  'refreshToken': 'new-refresh',
  'expiresAt': '2026-11-22T12:00:00Z',
  'member': {...memberJson, 'role': role, 'roleId': role == 'Admin' ? 2 : 1},
};
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  testWidgets('Guest login validates form and then stores Member session', (
    tester,
  ) async {
    int logins = 0;
    final api = ApiClient(
      'http://example.test',
      client: MockClient((request) async {
        if (request.url.path.endsWith('/category')) {
          return http.Response('[{"id":1,"name":"Pickleball"}]', 200);
        }
        if (request.url.path.endsWith('/auth/login')) {
          logins++;
          return http.Response(jsonEncode(tokens()), 200);
        }
        return http.Response('{}', 404);
      }),
    );
    final session = SessionHelper(api)..ready = true;
    await tester.pumpWidget(MyApp(session: session));
    await tester.pumpAndSettle();
    expect(find.text('Pickleball'), findsOneWidget);
    expect(find.text('Quản lý thành viên'), findsNothing);
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(logins, 0);
    expect(find.text('Nhập email hợp lệ'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'test@example.com');
    await tester.enterText(fields.at(1), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(logins, 1);
    expect(session.member?.role, 'Member');
    expect(await session.storage.read(key: 'sb2_refresh'), 'new-refresh');
    expect(find.text('Quản lý thành viên'), findsNothing);
  });
  testWidgets('Only Admin sees member management entry', (tester) async {
    final api = ApiClient(
      'http://example.test',
      client: MockClient((request) async => http.Response('[]', 200)),
    );
    final session = SessionHelper(api)
      ..ready = true
      ..member = Member.fromMap({...memberJson, 'role': 'Admin', 'roleId': 2});
    await tester.pumpWidget(MyApp(session: session));
    await tester.pumpAndSettle();
    expect(find.text('Quản lý thành viên'), findsOneWidget);
    session.setMember(Member.fromMap(memberJson));
    await tester.pumpAndSettle();
    expect(find.text('Quản lý thành viên'), findsNothing);
  });
  test('Concurrent expired requests share one refresh operation', () async {
    int refreshes = 0;
    final api = ApiClient(
      'http://example.test',
      client: MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          refreshes++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return http.Response(jsonEncode(tokens()), 200);
        }
        if (request.headers['authorization'] == 'Bearer expired') {
          return http.Response('', 401);
        }
        return http.Response(jsonEncode(memberJson), 200);
      }),
    );
    final session = SessionHelper(api);
    api.token = 'expired';
    await session.storage.write(key: 'sb2_refresh', value: 'old-refresh');
    final result = await Future.wait([
      api.call('GET', '/member/me'),
      api.call('GET', '/member/me'),
    ]);
    expect(refreshes, 1);
    expect(result.length, 2);
    expect(api.token, 'new-access');
    expect(await session.storage.read(key: 'sb2_refresh'), 'new-refresh');
  });
  test('Revoked refresh clears local credentials', () async {
    final api = ApiClient(
      'http://example.test',
      client: MockClient((_) async => http.Response('', 401)),
    );
    final session = SessionHelper(api)..member = Member.fromMap(memberJson);
    api.token = 'old';
    await session.storage.write(key: 'sb2_refresh', value: 'revoked');
    await expectLater(
      api.call('GET', '/member/me'),
      throwsA(isA<ApiException>()),
    );
    expect(session.member, isNull);
    expect(api.token, isNull);
    expect(await session.storage.read(key: 'sb2_refresh'), isNull);
  });
  test(
    'Temporary refresh network failure keeps credentials for retry',
    () async {
      final api = ApiClient(
        'http://example.test',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/auth/refresh')) {
            throw http.ClientException('offline');
          }
          return http.Response('', 401);
        }),
      );
      final session = SessionHelper(api)..member = Member.fromMap(memberJson);
      api.token = 'old';
      await session.storage.write(key: 'sb2_refresh', value: 'keep-me');
      await expectLater(
        api.call('GET', '/member/me'),
        throwsA(isA<ApiException>()),
      );
      expect(session.member, isNotNull);
      expect(await session.storage.read(key: 'sb2_refresh'), 'keep-me');
    },
  );
}
