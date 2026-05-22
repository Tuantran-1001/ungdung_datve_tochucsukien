class Event {
  final String id;
  final String title;
  final String description;
  final String date;
  final String location;
  final double price;
  final String imageUrl;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.price,
    required this.imageUrl,
  });
  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      date: map['date'],
      location: map['location'],
      price: map['price'],
      imageUrl: map['imageUrl'],
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'location': location,
      'price': price,
      'imageUrl': imageUrl,
    };
  }
}