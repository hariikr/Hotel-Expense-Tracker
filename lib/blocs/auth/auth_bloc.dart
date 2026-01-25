import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({required AuthService authService})
      : _authService = authService,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignInRequested>(_onAuthSignInRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
    on<AuthPasswordResetRequested>(_onAuthPasswordResetRequested);
    on<AuthResendConfirmationRequested>(_onAuthResendConfirmationRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onAuthSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _authService.signIn(
      email: event.email,
      password: event.password,
    );

    if (result.success) {
      if (result.user != null) {
        emit(Authenticated(result.user!));
      } else if (result.requiresConfirmation) {
        emit(AuthAwaitingConfirmation(
          result.message ?? 'Please confirm your email.',
          event.email,
        ));
      }
    } else {
      emit(AuthError(result.error ?? 'Authentication failed'));
      emit(Unauthenticated());
    }
  }

  Future<void> _onAuthSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _authService.signUp(
      email: event.email,
      password: event.password,
      fullName: event.fullName,
      businessName: event.businessName,
    );

    if (result.success) {
      if (result.session != null && result.user != null) {
        // Auto-login successful (Email confirmation is likely disabled)
        emit(Authenticated(result.user!));
      } else if (result.requiresConfirmation || result.session == null) {
        // Email confirmation is required
        emit(AuthAwaitingConfirmation(
          result.message ?? 'Confirmation required. Please check your email.',
          event.email,
        ));
      } else if (result.user != null) {
        // Fallback: try to sign in automatically if user was created but session is missing
        // This is the "Auto-Login" attempt the user requested
        add(AuthSignInRequested(email: event.email, password: event.password));
      }
    } else {
      emit(AuthError(result.error ?? 'Sign up failed'));
      emit(Unauthenticated());
    }
  }

  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await _authService.signOut();
    emit(Unauthenticated());
  }

  Future<void> _onAuthPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _authService.resetPassword(event.email);
    if (result.success) {
      emit(AuthPasswordResetSent(result.message ?? 'Reset link sent'));
    } else {
      emit(AuthError(result.error ?? 'Failed to send reset link'));
    }
  }

  Future<void> _onAuthResendConfirmationRequested(
    AuthResendConfirmationRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _authService.resendConfirmationEmail(event.email);
    if (result.success) {
      emit(AuthAwaitingConfirmation(
        result.message ?? 'Confirmation email resent.',
        event.email,
      ));
    } else {
      emit(AuthError(result.error ?? 'Failed to resend confirmation email'));
    }
  }
}
