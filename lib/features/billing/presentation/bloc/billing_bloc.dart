import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/invoice.dart';
import '../../data/models/invoice_model.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/product/domain/usecases/product_usecases.dart';
import '../../../../core/utils/printer_helper.dart';
import '../../../../core/data/hive_database.dart';

part 'billing_event.dart';
part 'billing_state.dart';

class BillingBloc extends Bloc<BillingEvent, BillingState> {
  final GetProductByBarcodeUseCase getProductByBarcodeUseCase;

  // Google Script URL for Sheets integration
  static const String _googleScriptUrl = 'https://script.google.com/macros/s/AKfycbzImifSLB2GM15LePU8EM5hEf0Ws8H5BCOgWyc0iwtjNJNxVYt2V8CytHjbcGGLcqgq-Q/exec';

  BillingBloc({required this.getProductByBarcodeUseCase})
      : super(const BillingState()) {
    on<ScanBarcodeEvent>(_onScanBarcode);
    on<AddProductToCartEvent>(_onAddProductToCart);
    on<RemoveProductFromCartEvent>(_onRemoveProductFromCart);
    on<UpdateQuantityEvent>(_onUpdateQuantity);
    on<ClearCartEvent>(_onClearCart);
    on<PrintReceiptEvent>(_onPrintReceipt);
    on<PlaceOrderEvent>(_onPlaceOrder);
    on<SyncToGoogleSheetsEvent>(_onSyncToGoogleSheets);
  }

  Future<void> _onScanBarcode(
      ScanBarcodeEvent event, Emitter<BillingState> emit) async {
    final result = await getProductByBarcodeUseCase(event.barcode);
    result.fold(
      (failure) =>
          emit(state.copyWith(error: 'Product not found: ${event.barcode}')),
      (product) {
        add(AddProductToCartEvent(product));
      },
    );
  }

  void _onAddProductToCart(
      AddProductToCartEvent event, Emitter<BillingState> emit) {
    final cleanState = state.copyWith(error: null);

    final existingIndex = cleanState.cartItems
        .indexWhere((item) => item.product.id == event.product.id);
    if (existingIndex >= 0) {
      final existingItem = cleanState.cartItems[existingIndex];
      final backendItems = List<CartItem>.from(cleanState.cartItems);
      backendItems[existingIndex] =
          existingItem.copyWith(quantity: existingItem.quantity + 1);
      emit(cleanState.copyWith(cartItems: backendItems, error: null));
    } else {
      final newItem = CartItem(product: event.product);
      emit(cleanState.copyWith(
          cartItems: [...cleanState.cartItems, newItem], error: null));
    }
  }

  void _onRemoveProductFromCart(
      RemoveProductFromCartEvent event, Emitter<BillingState> emit) {
    final updatedList = state.cartItems
        .where((item) => item.product.id != event.productId)
        .toList();
    emit(state.copyWith(cartItems: updatedList));
  }

  void _onUpdateQuantity(
      UpdateQuantityEvent event, Emitter<BillingState> emit) {
    if (event.quantity <= 0) {
      add(RemoveProductFromCartEvent(event.productId));
      return;
    }

    final index = state.cartItems
        .indexWhere((item) => item.product.id == event.productId);
    if (index >= 0) {
      final items = List<CartItem>.from(state.cartItems);
      items[index] = items[index].copyWith(quantity: event.quantity);
      emit(state.copyWith(cartItems: items));
    }
  }

  void _onClearCart(ClearCartEvent event, Emitter<BillingState> emit) {
    emit(const BillingState());
  }

  Future<void> _onPrintReceipt(
      PrintReceiptEvent event, Emitter<BillingState> emit) async {
    final printerHelper = PrinterHelper();

    if (!printerHelper.isConnected) {
      final savedMac = HiveDatabase.settingsBox.get('printer_mac');
      if (savedMac != null) {
        final connected = await printerHelper.connect(savedMac);
        if (!connected) {
          emit(state.copyWith(
              error: 'Failed to auto-connect to printer!', clearError: false));
          emit(state.copyWith(clearError: true));
          return;
        }
      } else {
        emit(state.copyWith(
            error: 'Printer not connected & no saved printer found!',
            clearError: false));
        emit(state.copyWith(clearError: true));
        return;
      }
    }

    emit(state.copyWith(
        isPrinting: true, printSuccess: false, clearError: true));

    try {
      final itemsMap = state.cartItems
          .map((item) => {
                'name': item.product.name,
                'qty': item.quantity,
                'price': item.product.price,
                'total': item.total,
              })
          .toList();

      await printerHelper.printReceipt(
          shopName: event.shopName,
          address1: event.address1,
          address2: event.address2,
          phone: event.phone,
          items: itemsMap,
          total: state.totalAmount,
          footer: event.footer);
      
      // Save Invoice to local DB for Analytics
      await _saveInvoiceToLocalDb();

      emit(state.copyWith(isPrinting: false, printSuccess: true));

      // Trigger Google Sheets Sync
      add(SyncToGoogleSheetsEvent(shopName: event.shopName));

    } catch (e) {
      emit(state.copyWith(
          isPrinting: false, error: 'Print failed: $e', clearError: false));
      emit(state.copyWith(clearError: true));
    }
  }

  Future<void> _onPlaceOrder(
      PlaceOrderEvent event, Emitter<BillingState> emit) async {
    if (state.cartItems.isEmpty) return;

    emit(state.copyWith(isPrinting: true, printSuccess: false, clearError: true));

    try {
      await _saveInvoiceToLocalDb();
      
      // Trigger Google Sheets Sync
      add(SyncToGoogleSheetsEvent(shopName: event.shopName));
      
      emit(state.copyWith(isPrinting: false, printSuccess: true));
    } catch (e) {
      emit(state.copyWith(
          isPrinting: false, error: 'Failed to place order: $e', clearError: false));
      emit(state.copyWith(clearError: true));
    }
  }

  Future<void> _saveInvoiceToLocalDb() async {
    final email = HiveDatabase.settingsBox.get('logged_in_user');
    if (email != null) {
      final invoice = InvoiceModel.fromEntity(Invoice(
        id: const Uuid().v4(),
        userEmail: email,
        dateTime: DateTime.now(),
        items: state.cartItems,
        totalAmount: state.totalAmount,
      ));
      await HiveDatabase.invoiceBox.put(invoice.id, invoice);
    }
  }

  Future<void> _onSyncToGoogleSheets(
      SyncToGoogleSheetsEvent event, Emitter<BillingState> emit) async {
    if (_googleScriptUrl.isEmpty) return;

    try {
      final itemsSummary = state.cartItems
          .map((item) => "${item.product.name} (x${item.quantity})")
          .join(", ");

      final data = {
        'timestamp': DateTime.now().toIso8601String(),
        'shopName': event.shopName,
        'items': itemsSummary,
        'total': state.totalAmount.toStringAsFixed(2),
      };

      await http.post(
        Uri.parse(_googleScriptUrl),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      print('Error syncing to Google Sheets: $e');
    }
  }
}
