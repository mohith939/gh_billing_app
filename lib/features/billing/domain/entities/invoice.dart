import 'package:equatable/equatable.dart';
import 'cart_item.dart';

class Invoice extends Equatable {
  final String id;
  final String userEmail;
  final DateTime dateTime;
  final List<CartItem> items;
  final double totalAmount;

  const Invoice({
    required this.id,
    required this.userEmail,
    required this.dateTime,
    required this.items,
    required this.totalAmount,
  });

  @override
  List<Object?> get props => [id, userEmail, dateTime, items, totalAmount];
}
