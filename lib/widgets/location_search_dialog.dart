import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimensions.dart';
import '../core/constants/app_strings.dart';
import '../models/location_model.dart';
import '../services/places_service.dart';

/// Modal dialog / bottom sheet allowing the user to search and select a location.
class LocationSearchDialog extends StatefulWidget {
  const LocationSearchDialog({
    super.key,
    required this.title,
    required this.initialQuery,
    required this.isPickup,
  });

  final String title;
  final String initialQuery;
  final bool isPickup;

  static Future<LocationPoint?> show(
    BuildContext context, {
    required String title,
    String initialQuery = '',
    bool isPickup = false,
  }) {
    return showModalBottomSheet<LocationPoint>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LocationSearchDialog(
        title: title,
        initialQuery: initialQuery,
        isPickup: isPickup,
      ),
    );
  }

  @override
  State<LocationSearchDialog> createState() => _LocationSearchDialogState();
}

class _LocationSearchDialogState extends State<LocationSearchDialog> {
  late final TextEditingController _searchController;
  List<LocationPoint> _suggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _loadSuggestions(widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions(String query) async {
    setState(() => _isLoading = true);
    final results = await PlacesService.searchLocations(query);
    if (mounted) {
      setState(() {
        _suggestions = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: AppColors.cardDark,
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLarge)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderDark,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
            child: Row(
              children: [
                Icon(
                  widget.isPickup ? Icons.my_location_rounded : Icons.location_on_rounded,
                  color: widget.isPickup ? AppColors.secondary : AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondaryLight),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space8),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 15),
              decoration: InputDecoration(
                hintText: AppStrings.searchLocationHint,
                hintStyle: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondaryLight, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _loadSuggestions('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceDark,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  borderSide: const BorderSide(color: AppColors.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              onChanged: (val) => _loadSuggestions(val),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  _selectCustomLocation(val.trim());
                }
              },
            ),
          ),
          const SizedBox(height: AppDimensions.space12),

          // Popular spots header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: 4),
            child: Row(
              children: [
                const Text(
                  AppStrings.popularPlacesHeader,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryLight,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
              ],
            ),
          ),
          const Divider(color: AppColors.borderDark, height: 8),

          // Quick action for pickup: Use Current Location
          if (widget.isPickup && _searchController.text.trim().isEmpty) ...[
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.secondary),
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  size: 18,
                  color: AppColors.secondary,
                ),
              ),
              title: const Text(
                'Use Current Location',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              subtitle: const Text(
                'Detect GPS coordinates and current address',
                style: TextStyle(
                  color: AppColors.textSecondaryLight,
                  fontSize: 12,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop(
                  const LocationPoint(
                    latitude: 0,
                    longitude: 0,
                    name: AppStrings.currentLocation,
                    address: 'Current Device Location',
                    placeId: 'use_current_gps',
                  ),
                );
              },
            ),
            const Divider(color: AppColors.borderDark, height: 1, indent: 52),
          ],

          // Suggestions list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              separatorBuilder: (_, _) => const Divider(
                color: AppColors.borderDark,
                height: 1,
                indent: 52,
              ),
              itemBuilder: (context, index) {
                final place = _suggestions[index];
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Icon(
                      _getIconForPlace(place.name),
                      size: 18,
                      color: widget.isPickup ? AppColors.secondary : AppColors.primary,
                    ),
                  ),
                  title: Text(
                    place.name,
                    style: const TextStyle(
                      color: AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    place.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondaryLight,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () => Navigator.of(context).pop(place),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

  void _selectCustomLocation(String query) {
    final customPoint = LocationPoint(
      latitude: 12.9716 + 0.015,
      longitude: 77.5946 + 0.018,
      name: query,
      address: '$query (Custom Location)',
    );
    Navigator.of(context).pop(customPoint);
  }

  IconData _getIconForPlace(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('airport')) return Icons.flight_takeoff_rounded;
    if (lower.contains('station') || lower.contains('railway')) return Icons.train_rounded;
    if (lower.contains('bus')) return Icons.directions_bus_rounded;
    if (lower.contains('metro')) return Icons.subway_rounded;
    if (lower.contains('park') || lower.contains('tech')) return Icons.business_rounded;
    return Icons.place_rounded;
  }
}
