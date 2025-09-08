import 'package:csb_webshop_mobile/src/features/announcements/application/announcements_provider.dart';
import 'package:csb_webshop_mobile/src/features/announcements/data/announcements_api.dart';
import 'package:csb_webshop_mobile/src/features/announcements/domain/announcement.dart';
import 'package:csb_webshop_mobile/src/features/announcements/presentation/announcements_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAnnouncementsApi extends AnnouncementsApi {
  _FakeAnnouncementsApi(this._items);
  final List<Announcement> _items;

  @override
  Future<List<Announcement>> getAnnouncements() async {
    return _items;
  }
}

void main() {
  testWidgets('shows empty state when there are no announcements', (WidgetTester tester) async {
    final ProviderContainer container = ProviderContainer(overrides: <Override>[
      announcementsApiProvider.overrideWith((Ref ref) => _FakeAnnouncementsApi(<Announcement>[])),
    ]);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AnnouncementsListScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Nema obavijesti.'), findsOneWidget);
  });

  testWidgets('renders a list of announcements', (WidgetTester tester) async {
    final List<Announcement> items = <Announcement>[
      Announcement(
        id: 1,
        title: 'Prva vijest',
        body: 'Detalji...',
        publishedAt: DateTime(2024, 5, 1, 10, 30),
        type: AnnouncementType.info,
      ),
      Announcement(
        id: 2,
        title: 'Druga vijest',
        body: 'Detalji 2',
        publishedAt: DateTime(2024, 5, 2, 12, 0),
        type: AnnouncementType.update,
      ),
    ];

    final ProviderContainer container = ProviderContainer(overrides: <Override>[
      announcementsApiProvider.overrideWith((Ref ref) => _FakeAnnouncementsApi(items)),
    ]);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AnnouncementsListScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Prva vijest'), findsOneWidget);
    expect(find.text('Druga vijest'), findsOneWidget);

    expect(find.text('Nema obavijesti.'), findsNothing);
  });
}

