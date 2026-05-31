import '../../../../shared/models/user_model.dart';

/// Abstract auth repository contract.
abstract class AuthRepository {
  /// Login and return the auth token.
  Future<({String token, UserModel user})> login({
    required String email,
    required String password,
  });

  /// Register a new customer account.
  Future<({String token, UserModel user})> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  });

  /// Logout and revoke token.
  Future<void> logout();

  /// Fetch current authenticated user.
  Future<UserModel> getCurrentUser();
}
