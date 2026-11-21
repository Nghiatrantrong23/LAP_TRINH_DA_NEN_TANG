import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trek_bikes_app/api_client.dart';
import 'package:trek_bikes_app/main.dart';
import 'package:trek_bikes_app/member.dart';
import 'package:trek_bikes_app/session_helper.dart';
import 'package:trek_bikes_app/product_edit_page.dart';

const cat = {
  'id': 1,
  'name': 'Pickleball',
  'rowVersion': 'version-1',
  'description': null,
  'imagePath': null,
  'displayOrder': 1,
  'isActive': true,
};
const admin = {
  'id': 'admin-id',
  'email': 'admin@example.com',
  'givenName': 'Admin',
  'surname': 'Demo',
  'phone': null,
  'roleId': 2,
  'role': 'Admin',
  'isLocked': false,
  'emailConfirmed': false,
  'rowVersion': 'version-1',
};
Finder field(String label) => find.ancestor(
  of: find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.labelText == label,
  ),
  matching: find.byType(TextFormField),
);

void main() {
  test('Multipart retry preserves image bytes and rowversion', () async {
    int calls = 0;
    final bodies = <String>[];
    late ApiClient api;
    api = ApiClient(
      'http://example.test',
      client: MockClient((request) async {
        calls++;
        bodies.add(String.fromCharCodes(request.bodyBytes));
        expect(
          request.headers['content-type'],
          contains('multipart/form-data'),
        );
        expect(
          request.headers['authorization'],
          calls == 1 ? 'Bearer old' : 'Bearer fresh',
        );
        return calls == 1
            ? http.Response('', 401)
            : http.Response('{"id":1}', 201);
      }),
    );
    api.token = 'old';
    api.refreshSession = () async {
      api.token = 'fresh';
      return true;
    };
    await api.upload(
      'POST',
      '/admin/product',
      {'rowVersion': 'a+/='},
      image: [137, 80, 78, 71, 1, 2, 3],
      filename: 'photo.png',
    );
    expect(calls, 2);
    for (final body in bodies) {
      expect(body, contains('photo.png'));
      expect(body, contains('a+/='));
      expect(body, contains(String.fromCharCodes([137, 80, 78, 71, 1, 2, 3])));
    }
  });
  test('Upload conflict is shown without automatic overwrite', () async {
    int calls = 0;
    final api = ApiClient(
      'http://example.test',
      client: MockClient((_) async {
        calls++;
        return http.Response(
          '{"title":"Reload required","code":"DATA_CHANGED"}',
          409,
        );
      }),
    );
    await expectLater(
      api.upload('PUT', '/admin/category/1', {'name': 'New'}),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'DATA_CHANGED'),
      ),
    );
    expect(calls, 1);
  });
  testWidgets('Admin can add category without optional image', (tester) async {
    bool saved = false;
    final api = ApiClient(
      'http://example.test',
      client: MockClient((request) async {
        if (request.method == 'POST') {
          saved = true;
          expect(request.body, contains('New category'));
          return http.Response(
            jsonEncode({...cat, 'name': 'New category'}),
            201,
          );
        }
        if (request.url.path == '/api/category') {
          return http.Response('[]', 200);
        }
        return http.Response(
          jsonEncode({
            'items': saved
                ? [
                    {...cat, 'name': 'New category'},
                  ]
                : [],
            'totalPages': 1,
          }),
          200,
        );
      }),
    );
    final session = SessionHelper(api)
      ..ready = true
      ..member = Member.fromMap(admin);
    await tester.pumpWidget(MyApp(session: session));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Quản lý danh mục'));
    await tester.tap(find.text('Quản lý danh mục'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm mới'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Tên danh mục'), 'New category');
    await tester.ensureVisible(find.text('Lưu danh mục'));
    await tester.tap(find.text('Lưu danh mục'));
    await tester.pumpAndSettle();
    expect(saved, isTrue);
    expect(find.text('New category'), findsOneWidget);
  });
  testWidgets('New service requires image and hides court configuration', (
    tester,
  ) async {
    int writes = 0;
    final api = ApiClient(
      'http://example.test',
      client: MockClient((request) async {
        if (request.method != 'GET') {
          writes++;
          return http.Response('{}', 201);
        }
        if (request.url.path.endsWith('/venue')) {
          return http.Response(
            '[{"id":1,"name":"Demo venue","isActive":true}]',
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'items': [cat],
            'totalPages': 1,
          }),
          200,
        );
      }),
    );
    final session = SessionHelper(api)
      ..ready = true
      ..member = Member.fromMap(admin);
    await tester.pumpWidget(
      MaterialApp(home: ProductEditPage(session: session)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(field('Tên sân / dịch vụ'), 'Test service');
    final options = find.byType(DropdownButtonFormField<int>);
    await tester.ensureVisible(options.at(0));
    await tester.tap(options.at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pickleball').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(options.at(1));
    await tester.tap(options.at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Demo venue').last);
    await tester.pumpAndSettle();
    final type = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(type);
    await tester.tap(type);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dịch vụ / phụ kiện').last);
    await tester.pumpAndSettle();
    expect(field('Sức chứa tối đa'), findsNothing);
    await tester.ensureVisible(find.text('Lưu sản phẩm'));
    await tester.tap(find.text('Lưu sản phẩm'));
    await tester.pumpAndSettle();
    expect(find.text('Sản phẩm mới bắt buộc có ảnh.'), findsOneWidget);
    expect(writes, 0);
  });
}
