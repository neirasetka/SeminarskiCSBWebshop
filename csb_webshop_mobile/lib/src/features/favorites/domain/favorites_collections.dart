/// Lokalno spremljeni ID-evi omiljenih torbi i kaiševa.
class FavoritesCollections {
  const FavoritesCollections({required this.bagIds, required this.beltIds});

  final Set<int> bagIds;
  final Set<int> beltIds;

  bool get isEmpty => bagIds.isEmpty && beltIds.isEmpty;
}
