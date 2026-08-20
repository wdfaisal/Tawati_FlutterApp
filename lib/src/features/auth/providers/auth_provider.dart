import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/error_handler.dart';
import '../../../core/providers.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

String _friendlyError(dynamic e) {
  return friendlyError(e);
}

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class PhoneCheckResult {
  final String status;
  PhoneCheckResult({required this.status});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(AuthState());

  AuthService get _authService => _ref.read(authServiceProvider);
  ApiClient get _apiClient => _ref.read(apiClientProvider);

  Future<PhoneCheckResult> checkPhone({required String phone}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authService.checkPhone(phone: phone);
      state = state.copyWith(isLoading: false);
      return PhoneCheckResult(status: result['status']);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _friendlyError(e),
      );
      rethrow;
    }
  }

  Future<void> login({
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authService.login(phone: phone, password: password);
      await _apiClient.setTokens(result['access_token'], result['refresh_token']);
      state = state.copyWith(
        user: result['user'],
        isAuthenticated: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _friendlyError(e),
      );
    }
  }

  Future<void> sendOtp({required String phone}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.sendOtp(phone: phone);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _friendlyError(e),
      );
    }
  }

  Future<Map<String, dynamic>> setPinAndLogin({
    required String phone,
    required String otp,
    required String pin,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authService.setPassword(
        phone: phone,
        otp: otp,
        password: pin,
      );
      final loginResult = await _authService.login(
        phone: phone,
        password: pin,
      );
      await _apiClient.setTokens(
        loginResult['access_token'],
        loginResult['refresh_token'],
      );
      state = state.copyWith(
        user: loginResult['user'],
        isAuthenticated: true,
        isLoading: false,
      );
      return {
        'needs_family_setup': result['needs_family_setup'],
        'user_id': result['user_id'],
      };
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _friendlyError(e),
      );
      rethrow;
    }
  }

  Future<void> setupFamily({
    required String userId,
    required String spouseName,
    List<Map<String, dynamic>> children = const [],
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.setupFamily(
        userId: userId,
        spouseName: spouseName,
        children: children,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _friendlyError(e),
      );
      rethrow;
    }
  }

  Future<void> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authService.verifyOtp(phone: phone, otp: otp);
      await _apiClient.setTokens(result['access_token'], result['refresh_token']);
      state = state.copyWith(
        user: result['user'],
        isAuthenticated: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _friendlyError(e),
      );
    }
  }

  Future<void> loadUser() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.getMe();
      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: _friendlyError(e),
      );
    }
  }

  Future<bool> loginWithBiometric() async {
    try {
      final user = await _authService.getMe();
      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _friendlyError(e),
      );
      return false;
    }
  }

  Future<void> logout() async {
    final refreshToken = await _apiClient.getRefreshToken();
    await _authService.logout(refreshToken: refreshToken);
    final bio = _ref.read(biometricServiceProvider);
    final biometricEnabled = await bio.isEnabled();
    if (!biometricEnabled) {
      await _apiClient.clearTokens();
    }
    state = AuthState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
