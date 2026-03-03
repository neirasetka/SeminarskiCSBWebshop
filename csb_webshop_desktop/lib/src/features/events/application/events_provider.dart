import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/events_api.dart';
import '../domain/event.dart';

final Provider<EventsApi> eventsApiProvider = Provider<EventsApi>((Ref ref) => EventsApi());

class EventsListNotifier extends AsyncNotifier<List<EventModel>> {
  @override
  Future<List<EventModel>> build() async {
    final EventsApi api = ref.read(eventsApiProvider);
    return api.getEvents();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<EventModel>>();
    final EventsApi api = ref.read(eventsApiProvider);
    state = await AsyncValue.guard(api.getEvents);
  }
}

final AsyncNotifierProvider<EventsListNotifier, List<EventModel>> eventsListProvider =
    AsyncNotifierProvider<EventsListNotifier, List<EventModel>>(EventsListNotifier.new);

class EventDetailNotifier extends AutoDisposeAsyncNotifier<EventModel> {
  int? _id;

  @override
  Future<EventModel> build() async {
    if (_id == null) throw UnimplementedError('Call fetch(id) first');
    final EventsApi api = ref.read(eventsApiProvider);
    return api.getEventById(_id!);
  }

  Future<void> fetch(int id) async {
    _id = id;
    final EventsApi api = ref.read(eventsApiProvider);
    state = const AsyncLoading<EventModel>();
    state = await AsyncValue.guard(() => api.getEventById(id));
  }

  Future<void> participate({required String name, required String email}) async {
    final int? id = _id;
    if (id == null) return;
    final EventsApi api = ref.read(eventsApiProvider);
    final EventModel? current = state.valueOrNull;
    if (current != null) {
      state = AsyncData<EventModel>(current.copyWith(isParticipating: true));
    }
    try {
      final EventModel updated = await api.participate(
        eventId: id,
        name: name,
        email: email,
      );
      state = AsyncData<EventModel>(updated);
    } catch (e, st) {
      state = AsyncError<EventModel>(e, st);
      rethrow;
    }
  }
}

final AutoDisposeAsyncNotifierProvider<EventDetailNotifier, EventModel> eventDetailProvider =
    AutoDisposeAsyncNotifierProvider<EventDetailNotifier, EventModel>(EventDetailNotifier.new);

final countdownProvider = StreamProvider.family<Duration, DateTime>((ref, DateTime startTime) {
  return Stream<Duration>.periodic(const Duration(seconds: 1), (_) {
    final DateTime now = DateTime.now();
    return startTime.difference(now);
  });
});

