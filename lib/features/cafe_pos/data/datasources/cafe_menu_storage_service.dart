import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/supabase_result.dart';
import '../../domain/models/coffee_menu_item.dart';

/// Immutable value object returned after uploading a menu photo to Supabase Storage.
@immutable
class MenuPhotoUploadResult {
  final String menuId;
  final String imageUrl;
  final String storagePath;

  const MenuPhotoUploadResult({
    required this.menuId,
    required this.imageUrl,
    required this.storagePath,
  });
}

/// Production-ready Supabase Service for dynamic Cafe Menu CRUD and Photo Storage
/// (`cafe_menus` PostgreSQL table + `menu-photos` Storage Bucket).
///
/// Adheres to Clean Architecture (Data Layer only), Defensive Lazy Initialization,
/// and Dart 3 sealed class result modeling.
class CafeMenuStorageService {
  final SupabaseClient? _customSupabase;
  final ImagePicker _imagePicker;

  CafeMenuStorageService({
    SupabaseClient? supabase,
    ImagePicker? imagePicker,
  })  : _customSupabase = supabase,
        _imagePicker = imagePicker ?? ImagePicker();

  SupabaseClient? get _supabase {
    if (_customSupabase != null) return _customSupabase;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Picks an image from Camera or Gallery and compresses it to <= 800x800 px (75% quality).
  Future<SupabaseResult<Uint8List?>> pickAndCompressPhoto({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 75,
      );
      if (picked == null) {
        return const SupabaseSuccess(null);
      }

      final rawBytes = await picked.readAsBytes();
      final compressed = await compressImageBytes(rawBytes);
      return SupabaseSuccess(compressed);
    } catch (e, stack) {
      debugPrint('CafeMenuStorageService.pickAndCompressPhoto error: $e\n$stack');
      return SupabaseFailure('Gagal memilih atau mengompresi foto menu', e);
    }
  }

  /// Compresses raw image bytes to max 800x800 px, 75% quality JPEG.
  /// Gracefully falls back to [rawBytes] in headless test environments.
  Future<Uint8List> compressImageBytes(
    Uint8List rawBytes, {
    int maxWidth = 800,
    int maxHeight = 800,
    int quality = 75,
  }) async {
    if (rawBytes.isEmpty) return rawBytes;
    try {
      final result = await FlutterImageCompress.compressWithList(
        rawBytes,
        minWidth: maxWidth,
        minHeight: maxHeight,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      return result.isNotEmpty ? result : rawBytes;
    } catch (_) {
      // Fallback for unit/widget test environments without native image codec channel
      return rawBytes;
    }
  }

  /// Fetches all cafe menus from PostgreSQL (`cafe_menus` table).
  Future<SupabaseResult<List<CoffeeMenuItem>>> fetchMenus({
    String? category,
    bool onlyAvailable = false,
  }) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient is not initialized');
    }

