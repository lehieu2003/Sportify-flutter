import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sportify/features/auth/data/models/auth_user.dart';
import 'package:sportify/features/auth/data/models/user_device_session.dart';
import 'package:sportify/features/auth/data/repositories/auth_repository.dart';
import 'package:sportify/features/auth/data/services/auth_api_service.dart';
import 'package:sportify/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:sportify/features/auth/presentation/views/profile_screen.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({required super.prefs})
      : super(
          service: AuthApiService(client: http.Client()),
        );

  @override
  Future<List<UserDeviceSession>> listSessions() async {
    return const <UserDeviceSession>[
      UserDeviceSession(
        id: '11111111-1111-1111-1111-111111111111',
        userAgent: 'Current Device',
        ip: '127.0.0.1',
        createdAt: null,
        expiresAt: null,
        isCurrent: true,
      ),
      UserDeviceSession(
        id: '22222222-2222-2222-2222-222222222222',
        userAgent: 'Laptop',
        ip: '127.0.0.2',
        createdAt: null,
        expiresAt: null,
        isCurrent: false,
      ),
    ];
  }

  @override
  Future<AuthUser> updateProfile({String? fullName, String? imageUrl}) async {
    return AuthUser(
      id: 'user-1',
      fullName: fullName ?? 'User',
      email: 'user@test.com',
      imageUrl: imageUrl ?? '',
      role: 'user',
    );
  }
}

void main() {
  testWidgets('ProfileScreen shows logged devices and validates edit form', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final vm = AuthViewModel(repository: _FakeAuthRepository(prefs: prefs));

    await tester.pumpWidget(
      MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider<AuthViewModel>.value(value: vm),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ProfileScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Logged in devices'), findsOneWidget);
    expect(find.text('Current Device'), findsOneWidget);
    expect(find.text('Laptop'), findsOneWidget);

    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Full name is required'), findsOneWidget);
  });
}
