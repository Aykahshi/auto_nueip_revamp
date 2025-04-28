import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:joker_state/joker_state.dart';

import '../../core/config/storage_keys.dart';
import '../../core/utils/auth_utils.dart';
import '../../core/utils/local_storage.dart';
import '../../domain/entities/profile_editing_state.dart';

// Presenter for profile editing logic and state management
class ProfileEditingPresenter extends Presenter<ProfileEditingState> {
  ProfileEditingPresenter() : super(const ProfileEditingState());

  @override
  void onInit() {
    super.onInit();
    _loadCredentials();
  }

  // Load initial credentials from storage
  void _loadCredentials() {
    final (companyCode, employeeId, password, address) =
        AuthUtils.getCredentials();
    trickWith(
      (state) => state.copyWith(
        companyCode: companyCode,
        employeeId: employeeId,
        password: password,
        companyAddress: address,
      ),
    );
  }

  // Toggle editing mode
  void toggleEditing() {
    trickWith(
      (state) => state.copyWith(
        isEditing: !state.isEditing,
        error: null, // Clear error when toggling edit mode
      ),
    );
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    trickWith(
      (state) => state.copyWith(isPasswordVisible: !state.isPasswordVisible),
    );
  }

  // Update specific field in state
  void updateField({
    String? companyCode,
    String? employeeId,
    String? password,
    String? companyAddress,
  }) {
    trickWith((state) {
      // Use Freezed copyWith for updating
      return state.copyWith(
        companyCode: companyCode ?? state.companyCode,
        employeeId: employeeId ?? state.employeeId,
        password: password ?? state.password,
        companyAddress: companyAddress ?? state.companyAddress,
      );
    });
  }

  // Save updated credentials and geocode address
  Future<void> saveProfile(
    String companyCode,
    String employeeId,
    String password,
    String companyAddress,
  ) async {
    trickWith((state) => state.copyWith(isLoading: true, error: null));
    try {
      // 1. Save credentials first
      await AuthUtils.saveCredentials(companyCode, employeeId, password);

      // 2. Geocode the address
      double? latitude;
      double? longitude;
      try {
        List<Location> locations = await locationFromAddress(companyAddress);
        if (locations.isNotEmpty) {
          latitude = locations.first.latitude;
          longitude = locations.first.longitude;
          // Save coordinates to LocalStorage
          await Future.wait([
            LocalStorage.set(StorageKeys.companyLatitude, latitude),
            LocalStorage.set(StorageKeys.companyLongitude, longitude),
            LocalStorage.set(StorageKeys.companyAddress, companyAddress),
          ]);
          debugPrint('Geocoding successful: ($latitude, $longitude)');

          // Update the global company address Joker
          Circus.spotlight<String>(tag: 'companyAddress').trick(companyAddress);
        } else {
          debugPrint('Geocoding failed: No locations found for address.');
        }
      } on PlatformException catch (e) {
        debugPrint('Geocoding PlatformException: ${e.code} - ${e.message}');
        trickWith(
          (state) => state.copyWith(
            isLoading: false,
            error: '地址轉換失敗：${e.message ?? "請檢查網路連線或稍後再試"}',
          ),
        );
        return; // Stop execution if geocoding fails critically
      } catch (e) {
        debugPrint('Geocoding general error: $e');
        // Handle other potential errors during geocoding
        trickWith(
          (state) => state.copyWith(isLoading: false, error: '地址轉換時發生未知錯誤'),
        );
        return; // Stop execution
      }

      // 3. Force check auth session with new credentials
      await AuthUtils.checkAuthSession(force: true);

      // 4. Update state on success (including the address)
      trickWith(
        (state) => state.copyWith(
          companyCode: companyCode,
          employeeId: employeeId,
          password: password,
          companyAddress: companyAddress, // Update address in state
          isLoading: false,
          isEditing: false, // Exit editing mode after saving
        ),
      );
    } catch (e) {
      debugPrint('Failed to save profile: $e');
      trickWith(
        (state) =>
            state.copyWith(isLoading: false, error: '儲存失敗，請檢查網路連線或稍後再試。'),
      );
    }
  }
}
