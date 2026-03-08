import 'package:hive_flutter/hive_flutter.dart';
import '../../features/product/data/models/product_model.dart';
import '../../features/shop/data/models/shop_model.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/billing/data/models/invoice_model.dart';

class HiveDatabase {
  static const String productBoxName = 'products';
  static const String shopBoxName = 'shop';
  static const String settingsBoxName = 'settings';
  static const String userBoxName = 'users';
  static const String invoiceBoxName = 'invoices';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ProductModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ShopModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(UserModelAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(InvoiceModelAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(CartItemModelAdapter());

    // Open Boxes
    await Hive.openBox<ProductModel>(productBoxName);
    await Hive.openBox<ShopModel>(shopBoxName);
    await Hive.openBox(settingsBoxName); 
    await Hive.openBox<UserModel>(userBoxName);
    await Hive.openBox<InvoiceModel>(invoiceBoxName);
    
    // Seed Superadmin if not exists
    final userBox = Hive.box<UserModel>(userBoxName);
    if (userBox.isEmpty) {
      await userBox.put('finstics@gmail.com', const UserModel(
        email: 'finstics@gmail.com',
        password: 'Mohith@123',
        shopName: 'Super Admin',
        isSuperAdmin: true,
      ));
      
      // Also seed the initial customers mentioned in the old LoginPage
      await userBox.put('ghtadepalli@gmail.com', UserModel(
        email: 'ghtadepalli@gmail.com',
        password: 'Finstics@123',
        shopName: 'Golden Harvest',
        phoneNumber: '9876543210',
        upiId: 'ght@upi',
        addressLine1: 'Tadepalli, Guntur',
        addressLine2: 'Andhra Pradesh',
        expiryDate: DateTime.now().add(const Duration(days: 30)),
      ));
    }
  }

  static Box<ProductModel> get productBox =>
      Hive.box<ProductModel>(productBoxName);
  static Box<ShopModel> get shopBox => Hive.box<ShopModel>(shopBoxName);
  static Box get settingsBox => Hive.box(settingsBoxName);
  static Box<UserModel> get userBox => Hive.box<UserModel>(userBoxName);
  static Box<InvoiceModel> get invoiceBox => Hive.box<InvoiceModel>(invoiceBoxName);
}
