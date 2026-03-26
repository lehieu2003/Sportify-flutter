import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sportify/features/auth/data/models/auth_user.dart';
import 'package:sportify/features/auth/data/models/user_device_session.dart';
import 'package:sportify/features/auth/data/repositories/auth_repository.dart';
import 'package:sportify/features/auth/data/services/auth_api_service.dart';
import 'package:sportify/features/auth/presentation/viewmodels/auth_view_model.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({required super.prefs})
      : super(
          service: AuthApiService(client: http.Client()),
        );

  bool loadSessionsCalled = false;
  String? revokedSessionId;

  @override
  Future<List<UserDeviceSession>> listSessions() async {
    loadSessionsCalled = true;
    return const <UserDeviceSession>[
      UserDeviceSession(
        id: '11111111-1111-1111-1111-111111111111',
        userAgent: 'Pixel',
        ip: '127.0.0.1',
        createdAt: null,
        expiresAt: null,
        isCurrent: true,
      ),
      UserDeviceSession(
        id: '22222222-2222-2222-2222-222222222222',
        userAgent: 'Web',
        ip: '127.0.0.2',
        createdAt: null,
        expiresAt: null,
        isCurrent: false,
      ),
    ];
  }

  @override
  Future<void> revokeSession(String sessionId) async {
    revokedSessionId = sessionId;
  }

  @override
  Future<void> signoutAllRemote() async {}

  @override
  Future<void> signoutRemote() async {}

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
  test('AuthViewModel loads sessions and updates state', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final repository = _FakeAuthRepository(prefs: prefs);
    final vm = AuthViewModel(repository: repository);

    await vm.loadDeviceSessions();

    expect(repository.loadSessionsCalled, isTrue);
    expect(vm.state.deviceSessions.length, 2);
  });

  test('AuthViewModel revokes one session and removes it from state', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final repository = _FakeAuthRepository(prefs: prefs);
    final vm = AuthViewModel(repository: repository);
    await vm.loadDeviceSessions();

    await vm.revokeDeviceSession('22222222-2222-2222-2222-222222222222');

    expect(repository.revokedSessionId, '22222222-2222-2222-2222-222222222222');
    expect(vm.state.deviceSessions.length, 1);
    expect(vm.state.deviceSessions.first.id, '11111111-1111-1111-1111-111111111111');
  });
}
