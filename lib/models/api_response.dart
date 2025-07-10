class TripItinerary {
  final String title;
  final String startDate;
  final String endDate;
  final List<Day> days;

  TripItinerary({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.days,
  });

  factory TripItinerary.fromJson(Map<String, dynamic> json) {
    return TripItinerary(
      title: json['title'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      days: (json['days'] as List? ?? [])
          .map((day) => Day.fromJson(day))
          .toList(),
    );
  }
}

class Day {
  final String date;
  final String summary;
  final List<Item> items;

  Day({required this.date, required this.summary, required this.items});

  factory Day.fromJson(Map<String, dynamic> json) {
    return Day(
      date: json['date'] ?? '',
      summary: json['summary'] ?? '',
      items: (json['items'] as List? ?? [])
          .map((item) => Item.fromJson(item))
          .toList(),
    );
  }
}

class Item {
  final String time;
  final String activity;
  final String location;

  Item({required this.time, required this.activity, required this.location});

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      time: json['time'] ?? '',
      activity: json['activity'] ?? '',
      location: json['location'] ?? '',
    );
  }
}
