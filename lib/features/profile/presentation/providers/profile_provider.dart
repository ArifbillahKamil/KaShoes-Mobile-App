import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/models/user_model.dart';
import '../../data/datasources/profile_remote_datasource.dart';

// ─── State ─────────────────────────────────────────────────────────────────────

enum ProfileStatus { initial, loading, loaded, saving, error }

class ProfileState {
  final ProfileStatus status;
  final UserModel? user;
  final String? errorMessage;
  final bool saveSuccess;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.user,
    this.errorMessage,
    this.saveSuccess = false,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    UserModel? user,
    String? errorMessage,
    bool? saveSuccess,
  }) {
    return ProfileState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      saveSuccess: saveSuccess ?? this.saveSuccess,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRemoteDatasource _datasource;

  ProfileNotifier(this._datasource) : super(const ProfileState());

  Future<void> load() async {
    state = state.copyWith(status: ProfileStatus.loading, errorMessage: null);
    try {
      final user = await _datasource.getProfile();
      state = state.copyWith(status: ProfileStatus.loaded, user: user);
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'Gagal memuat profil',
      );
    }
  }

  Future<void> updateProfile({String? phone, String? address}) async {
    state = state.copyWith(status: ProfileStatus.saving, errorMessage: null, saveSuccess: false);
    try {
      final updatedUser = await _datasource.updateProfile(phone: phone, address: address);
      state = state.copyWith(
        status: ProfileStatus.loaded,
        user: updatedUser,
        saveSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.loaded,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        saveSuccess: false,
      );
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final profileDatasourceProvider = Provider<ProfileRemoteDatasource>((ref) {
  return ProfileRemoteDatasource(createDioClient());
});

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref.watch(profileDatasourceProvider));
});
