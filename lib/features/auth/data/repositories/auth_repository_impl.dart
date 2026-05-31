import '../../../../core/errors/exceptions.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../shared/models/user_model.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _datasource;

  AuthRepositoryImpl(this._datasource);

  @override
  Future<({String token, UserModel user})> login({
    required String email,
    required String password,
  }) async {
    final data = await _datasource.login(email: email, password: password);

    // Extract token — handle both "token" and "access_token" keys
    final token = data['token'] as String? ?? data['access_token'] as String?;
    if (token == null) throw ServerException('Token tidak ditemukan dalam response');

    // Extract user — handle both "user" key and direct user data
    final userMap = data['user'] as Map<String, dynamic>? ?? data;
    final user = UserModel.fromJson(userMap);

    // Persist token
    await TokenStorage.saveToken(token);

    return (token: token, user: user);
  }

  @override
  Future<({String token, UserModel user})> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    final data = await _datasource.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );

    final token = data['token'] as String? ?? data['access_token'] as String?;
    if (token == null) throw ServerException('Token tidak ditemukan dalam response');

    final userMap = data['user'] as Map<String, dynamic>? ?? data;
    final user = UserModel.fromJson(userMap);

    await TokenStorage.saveToken(token);

    return (token: token, user: user);
  }

  @override
  Future<void> logout() async {
    await _datasource.logout();
    await TokenStorage.deleteToken();
  }

  @override
  Future<UserModel> getCurrentUser() async {
    return _datasource.getCurrentUser();
  }
}
