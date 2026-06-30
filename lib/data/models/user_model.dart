import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 4)
class UserModel extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? pronoun;

  @HiveField(2)
  String? firstName;

  @HiveField(3)
  String? fullName;

  @HiveField(4)
  int? age;

  @HiveField(5)
  String? email;

  @HiveField(6)
  String? profileImagePath;

  @HiveField(7)
  DateTime? dateOfBirth;

  @HiveField(8)
  String? address;

  @HiveField(9)
  String? instagramHandle;

  @HiveField(14)
  String? street;

  @HiveField(15)
  String? state;

  @HiveField(16)
  String? country;

  @HiveField(17)
  String? pinCode;

  @HiveField(10)
  DateTime? createdAt;

  @HiveField(11)
  bool isOnboardingComplete;

  @HiveField(12)
  DateTime? joinedAt;

  @HiveField(13)
  bool permissionsGranted;

  UserModel({
    this.id,
    this.pronoun,
    this.firstName,
    this.fullName,
    this.age,
    this.email,
    this.profileImagePath,
    this.dateOfBirth,
    this.address,
    this.instagramHandle,
    this.createdAt,
    this.isOnboardingComplete = false,
    this.joinedAt,
    this.permissionsGranted = false,
    this.street,
    this.state,
    this.country,
    this.pinCode,
  });

  String get greeting {
    if (firstName == null || firstName!.isEmpty) return 'Hello';
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  UserModel copyWith({
    String? id,
    String? pronoun,
    String? firstName,
    String? fullName,
    int? age,
    String? email,
    String? profileImagePath,
    DateTime? dateOfBirth,
    String? address,
    String? instagramHandle,
    DateTime? createdAt,
    bool? isOnboardingComplete,
    DateTime? joinedAt,
    bool? permissionsGranted,
    String? street,
    String? state,
    String? country,
    String? pinCode,
  }) {
    return UserModel(
      id: id ?? this.id,
      pronoun: pronoun ?? this.pronoun,
      firstName: firstName ?? this.firstName,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      email: email ?? this.email,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      instagramHandle: instagramHandle ?? this.instagramHandle,
      createdAt: createdAt ?? this.createdAt,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      joinedAt: joinedAt ?? this.joinedAt,
      permissionsGranted: permissionsGranted ?? this.permissionsGranted,
      street: street ?? this.street,
      state: state ?? this.state,
      country: country ?? this.country,
      pinCode: pinCode ?? this.pinCode,
    );
  }
}