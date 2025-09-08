import 'dart:async';

import '../domain/event.dart';

class EventsApi {
  Future<List<EventModel>> getEvents() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _dummyEvents;
  }

  Future<EventModel> getEventById(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _dummyEvents.firstWhere((EventModel e) => e.id == id);
  }

  Future<EventModel> participate({required int eventId, required int userId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final int index = _dummyEvents.indexWhere((EventModel e) => e.id == eventId);
    if (index == -1) throw StateError('Event not found');
    final EventModel current = _dummyEvents[index];
    final List<int> list = <int>{...(current.participants ?? <int>[]), userId}.toList();
    final EventModel updated = current.copyWith(participants: list, isParticipating: true);
    _dummyEvents[index] = updated;
    return updated;
  }
}

List<EventModel> _dummyEvents = <EventModel>[
  EventModel(
    id: 1,
    title: 'Giveaway – CSB torba',
    description: 'Prijavi se i osvoji limited edition CSB torbu! Izvlačenje na početku eventa.',
    startDateTime: DateTime.now().add(const Duration(minutes: 10)),
    participants: <int>[],
  ),
  EventModel(
    id: 2,
    title: 'Live Q&A',
    description: 'Postavite pitanja uživo. Najbolje pitanje dobija poklon vaučer.',
    startDateTime: DateTime.now().add(const Duration(hours: 3)),
    participants: <int>[],
  ),
];