    try {
      var query = client.from('cafe_menus').select();
      if (category != null && category.trim().isNotEmpty) {
        query = query.eq('category', category.trim());
      }
      if (onlyAvailable) {
        query = query.eq('is_available', true);
      }

      final rows = await query.order('created_at', ascending: true);
      final menus = rows.map((row) => CoffeeMenuItem.fromMap(row)).toList();
      return SupabaseSuccess(menus);
    } catch (e, stack) {
      debugPrint('CafeMenuStorageService.fetchMenus error: $e\n$stack');
      return SupabaseFailure('Failed to fetch cafe menus from Supabase', e);
    }
  }

  /// Real-time stream of `cafe_menus` table.
  Stream<List<CoffeeMenuItem>> streamMenus() {
    final client = _supabase;
    if (client == null) {
      return Stream.value(CoffeeMenuItem.standardCatalog);
    }

    return client
        .from('cafe_menus')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((rows) {
          if (rows.isEmpty) {
            return CoffeeMenuItem.standardCatalog;
          }
          return rows.map((row) => CoffeeMenuItem.fromMap(row)).toList();
        });
  }

  /// Uploads a compressed photo to Supabase Storage bucket `menu-photos`,
  /// deletes [oldStoragePath] if provided so orphan files never accumulate,
  /// and updates `image_url` and `image_path` on the `cafe_menus` row.
  Future<SupabaseResult<MenuPhotoUploadResult>> uploadMenuPhoto({
    required String menuId,
    required Uint8List imageBytes,
    String? oldStoragePath,
    CoffeeMenuItem? fallbackMenuTemplate,
  }) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient is not initialized');
    }
    if (menuId.trim().isEmpty) {
      return const SupabaseFailure('Menu ID tidak boleh kosong');
    }

    try {
      final bucket = client.storage.from(AppConstants.menuPhotosBucket);

      // 1. Delete old photo in bucket if present (prevent orphan files on Mini PC / Cloud)
      if (oldStoragePath != null &&
          oldStoragePath.trim().isNotEmpty &&
          !oldStoragePath.startsWith('assets/')) {
        try {
          await bucket.remove([oldStoragePath.trim()]);
        } catch (e) {
          debugPrint('Non-fatal warning removing old menu photo: $e');
        }
      }

      // 2. Compress image before upload
      final compressedBytes = await compressImageBytes(imageBytes);
      final storagePath =
          'menus/${menuId.trim()}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 3. Upload binary to `menu-photos` bucket
      await bucket.uploadBinary(
        storagePath,
        compressedBytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      // 4. Get public URL
      final publicUrl = bucket.getPublicUrl(storagePath);

      // 5. Upsert/update `cafe_menus` row in PostgreSQL
      final template = fallbackMenuTemplate ??
          CoffeeMenuItem.standardCatalog
              .cast<CoffeeMenuItem?>()
              .firstWhere((item) => item?.id == menuId, orElse: () => null);

      final payload = <String, dynamic>{
        'id': menuId,
        'name': template?.nameId ?? menuId,
        'category': template?.category ?? 'coffee',
        'price': template?.basePrice ?? 25000,
        'description': template?.descriptionId ?? '',
        'image_url': publicUrl,
        'image_path': storagePath,
        'sign_video_url': template?.signVideoUrl,
        'is_available': template?.isAvailable ?? true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      await client.from('cafe_menus').upsert(
            payload,
            onConflict: 'id',
          );

      return SupabaseSuccess(
        MenuPhotoUploadResult(
          menuId: menuId,
          imageUrl: publicUrl,
          storagePath: storagePath,
        ),
      );
    } catch (e, stack) {
      debugPrint('CafeMenuStorageService.uploadMenuPhoto error: $e\n$stack');
      return SupabaseFailure('Failed to upload menu photo to Supabase', e);
    }
  }

  /// Creates or updates a menu item in `cafe_menus` (with optional new photo bytes).
  Future<SupabaseResult<CoffeeMenuItem>> upsertMenu(
    CoffeeMenuItem menu, {
    Uint8List? newPhotoBytes,
  }) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient is not initialized');
    }

    try {
      CoffeeMenuItem updatedMenu = menu;

      if (newPhotoBytes != null && newPhotoBytes.isNotEmpty) {
        final uploadRes = await uploadMenuPhoto(
          menuId: menu.id,
          imageBytes: newPhotoBytes,
          oldStoragePath: menu.storagePath,
          fallbackMenuTemplate: menu,
        );
        switch (uploadRes) {
          case SupabaseSuccess<MenuPhotoUploadResult>(data: final uploaded):
            updatedMenu = menu.copyWith(
              imageUrl: uploaded.imageUrl,
              storagePath: uploaded.storagePath,
            );
          case SupabaseFailure<MenuPhotoUploadResult>(
              errorMessage: final msg,
              error: final err
            ):
            return SupabaseFailure(msg, err);
        }
      } else {
        await client.from('cafe_menus').upsert(
              updatedMenu.toPostgresMap(),
              onConflict: 'id',
            );
      }

      return SupabaseSuccess(updatedMenu);
    } catch (e, stack) {
      debugPrint('CafeMenuStorageService.upsertMenu error: $e\n$stack');
      return SupabaseFailure('Failed to save cafe menu to Supabase', e);
    }
  }

  /// Deletes a menu item from `cafe_menus` AND removes its photo from `menu-photos` bucket.
  Future<SupabaseResult<void>> deleteMenu({
    required String menuId,
    String? storagePath,
  }) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient is not initialized');
    }

    try {
      if (storagePath != null &&
          storagePath.trim().isNotEmpty &&
          !storagePath.startsWith('assets/')) {
        try {
          await client.storage
              .from(AppConstants.menuPhotosBucket)
              .remove([storagePath.trim()]);
        } catch (e) {
          debugPrint('Non-fatal warning deleting menu photo from storage: $e');
        }
      }

      await client.from('cafe_menus').delete().eq('id', menuId);
      return const SupabaseSuccess(null);
    } catch (e, stack) {
      debugPrint('CafeMenuStorageService.deleteMenu error: $e\n$stack');
      return SupabaseFailure('Failed to delete menu: $menuId', e);
    }
  }
}
