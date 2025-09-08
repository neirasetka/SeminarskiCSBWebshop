class EventModel {
  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDateTime,
    this.participants,
    this.isParticipating = false,
  });

  final int id;
  final String title;
  final String description;
  final DateTime startDateTime;
  final List<int>? participants; // user IDs, optional for demo
  final bool isParticipating;

  EventModel copyWith({
    String? title,
    String? description,
    DateTime? startDateTime,
    List<int>? participants,
    bool? isParticipating,
  }) {
    return EventModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDateTime: startDateTime ?? this.startDateTime,
      participants: participants ?? this.participants,
      isParticipating: isParticipating ?? this.isParticipating,
    );
  }
}

