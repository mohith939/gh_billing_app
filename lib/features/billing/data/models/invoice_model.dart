import 'package:hive/hive.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/cart_item.dart';
import '../../../product/domain/entities/product.dart';

part 'invoice_model.g.dart';

@HiveType(typeId: 3)
class InvoiceModel extends Invoice {
  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String userEmail;
  @override
  @HiveField(2)
  final DateTime dateTime;
  @override
  @HiveField(3)
  final List<CartItemModel> itemModels;
  @override
  @HiveField(4)
  final double totalAmount;

  InvoiceModel({
    required this.id,
    required this.userEmail,
    required this.dateTime,
    required this.itemModels,
    required this.totalAmount,
  }) : super(
          id: id,
          userEmail: userEmail,
          dateTime: dateTime,
          items: itemModels,
          totalAmount: totalAmount,
        );

  factory InvoiceModel.fromEntity(Invoice invoice) {
    return InvoiceModel(
      id: invoice.id,
      userEmail: invoice.userEmail,
      dateTime: invoice.dateTime,
      itemModels: invoice.items.map((e) => CartItemModel.fromEntity(e)).toList(),
      totalAmount: invoice.totalAmount,
    );
  }
}

@HiveType(typeId: 4)
class CartItemModel extends CartItem {
  @HiveField(0)
  final String productId;
  @HiveField(1)
  final String productName;
  @HiveField(2)
  final double productPrice;
  @override
  @HiveField(3)
  final int quantity;

  CartItemModel({
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.quantity,
  }) : super(
          product: Product(id: productId, name: productName, barcode: '', price: productPrice),
          quantity: quantity,
        );

  factory CartItemModel.fromEntity(CartItem item) {
    return CartItemModel(
      productId: item.product.id,
      productName: item.product.name,
      productPrice: item.product.price,
      quantity: item.quantity,
    );
  }
}
