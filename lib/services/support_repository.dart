import '../models/support_request_model.dart';

/// Abstract contract for customer support requests.
///
/// Decouples UI from the underlying storage mechanism (local in-memory vs cloud backend).
abstract class SupportRepository {
  /// Submits and persists a new [SupportRequest].
  Future<SupportRequest> createSupportRequest(SupportRequest request);

  /// Retrieves all submitted support requests sorted newest first.
  List<SupportRequest> getSupportRequests();

  /// Retrieves a specific support request by its [id], or null if not found.
  SupportRequest? getSupportRequestById(String id);

  /// Updates the lifecycle [status] of an existing request.
  void updateSupportRequestStatus(String id, SupportStatus status);
}
