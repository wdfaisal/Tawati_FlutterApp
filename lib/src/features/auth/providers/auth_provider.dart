import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/error_handler.dart';
import '../../../core/guest_mode.dart';
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

  /// True when the app is being browsed without an account (visitor mode).
  final bool isGuest;

  /// True whenever nobody is signed in — either because the visitor chose to
  /// browse as a guest or simply because there is no member session yet.
  /// The UI uses this so an unknown session never falls back to member screens.
  bool get isVisitor => isGuest || !isAuthenticated;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.isGuest = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    bool? isGuest,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isGuest: isGuest ?? this.isGuest,
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

  /// Enables visitor mode: no tokens, read-only content, protected routes
  /// redirected to the login screen.
  Future<void> continueAsGuest() async {
    await _apiClient.clearTokens();
    _apiClient.guestMode = true;
    guestModeNotifier.value = true;
    await GuestSession.enable();
    state = AuthState(isGuest: true);
  }

  /// Restores a previously chosen visitor session (used by the splash screen).
  Future<bool> restoreGuestSession() async {
    final active = await GuestSession.isActive();
    if (!active) return false;
    _apiClient.guestMode = true;
    guestModeNotifier.value = true;
    state = AuthState(isGuest: true);
    return true;
  }

  Future<void> _leaveGuestMode() async {
    _apiClient.guestMode = false;
    guestModeNotifier.value = false;
    await GuestSession.disable();
  }

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
    await _leaveGuestMode();
    state = state.copyWith(isLoading: true, clearError: true, isGuest: false);
    try {
      final result = await _authService.login(phone: phone, password: password);
      await _apiClient.setTokens(result['access_token'], result['refresh_token']);
      state = state.copyWith(
        user: result['user'],
        isAuthenticated: true,
        isGuest: false,
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

  Future<void> verifyOtpOnly({required String phone, required String otp}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.verifyOtpOnly(phone: phone, otp: otp);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _friendlyError(e),
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> setPassword({
    required String phone,
    required String otp,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authService.setPassword(
        phone: phone,
        otp: otp,
        password: password,
      );
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _friendlyError(e),
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> setPinAndLogin({
    required String phone,
    required String otp,
    required String pin,
  }) async {
    await _leaveGuestMode();
    state = state.copyWith(isLoading: true, clearError: true, isGuest: false);
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
        isGuest: false,
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
    await _leaveGuestMode();
    state = state.copyWith(isLoading: true, clearError: true, isGuest: false);
    try {
      final result = await _authService.verifyOtp(phone: phone, otp: otp);
      await _apiClient.setTokens(result['access_token'], result['refresh_token']);
      state = state.copyWith(
        user: result['user'],
        isAuthenticated: true,
        isGuest: false,
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
        error: _friendlyError(e),
      );
    }
  }

  Future<bool> submitDocumentation({
    String? nationalId,
    String? dateOfBirth,
    String? maritalStatus,
    String? spouseName,
    List<Map<String, dynamic>> children = const [],
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.submitDocumentation(
        nationalId: nationalId,
        dateOfBirth: dateOfBirth,
        maritalStatus: maritalStatus,
        spouseName: spouseName,
        children: children,
      );
      final current = state.user;
      if (current != null) {
        state = state.copyWith(
          user: User(
            id: current.id,
            phone: current.phone,
            fullNameAr: current.fullNameAr,
            fullNameEn: current.fullNameEn,
            email: current.email,
            role: current.role,
            familyId: current.familyId,
            familyHeadId: current.familyHeadId,
            avatar: current.avatar,
            status: current.status,
            memberNumber: current.memberNumber,
            nationalId: nationalId ?? current.nationalId,
            dateOfBirth: current.dateOfBirth,
            gender: current.gender,
            maritalStatus: maritalStatus ?? current.maritalStatus,
            membershipLevel: current.membershipLevel,
            documentationCompleted: true,
            joinedAt: current.joinedAt,
            createdAt: current.createdAt,
          ),
        );
      }
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _friendlyError(e),
      );
      return false;
    }
  }

  Future<bool> loginWithBiometric() async {
    await _leaveGuestMode();
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
    if (state.isGuest) {
      await _leaveGuestMode();
      state = AuthState();
      return;
    }
    try {
      final refreshToken = await _apiClient.getRefreshToken();
      await _authService.logout(refreshToken: refreshToken);
    } catch (_) {
      // Ignore network/server failures: the local session must still end.
    }
    final bio = _ref.read(biometricServiceProvider);
    final biometricEnabled = await bio.isEnabled();
    if (!biometricEnabled) {
      await _apiClient.clearTokens();
    }
    await _leaveGuestMode();
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
