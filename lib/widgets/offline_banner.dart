import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

/// Reusable Network Offline Status Banner for QuickRide.
///
/// Automatically listens to [ConnectivityService] changes and displays
/// an informative, non-intrusive status banner with a retry action.
class OfflineBanner extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;

  const OfflineBanner({
    super.key,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final connectivity = ConnectivityService();

    return StreamBuilder<bool>(
      stream: connectivity.onConnectivityChanged,
      initialData: connectivity.isOnline,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;
        if (isOnline) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFC53030), // Warning Red
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  customMessage ?? 'No internet connection. Offline protection active.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              InkWell(
                onTap: onRetry ?? () => connectivity.checkConnectivity(),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'RETRY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
