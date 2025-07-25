import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/hive_models.dart';
import '../models/api_response.dart';

class DatabaseService {
  static const String _boxName = 'itineraries';
  late Box _box;
  bool _isInitialized = false;

  // Initialize Hive and open box
  Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    _isInitialized = true;
  }

  // Save an itinerary
  Future<String> saveItinerary(TripItinerary itinerary) async {
    await init();
    try {
      final savedItinerary = SavedItinerary.fromApiModel(itinerary);
      final key = await _box.add(savedItinerary.toMap());
      return key.toString();
    } catch (e) {
      debugPrint('Error saving itinerary: $e');
      rethrow;
    }
  }

  // Get recent itineraries (limited by count)
  List<SavedItinerary> getRecentItineraries(int count) {
    if (!_isInitialized) {
      debugPrint('Database not initialized');
      return [];
    }

    try {
      final keys = _box.keys.toList();
      final itineraries = <SavedItinerary>[];

      for (var key in keys) {
        final map = _box.get(key);
        if (map != null) {
          final savedItinerary = SavedItinerary.fromMap(
            Map<String, dynamic>.from(map),
          );
          // Attach the Hive key to the object
          savedItinerary.key = key as int?;
          itineraries.add(savedItinerary);
        }
      }

      itineraries.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return itineraries.take(count).toList();
    } catch (e) {
      debugPrint('Error getting recent itineraries: $e');
      return [];
    }
  }

  // Get itinerary by key
  TripItinerary? getItineraryByKey(String key) {
    if (!_isInitialized) {
      debugPrint('Database not initialized');
      return null;
    }

    try {
      final map = _box.get(int.parse(key));
      if (map == null) return null;

      final savedItinerary = SavedItinerary.fromMap(
        Map<String, dynamic>.from(map),
      );
      return savedItinerary.toApiModel();
    } catch (e) {
      debugPrint('Error getting itinerary by key: $e');
      return null;
    }
  }

  // Delete itinerary
  Future<bool> deleteItinerary(String key) async {
    if (!_isInitialized) {
      debugPrint('Database not initialized');
      return false;
    }

    try {
      await _box.delete(int.parse(key));
      return true;
    } catch (e) {
      debugPrint('Error deleting itinerary: $e');
      return false;
    }
  }

  Future<void> saveUserName(String name) async {
    var box = await Hive.openBox('user_profile');
    await box.put('name', name);
  }

  // Retrieve user name from Hive
  Future<String?> getUserName() async {
    var box = await Hive.openBox('user_profile');
    return box.get('name') as String?;
  }

  Future<void> saveTokenUsage({
    required int requestTokens,
    required int responseTokens,
  }) async {
    var box = await Hive.openBox('app_settings');
    await box.put('request_tokens', requestTokens);
    await box.put('response_tokens', responseTokens);
    debugPrint(
      'Saved token usage: $requestTokens request, $responseTokens response',
    );
  }

  // Get token usage
  Future<Map<String, int>> getTokenUsage() async {
    var box = await Hive.openBox('app_settings');
    final requestTokens = box.get('request_tokens', defaultValue: 0) as int;
    final responseTokens = box.get('response_tokens', defaultValue: 0) as int;
    debugPrint(
      'Retrieved token usage: $requestTokens request, $responseTokens response',
    );
    return {'requestTokens': requestTokens, 'responseTokens': responseTokens};
  }

  // Close the box when no longer needed
  Future<void> close() async {
    if (_isInitialized) {
      await _box.close();
      _isInitialized = false;
    }
  }
}
