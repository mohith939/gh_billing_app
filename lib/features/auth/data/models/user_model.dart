import 'package:hive/hive.dart';
import '../../domain/entities/user.dart';

part 'user_model.g.dart';

@HiveType(typeId: 2)
class UserModel extends AppUser {
  @override
  @HiveField(0)
  final String email;
  @override
  @HiveField(1)
  final String password;
  @override
  @HiveField(2)
  final String shopName;
  @override
  @HiveField(3)
  final DateTime? expiryDate;
  @override
  @HiveField(4)
  final bool isSuperAdmin;
  @override
  @HiveField(5)
  final String phoneNumber;
  @override
  @HiveField(6)
  final String upiId;
  @override
  @HiveField(7)
  final String addressLine1;
  @override
  @HiveField(8)
  final String addressLine2;

  const UserModel({
    required this.email,
    required this.password,
    required this.shopName,
    this.phoneNumber = '',
    this.upiId = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.expiryDate,
    this.isSuperAdmin = false,
  }) : super(
          email: email,
          password: password,
          shopName: shopName,
          phoneNumber: phoneNumber,
          upiId: upiId,
          addressLine1: addressLine1,
          addressLine2: addressLine2,
          expiryDate: expiryDate,
          isSuperAdmin: isSuperAdmin,
        );

  factory UserModel.fromEntity(AppUser user) {
    return UserModel(
      email: user.email,
      password: user.password,
      shopName: user.shopName,
      phoneNumber: user.phoneNumber,
      upiId: user.upiId,
      addressLine1: user.addressLine1,
      addressLine2: user.addressLine2,
      expiryDate: user.expiryDate,
      isSuperAdmin: user.isSuperAdmin,
    );
  }

  AppUser toEntity() => this;

  UserModel copyWith({
    String? email,
    String? password,
    String? shopName,
    String? phoneNumber,
    String? upiId,
    String? addressLine1,
    String? addressLine2,
    DateTime? expiryDate,
    bool? isSuperAdmin,
  }) {
    return UserModel(
      email: email ?? this.email,
      password: password ?? this.password,
      shopName: shopName ?? this.shopName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      upiId: upiId ?? this.upiId,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      expiryDate: expiryDate ?? this.expiryDate,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
    );
  }
}
