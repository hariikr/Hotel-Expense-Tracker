import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_logger.dart';

/// User profile model
class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final String preferredLanguage;
  final String? businessName;
  final String businessType;
  final String timezone;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.preferredLanguage = 'ml',
    this.businessName,
    this.businessType = 'hotel',
    this.timezone = 'Asia/Kolkata',
    this.settings = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      preferredLanguage: json['preferred_language'] as String? ?? 'ml',
      businessName: json['business_name'] as String?,
      businessType: json['business_type'] as String? ?? 'hotel',
      timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
      settings: json['settings'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'preferred_language': preferredLanguage,
      'business_name': businessName,
      'business_type': businessType,
      'timezone': timezone,
      'settings': settings,
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? preferredLanguage,
    String? businessName,
    String? businessType,
    String? timezone,
    Map<String, dynamic>? settings,
  }) {
    return UserProfile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      timezone: timezone ?? this.timezone,
      settings: settings ?? this.settings,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Authentication service for managing user sessions
class AuthService {
  final SupabaseClient _supabase;

  AuthService([SupabaseClient? client])
      : _supabase = client ?? Supabase.instance.client;

  /// Get the current Supabase client
  SupabaseClient get client => _supabase;

  /// Get the current authenticated user
  User? get currentUser => _supabase.auth.currentUser;

  /// Get the current user's ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Check if user is authenticated
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sign up with email and password
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? fullName,
    String? businessName,
  }) async {
    AppLogger.functionEntry('signUp', params: {'email': email});
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'business_name': businessName,
        },
      );

      if (response.user == null) {
        AppLogger.functionExit('signUp', result: 'No user returned');
        return AuthResult.error(
            'സൈൻ അപ്പ് പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.');
      }

      // Check if email confirmation is required
      if (response.session == null) {
        AppLogger.functionExit('signUp', result: 'Email confirmation required');
        return AuthResult.success(
          user: response.user!,
          message:
              'നിങ്ങളുടെ ഇമെയിൽ സ്ഥിരീകരിക്കുക. ഒരു ലിങ്ക് അയച്ചിട്ടുണ്ട്.',
          requiresConfirmation: true,
        );
      }

      AppLogger.functionExit('signUp', result: 'Success');
      return AuthResult.success(
        user: response.user!,
        session: response.session,
        message: 'സ്വാഗതം! അക്കൗണ്ട് സൃഷ്ടിച്ചു.',
      );
    } on AuthException catch (e) {
      AppLogger.e('SignUp error: ${e.message}');
      return AuthResult.error(_getAuthErrorMessage(e.message));
    } catch (e) {
      AppLogger.e('SignUp error: $e');
      return AuthResult.error('ഒരു പിശക് സംഭവിച്ചു: $e');
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    AppLogger.functionEntry('signIn', params: {'email': email});
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        AppLogger.functionExit('signIn', result: 'No user returned');
        return AuthResult.error(
            'ലോഗിൻ പരാജയപ്പെട്ടു. ഇമെയിലും പാസ്‌വേഡും പരിശോധിക്കുക.');
      }

      AppLogger.functionExit('signIn', result: 'Success');
      return AuthResult.success(
        user: response.user!,
        session: response.session,
        message: 'സ്വാഗതം!',
      );
    } on AuthException catch (e) {
      AppLogger.e('SignIn error: ${e.message}');

      // Specifically handle unconfirmed email
      if (e.message.toLowerCase().contains('email not confirmed')) {
        return AuthResult.success(
          message: _getAuthErrorMessage(e.message),
          requiresConfirmation: true,
        );
      }

      return AuthResult.error(_getAuthErrorMessage(e.message));
    } catch (e) {
      AppLogger.e('SignIn error: $e');
      return AuthResult.error('ഒരു പിശക് സംഭവിച്ചു: $e');
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    AppLogger.functionEntry('signOut');
    try {
      await _supabase.auth.signOut();
      AppLogger.functionExit('signOut', result: 'Success');
    } catch (e) {
      AppLogger.e('SignOut error: $e');
      rethrow;
    }
  }

  /// Send password reset email
  Future<AuthResult> resetPassword(String email) async {
    AppLogger.functionEntry('resetPassword', params: {'email': email});
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      AppLogger.functionExit('resetPassword', result: 'Success');
      return AuthResult.success(
        message: 'പാസ്‌വേഡ് റീസെറ്റ് ലിങ്ക് ഇമെയിലിലേക്ക് അയച്ചു.',
      );
    } on AuthException catch (e) {
      AppLogger.e('ResetPassword error: ${e.message}');
      return AuthResult.error(_getAuthErrorMessage(e.message));
    } catch (e) {
      AppLogger.e('ResetPassword error: $e');
      return AuthResult.error('ഒരു പിശക് സംഭവിച്ചു: $e');
    }
  }

  /// Resend confirmation email
  Future<AuthResult> resendConfirmationEmail(String email) async {
    AppLogger.functionEntry('resendConfirmationEmail',
        params: {'email': email});
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      AppLogger.functionExit('resendConfirmationEmail', result: 'Success');
      return AuthResult.success(
        message: 'സ്ഥിരീകരണ ഇമെയിൽ വീണ്ടും അയച്ചു.',
      );
    } on AuthException catch (e) {
      AppLogger.e('Resend error: ${e.message}');
      return AuthResult.error(_getAuthErrorMessage(e.message));
    } catch (e) {
      AppLogger.e('Resend error: $e');
      return AuthResult.error('ഒരു പിശക് സംഭവിച്ചു: $e');
    }
  }

  /// Get user profile from database
  Future<UserProfile?> getUserProfile() async {
    AppLogger.functionEntry('getUserProfile');
    try {
      final userId = currentUserId;
      if (userId == null) {
        AppLogger.functionExit('getUserProfile', result: 'No user');
        return null;
      }

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        AppLogger.functionExit('getUserProfile', result: 'No profile');
        return null;
      }

      final profile = UserProfile.fromJson(response);
      AppLogger.functionExit('getUserProfile', result: 'Found profile');
      return profile;
    } catch (e) {
      AppLogger.e('getUserProfile error: $e');
      return null;
    }
  }

  /// Update user profile
  Future<UserProfile?> updateProfile({
    String? fullName,
    String? phone,
    String? businessName,
    String? preferredLanguage,
  }) async {
    AppLogger.functionEntry('updateProfile');
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('Not authenticated');
      }

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (businessName != null) updates['business_name'] = businessName;
      if (preferredLanguage != null)
        updates['preferred_language'] = preferredLanguage;

      await _supabase.from('profiles').update(updates).eq('id', userId);

      AppLogger.functionExit('updateProfile', result: 'Success');
      return await getUserProfile();
    } catch (e) {
      AppLogger.e('updateProfile error: $e');
      return null;
    }
  }

  /// Get localized auth error message
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode.toLowerCase()) {
      case 'invalid login credentials':
      case 'invalid_credentials':
        return 'തെറ്റായ ഇമെയിൽ അല്ലെങ്കിൽ പാസ്‌വേഡ്.';
      case 'email not confirmed':
        return 'ഇമെയിൽ സ്ഥിരീകരിച്ചിട്ടില്ല. നിങ്ങളുടെ ഇൻബോക്‌സ് പരിശോധിക്കുക.';
      case 'user already registered':
        return 'ഈ ഇമെയിൽ ഇതിനകം രജിസ്റ്റർ ചെയ്തിട്ടുണ്ട്.';
      case 'weak password':
        return 'പാസ്‌വേഡ് വളരെ ദുർബലമാണ്. കുറഞ്ഞത് 6 അക്ഷരങ്ങൾ ഉപയോഗിക്കുക.';
      case 'email rate limit exceeded':
        return 'വളരെയധികം ശ്രമങ്ങൾ. കുറച്ച് സമയത്തിന് ശേഷം വീണ്ടും ശ്രമിക്കുക.';
      default:
        return 'ഒരു പിശക് സംഭവിച്ചു: $errorCode';
    }
  }
}

/// Result of an authentication operation
class AuthResult {
  final bool success;
  final User? user;
  final Session? session;
  final String? message;
  final String? error;
  final bool requiresConfirmation;

  AuthResult._({
    required this.success,
    this.user,
    this.session,
    this.message,
    this.error,
    this.requiresConfirmation = false,
  });

  factory AuthResult.success({
    User? user,
    Session? session,
    String? message,
    bool requiresConfirmation = false,
  }) {
    return AuthResult._(
      success: true,
      user: user,
      session: session,
      message: message,
      requiresConfirmation: requiresConfirmation,
    );
  }

  factory AuthResult.error(String error) {
    return AuthResult._(
      success: false,
      error: error,
    );
  }
}
