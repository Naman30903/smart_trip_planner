import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/api_response.dart';

@HiveType(typeId: 0)
class SavedItinerary extends HiveObject {
  @HiveField(0)
  late String title;

  @HiveField(1)
  late String startDate;

  @HiveField(2)
  late String endDate;

  @HiveField(3)
  late DateTime savedAt;

  @HiveField(4)
  late String daysJson;

  @HiveField(5)
  late final int? key;

  // set key(int? value) {
  //   key = value;
  // }

  SavedItinerary({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.savedAt,
    required this.daysJson,
  });

  // Factory method to convert from API model
  factory SavedItinerary.fromApiModel(TripItinerary itinerary) {
    return SavedItinerary(
      title: itinerary.title,
      startDate: itinerary.startDate,
      endDate: itinerary.endDate,
      savedAt: DateTime.now(),
      daysJson: jsonEncode({
        'days': itinerary.days
            .map(
              (day) => {
                'date': day.date,
                'summary': day.summary,
                'items': day.items
                    .map(
                      (item) => {
                        'time': item.time,
                        'activity': item.activity,
                        'location': item.location,
                      },
                    )
                    .toList(),
              },
            )
            .toList(),
      }),
    );
  }

  // Method to convert to API model
  TripItinerary toApiModel() {
    final decodedData = jsonDecode(daysJson);

    final List<Day> days = (decodedData['days'] as List).map<Day>((dayData) {
      final List<Item> items = (dayData['items'] as List).map<Item>((itemData) {
        return Item(
          time: itemData['time'],
          activity: itemData['activity'],
          location: itemData['location'],
        );
      }).toList();

      return Day(
        date: dayData['date'],
        summary: dayData['summary'],
        items: items,
      );
    }).toList();

    return TripItinerary(
      title: title,
      startDate: startDate,
      endDate: endDate,
      days: days,
    );
  }

  // Hive storage helpers
  Map<String, dynamic> toMap() => {
    'title': title,
    'startDate': startDate,
    'endDate': endDate,
    'savedAt': savedAt.toIso8601String(),
    'daysJson': daysJson,
  };

  factory SavedItinerary.fromMap(Map<String, dynamic> map) {
    return SavedItinerary(
      title: map['title'],
      startDate: map['startDate'],
      endDate: map['endDate'],
      savedAt: DateTime.parse(map['savedAt']),
      daysJson: map['daysJson'],
    );
  }
}
