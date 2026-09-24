import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickride_user/services/user_storage_service.dart';
import 'package:quickride_user/services/session_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('User Storage Service Tests', () {
    test('UserStorageService singleton instance is consistent', () {
      final s1 = UserStorageService();
      final s2 = UserStorageService();
      expect(identical(s1, s2), isTrue);
    });

    test('uploadProfileImage gracefully executes offline fallback and tracks progress', () async {
      final service = UserStorageService();
      final session = SessionManager();

      double recordedProgress = 0.0;
      final dummyFile = XFile.fromData(
        Uint8List.fromList([1, 2, 3, 4, 5]),
        name: 'test_avatar.png',
      );

      final result = await service.uploadProfileImage(
        userId: session.currentUser.userId,
        file: dummyFile,
        onProgress: (progress) {
          recordedProgress = progress;
        },
      );

      expect(result.success, isTrue);
      expect(result.isOfflineFallback, isTrue);
      expect(result.downloadUrl, isNotNull);
      expect(recordedProgress, equals(1.0));
      expect(session.currentUser.profileImage, equals(result.downloadUrl));
    });
  });
}
