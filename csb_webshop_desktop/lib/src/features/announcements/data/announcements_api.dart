import 'dart:async';

import '../domain/announcement.dart';

class AnnouncementsApi {
  Future<List<Announcement>> getAnnouncements() async {
    // Simulate network latency
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _dummyAnnouncements;
  }

  Future<Announcement> getAnnouncementById(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _dummyAnnouncements.firstWhere((Announcement a) => a.id == id);
  }
}

final List<Announcement> _dummyAnnouncements = <Announcement>[
  Announcement(
    id: 1,
    title: 'Dobrodošli u aplikaciju',
    body: 'Hvala što koristite našu aplikaciju. Ovo je početna obavijest.',
    publishedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    type: AnnouncementType.info,
  ),
  Announcement(
    id: 2,
    title: 'Veliki update 1.1',
    body: 'Dodali smo nove funkcionalnosti i poboljšanja performansi.',
    publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
    type: AnnouncementType.update,
  ),
  Announcement(
    id: 3,
    title: 'Akcija ovog vikenda',
    body: 'Iskoristite posebne popuste do 30% na odabrane artikle.',
    publishedAt: DateTime.now().subtract(const Duration(days: 3, hours: 4)),
    type: AnnouncementType.announcement,
  ),
];

