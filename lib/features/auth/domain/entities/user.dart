import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String email;
  final String password;
  final String shopName;
  final String phoneNumber;
  final String upiId;
  final String addressLine1;
  final String addressLine2;
  final String footerText;
  final String? qrCodePath;
  final DateTime? expiryDate;
  final bool isSuperAdmin;

  const AppUser({
    required this.email,
    required this.password,
    required this.shopName,
    this.phoneNumber = '',
    this.upiId = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.footerText = 'Thank you, Visit again!!!',
    this.qrCodePath,
    this.expiryDate,
    this.isSuperAdmin = false,
  });

  bool get isSubscriptionActive {
    if (isSuperAdmin) return true;
    if (expiryDate == null) return false;
    return expiryDate!.isAfter(DateTime.now());
  }

  bool get needsRenewalPrompt {
    if (isSuperAdmin || expiryDate == null) return false;
    final now = DateTime.now();
    final difference = expiryDate!.difference(now).inDays;
    return difference <= 5 && difference >= 0;
  }

  @override
  List<Object?> get props => [
        email,
        password,
        shopName,
        phoneNumber,
        upiId,
        addressLine1,
        addressLine2,
        footerText,
        qrCodePath,
        expiryDate,
        isSuperAdmin
      ];
}
