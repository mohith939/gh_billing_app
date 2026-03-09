import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/shop.dart';
import '../../domain/usecases/shop_usecases.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/data/hive_database.dart';
import '../../../auth/data/models/user_model.dart';

part 'shop_event.dart';
part 'shop_state.dart';

class ShopBloc extends Bloc<ShopEvent, ShopState> {
  final GetShopUseCase getShopUseCase;
  final UpdateShopUseCase updateShopUseCase;

  ShopBloc({
    required this.getShopUseCase,
    required this.updateShopUseCase,
  }) : super(ShopInitial()) {
    on<LoadShopEvent>(_onLoadShop);
    on<UpdateShopEvent>(_onUpdateShop);
  }

  Future<void> _onLoadShop(LoadShopEvent event, Emitter<ShopState> emit) async {
    emit(ShopLoading());
    final result = await getShopUseCase(NoParams());
    result.fold(
      (failure) => emit(ShopError(failure.message)),
      (shop) => emit(ShopLoaded(shop)),
    );
  }

  Future<void> _onUpdateShop(
      UpdateShopEvent event, Emitter<ShopState> emit) async {
    emit(ShopLoading());
    final result = await updateShopUseCase(event.shop);
    result.fold(
      (failure) => emit(ShopError(failure.message)),
      (_) {
        // After updating the general shop box, we also need to sync back to the User model
        // so that the data persists across logouts.
        _syncShopToUser(event.shop);
        
        add(LoadShopEvent());
        emit(ShopOperationSuccess());
      },
    );
  }

  void _syncShopToUser(Shop shop) {
    final email = HiveDatabase.settingsBox.get('logged_in_user');
    if (email != null) {
      final user = HiveDatabase.userBox.get(email);
      if (user != null) {
        final updatedUser = user.copyWith(
          shopName: shop.name,
          addressLine1: shop.addressLine1,
          addressLine2: shop.addressLine2,
          phoneNumber: shop.phoneNumber,
          upiId: shop.upiId,
          footerText: shop.footerText,
          qrCodePath: shop.qrCodePath,
        );
        HiveDatabase.userBox.put(email, updatedUser);
      }
    }
  }
}
