import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/services/database_service.dart';
import '../../data/services/notification_service.dart';
final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<UserModel?> {
  final DatabaseService _db = DatabaseService();

  UserNotifier() : super(null);

  Future<void> loadUser() async {
    try {
      final box = _db.userBox;
      if (box.isNotEmpty) {
        state = box.getAt(0);
      }
    } catch (e) {
      state = null;
    }
  }

  Future<void> saveUser({
    String? pronoun,
    String? firstName,
    String? fullName,
    int? age,
    String? email,
    String? profileImagePath,
    DateTime? dateOfBirth,
    String? address,
    String? instagramHandle,
    bool? isOnboardingComplete,
    DateTime? joinedAt,
    String? street,
    String? stateField,
    String? country,
    String? pinCode,
  }) async {
    try {
      final box = _db.userBox;
      final currentUser = state;
      
      final user = UserModel(
        id: currentUser?.id ?? _db.generateId(),
        pronoun: pronoun ?? currentUser?.pronoun,
        firstName: firstName ?? currentUser?.firstName,
        fullName: fullName ?? currentUser?.fullName,
        age: age ?? currentUser?.age,
        email: email ?? currentUser?.email,
        profileImagePath: profileImagePath ?? currentUser?.profileImagePath,
        dateOfBirth: dateOfBirth ?? currentUser?.dateOfBirth,
        address: address ?? currentUser?.address,
        instagramHandle: instagramHandle ?? currentUser?.instagramHandle,
        createdAt: currentUser?.createdAt ?? DateTime.now(),
        isOnboardingComplete: isOnboardingComplete ?? currentUser?.isOnboardingComplete ?? false,
        joinedAt: joinedAt ?? currentUser?.joinedAt,
        street: street ?? currentUser?.street,
        state: stateField ?? currentUser?.state,
        country: country ?? currentUser?.country,
        pinCode: pinCode ?? currentUser?.pinCode,
      );

      if (box.isEmpty) {
        await box.add(user);
      } else {
        await box.putAt(0, user);
      }
      
      state = user;

      if (user.dateOfBirth != null && user.firstName != null) {
        await NotificationService().scheduleBirthdayNotifications(user.dateOfBirth!, user.firstName!);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? pronoun,
    String? firstName,
    String? fullName,
    int? age,
    String? email,
    String? profileImagePath,
    DateTime? dateOfBirth,
    String? address,
    String? instagramHandle,
    String? street,
    String? stateField,
    String? country,
    String? pinCode,
  }) async {
    await saveUser(
      pronoun: pronoun,
      firstName: firstName,
      fullName: fullName,
      age: age,
      email: email,
      profileImagePath: profileImagePath,
      dateOfBirth: dateOfBirth,
      address: address,
      instagramHandle: instagramHandle,
      street: street,
      stateField: stateField,
      country: country,
      pinCode: pinCode,
    );
  }

  Future<void> setPermissionsGranted(bool granted) async {
    final currentUser = state;
    if (currentUser != null) {
      final updated = currentUser.copyWith(
        isOnboardingComplete: true,
        permissionsGranted: granted,
      );
      await _saveUser(updated);
    } else {
      // Create a minimal user if none exists
      await saveUser(isOnboardingComplete: true);
    }
  }

  Future<void> _saveUser(UserModel user) async {
    final box = _db.userBox;
    if (box.isEmpty) {
      await box.add(user);
    } else {
      await box.putAt(0, user);
    }
    state = user;
  }

  String get greeting {
    if (state?.firstName == null || state!.firstName!.isEmpty) return 'Hello';
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String? get firstName => state?.firstName;

  bool get hasProfileImage =>
      state?.profileImagePath != null && state!.profileImagePath!.isNotEmpty;

  String get profileImagePath => state?.profileImagePath ?? '';
}