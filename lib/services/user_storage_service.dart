import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'firebase_service.dart';
import 'session_manager.dart';

class StorageUploadResult {
  final bool success;
  final String? downloadUrl;
  final String? errorMessage;
  final bool isOfflineFallback;

  const StorageUploadResult({
    required this.success,
    this.downloadUrl,
    this.errorMessage,
    this.isOfflineFallback = false,
  });
}

class UserStorageService {
  static final UserStorageService _instance = UserStorageService._internal();
  factory UserStorageService() => _instance;
  UserStorageService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery or camera
  Future<XFile?> pickProfileImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('[UserStorageService] Error picking image: $e');
      return null;
    }
  }

  /// Upload user profile image to Firebase Storage at users/{userId}/profile/
  /// Gracefully falls back to offline/mock if Firebase is unavailable.
  Future<StorageUploadResult> uploadProfileImage({
    required String userId,
    required XFile file,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final Uint8List bytes = await file.readAsBytes();
      final firebaseService = QuickRideFirebaseService();

      if (firebaseService.isFirebaseAvailable) {
        final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
        final storagePath = 'users/$userId/profile/$fileName';

        final storageRef = FirebaseStorage.instance.ref().child(storagePath);
        final uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/$ext'),
        );

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (snapshot.totalBytes > 0) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress?.call(progress);
          }
        });

        final TaskSnapshot completedSnapshot = await uploadTask;
        final String downloadUrl = await completedSnapshot.ref.getDownloadURL();

        // Update SessionManager
        final session = SessionManager();
        session.updateProfile(session.currentUser.copyWith(profileImage: downloadUrl));

        debugPrint('[UserStorageService] Profile uploaded successfully: $downloadUrl');
        return StorageUploadResult(success: true, downloadUrl: downloadUrl);
      } else {
        // Fallback: simulate smooth upload progress
        debugPrint('[UserStorageService] Firebase unavailable, using offline fallback');
        onProgress?.call(0.3);
        await Future.delayed(const Duration(milliseconds: 150));
        onProgress?.call(0.7);
        await Future.delayed(const Duration(milliseconds: 150));
        onProgress?.call(1.0);

        // Standard high-res avatar placeholder for offline mode
        const fallbackUrl = 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=400&q=80';
        final session = SessionManager();
        session.updateProfile(session.currentUser.copyWith(profileImage: fallbackUrl));

        return const StorageUploadResult(
          success: true,
          downloadUrl: fallbackUrl,
          isOfflineFallback: true,
        );
      }
    } catch (e) {
      debugPrint('[UserStorageService] Upload error: $e');
      return StorageUploadResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Upload complaint screenshot attachment to complaints/{userId}/{timestamp}.ext
  Future<StorageUploadResult> uploadComplaintAttachment({
    required String userId,
    required String complaintId,
    required XFile file,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final Uint8List bytes = await file.readAsBytes();
      final firebaseService = QuickRideFirebaseService();

      if (firebaseService.isFirebaseAvailable) {
        final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
        final storagePath = 'complaints/$userId/$complaintId/$fileName';

        final storageRef = FirebaseStorage.instance.ref().child(storagePath);
        final uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/$ext'),
        );

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (snapshot.totalBytes > 0) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress?.call(progress);
          }
        });

        final TaskSnapshot completedSnapshot = await uploadTask;
        final String downloadUrl = await completedSnapshot.ref.getDownloadURL();

        debugPrint('[UserStorageService] Complaint attachment uploaded: $downloadUrl');
        return StorageUploadResult(success: true, downloadUrl: downloadUrl);
      } else {
        debugPrint('[UserStorageService] Offline fallback: simulating complaint attachment upload');
        onProgress?.call(0.3);
        await Future.delayed(const Duration(milliseconds: 100));
        onProgress?.call(0.7);
        await Future.delayed(const Duration(milliseconds: 100));
        onProgress?.call(1.0);

        const fallbackUrl = 'https://images.unsplash.com/photo-1590674899484-d5640e854abe?auto=format&fit=crop&w=600&q=80';
        return const StorageUploadResult(
          success: true,
          downloadUrl: fallbackUrl,
          isOfflineFallback: true,
        );
      }
    } catch (e) {
      debugPrint('[UserStorageService] Complaint attachment upload error: $e');
      return StorageUploadResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }
}
