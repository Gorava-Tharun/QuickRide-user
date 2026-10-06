import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimensions.dart';
import '../core/constants/app_strings.dart';
import '../models/location_model.dart';
import '../services/places_service.dart';

/// Modal dialog / bottom sheet allowing the user to search and select a location.
///
/// Supports real Google Places Autocomplete with GPS location bias and
/// direct "Select on Map" option for destination selection.
class LocationSearchDialog extends StatefulWidget {
  const LocationSearchDialog({
    super.key,
    required this.title,
    required this.initialQuery,
    required this.isPickup,
    this.currentLatitude,
    this.currentLongitude,
  });

  final String title;
  final String initialQuery;
  final bool isPickup;
  final double? currentLatitude;
  final double? currentLongitude;

  static Future<LocationPoint?> show(
    BuildContext context, {
    required String title,
    String initialQuery = '',
    bool isPickup = false,
    double? currentLatitude,
    double? currentLongitude,
  }) {
    return showModalBottomSheet<LocationPoint>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LocationSearchDialog(
        title: title,
        initialQuery: initialQuery,
        isPickup: isPickup,
        currentLatitude: currentLatitude,
        currentLongitude: currentLongitude,
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
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _loadSuggestions(widget.initialQuery);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _loadSuggestions(query);
    });
  }

  Future<void> _loadSuggestions(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty && PlacesService.mockSearchResults == null) {
      if (mounted) {
        setState(() {
          _suggestions = PlacesService.curatedLocations;
          _isLoading = false;
        });
      }
      return;
    }

    setState(() => _isLoading = true);
    final results = await PlacesService.searchLocations(
      cleanQuery,
      currentLat: widget.currentLatitude,
      currentLng: widget.currentLongitude,
    );

    if (mounted) {
      setState(() {
        _suggestions = results;
        _isLoading = false;
      });
    }
  }

  void _triggerSelectOnMap() {
    Navigator.of(context).pop(
      const LocationPoint(
        latitude: 0,
        longitude: 0,
        name: 'Select on Map',
        address: 'Select directly on Google Map',
        placeId: 'select_on_map',
      ),
    );
  }

  Future<void> _onSelectSuggestion(LocationPoint place) async {
    if (place.latitude == 0.0 && place.longitude == 0.0 && place.placeId != null) {
      setState(() => _isLoading = true);
      final resolved = await PlacesService.resolvePlaceCoordinates(place);
      if (mounted) {
        Navigator.of(context).pop(resolved);
      }
    } else {
      Navigator.of(context).pop(place);
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
                  hintText: widget.isPickup
                      ? AppStrings.searchLocationHint
                      : 'Search street, shop, area or landmark...',
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
                onChanged: _onSearchChanged,
                onSubmitted: (val) {
                  _debounceTimer?.cancel();
                  _loadSuggestions(val);
                },
              ),
            ),
            const SizedBox(height: AppDimensions.space8),

            // Quick Actions Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    widget.isPickup ? 'CURRENT LOCATION' : 'SELECT OPTIONS',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondaryLight,
                      letterSpacing: 0.6,
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

            // Quick action for destination: Select Directly on Google Map
            if (!widget.isPickup) ...[
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text(
                  'Select Directly on Google Map',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                subtitle: const Text(
                  'Tap any point or road on map to drop destination marker',
                  style: TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondaryLight),
                onTap: _triggerSelectOnMap,
              ),
              const Divider(color: AppColors.borderDark, height: 1, indent: 52),
            ],

            // Empty state when search yields no matches
            if (!_isLoading &&
                _searchController.text.trim().isNotEmpty &&
                _suggestions.isEmpty) ...[
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: const Icon(
                          Icons.location_off_outlined,
                          size: 30,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No matching location found',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Try searching with a landmark, area name, or tap "Select on Map" to choose directly on the Google Map.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      if (!widget.isPickup) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                            ),
                          ),
                          icon: const Icon(Icons.map_rounded, size: 18),
                          label: const Text(
                            'Select on Map',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          onPressed: _triggerSelectOnMap,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            // Suggestions list from Google Places API or Popular Transit Spots
            if (_suggestions.isNotEmpty && _searchController.text.trim().isEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: 6),
                child: Row(
                  children: [
                    Text(
                      AppStrings.popularPlacesHeader,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.borderDark, height: 4),
            ],
            if (_suggestions.isNotEmpty)
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
                      onTap: () => _onSelectSuggestion(place),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForPlace(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('airport')) return Icons.flight_takeoff_rounded;
    if (lower.contains('station') || lower.contains('railway')) return Icons.train_rounded;
    if (lower.contains('bus')) return Icons.directions_bus_rounded;
    if (lower.contains('metro')) return Icons.subway_rounded;
    if (lower.contains('hospital') || lower.contains('clinic')) return Icons.local_hospital_rounded;
    if (lower.contains('college') || lower.contains('school') || lower.contains('university')) {
      return Icons.school_rounded;
    }
    if (lower.contains('park') || lower.contains('tech')) return Icons.business_rounded;
    return Icons.place_rounded;
  }
}
