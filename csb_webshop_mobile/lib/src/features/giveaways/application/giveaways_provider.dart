import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/giveaways_api.dart';
import '../domain/giveaway.dart';
import '../domain/participant.dart';

final Provider<GiveawaysApi> giveawaysApiProvider = Provider<GiveawaysApi>((Ref ref) => GiveawaysApi());

class GiveawaysListNotifier extends AutoDisposeAsyncNotifier<List<Giveaway>> {
  String _status = 'all';

  @override
  Future<List<Giveaway>> build() async {
    final GiveawaysApi api = ref.read(giveawaysApiProvider);
    return api.getGiveaways(status: _status);
  }

  Future<void> filter(String status) async {
    _status = status;
    final GiveawaysApi api = ref.read(giveawaysApiProvider);
    state = const AsyncLoading<List<Giveaway>>();
    state = await AsyncValue.guard(() => api.getGiveaways(status: status));
  }

  Future<void> refresh() => filter(_status);
}

final AutoDisposeAsyncNotifierProvider<GiveawaysListNotifier, List<Giveaway>> giveawaysListProvider =
    AutoDisposeAsyncNotifierProvider<GiveawaysListNotifier, List<Giveaway>>(GiveawaysListNotifier.new);

class GiveawayDetailNotifier extends AutoDisposeAsyncNotifier<Giveaway> {
  int? _id;

  @override
  Future<Giveaway> build() async {
    if (_id == null) throw UnimplementedError('Call fetch(id) first');
    final GiveawaysApi api = ref.read(giveawaysApiProvider);
    final List<Giveaway> list = await api.getGiveaways();
    return list.firstWhere((Giveaway g) => g.id == _id);
  }

  Future<void> fetch(int id) async {
    _id = id;
    final GiveawaysApi api = ref.read(giveawaysApiProvider);
    state = const AsyncLoading<Giveaway>();
    final List<Giveaway> list = await api.getGiveaways();
    state = AsyncData<Giveaway>(list.firstWhere((Giveaway g) => g.id == id));
  }
}

final AutoDisposeAsyncNotifierProvider<GiveawayDetailNotifier, Giveaway> giveawayDetailProvider =
    AutoDisposeAsyncNotifierProvider<GiveawayDetailNotifier, Giveaway>(GiveawayDetailNotifier.new);

class ParticipantsNotifier extends AutoDisposeAsyncNotifier<List<GiveawayParticipant>> {
  int? _giveawayId;

  @override
  Future<List<GiveawayParticipant>> build() async {
    if (_giveawayId == null) return <GiveawayParticipant>[];
    final GiveawaysApi api = ref.read(giveawaysApiProvider);
    return api.getParticipants(_giveawayId!);
  }

  Future<void> load(int giveawayId) async {
    _giveawayId = giveawayId;
    final GiveawaysApi api = ref.read(giveawaysApiProvider);
    state = const AsyncLoading<List<GiveawayParticipant>>();
    state = await AsyncValue.guard(() => api.getParticipants(giveawayId));
  }
}

final AutoDisposeAsyncNotifierProvider<ParticipantsNotifier, List<GiveawayParticipant>> participantsProvider =
    AutoDisposeAsyncNotifierProvider<ParticipantsNotifier, List<GiveawayParticipant>>(ParticipantsNotifier.new);

