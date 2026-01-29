import 'dart:async';

import '../domain/announcement.dart';

class AnnouncementsApi {
  Future<List<Announcement>> getAnnouncements() async {
    // Simulate network latency
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List<Announcement>.from(_dummyAnnouncements);
  }

  Future<Announcement> getAnnouncementById(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _dummyAnnouncements.firstWhere((Announcement a) => a.id == id);
  }

  /// Creates a new bag announcement.
  /// Returns the created announcement.
  Future<Announcement> createBagAnnouncement({
    required String bagName,
    required double bagPrice,
    required String bagColor,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    
    final int newId = _dummyAnnouncements.isEmpty 
        ? 1 
        : _dummyAnnouncements.map((Announcement a) => a.id).reduce((int a, int b) => a > b ? a : b) + 1;
    
    final Announcement newAnnouncement = Announcement(
      id: newId,
      title: 'Nova torbica: $bagName',
      body: 'Predstavljamo vam novu torbicu "$bagName" u boji $bagColor po cijeni od ${bagPrice.toStringAsFixed(2)} KM. Pogledajte našu ponudu!',
      publishedAt: DateTime.now(),
      type: AnnouncementType.announcement,
    );
    
    // Add to the beginning of the list (newest first)
    _dummyAnnouncements.insert(0, newAnnouncement);
    
    return newAnnouncement;
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

