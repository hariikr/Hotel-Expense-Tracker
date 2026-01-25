import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String? fullName;
  final String? businessName;

  const AuthSignUpRequested({
    required this.email,
    required this.password,
    this.fullName,
    this.businessName,
  });

  @override
  List<Object?> get props => [email, password, fullName, businessName];
}

class AuthSignOutRequested extends AuthEvent {}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthResendConfirmationRequested extends AuthEvent {
  final String email;

  const AuthResendConfirmationRequested({required this.email});

  @override
  List<Object?> get props => [email];
}
