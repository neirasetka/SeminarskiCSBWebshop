import 'dart:async';
import 'dart:math' as math;

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

  Future<Announcement> createBagAnnouncement({
    required String bagName,
    required double price,
    required String color,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final Announcement announcement = Announcement(
      id: _generateAnnouncementId(),
      title: 'Nova torbica: $bagName',
      body: 'Najavljujemo novu torbicu $bagName u $color boji po cijeni ${_formatPrice(price)} KM.',
      publishedAt: DateTime.now(),
      type: AnnouncementType.announcement,
    );
    _dummyAnnouncements.insert(0, announcement);
    return announcement;
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

int _generateAnnouncementId() {
  if (_dummyAnnouncements.isEmpty) {
    return 1;
  }
  final int maxId = _dummyAnnouncements.fold<int>(
    0,
    (int maxValue, Announcement announcement) => math.max(maxValue, announcement.id),
  );
  return maxId + 1;
}

String _formatPrice(double price) {
  final bool hasDecimals = price.remainder(1) != 0;
  return hasDecimals ? price.toStringAsFixed(2) : price.toStringAsFixed(0);
}

