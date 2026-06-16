/// Tekstovi za For You / preporuke kad API vrati popularni fallback.
class RecommendationMessages {
  const RecommendationMessages._();

  static String nonPersonalizedHint({required bool hasFavorites}) {
    if (hasFavorites) {
      return 'Popularni proizvodi — ocijenite ih za personalizaciju.';
    }
    return 'Popularni proizvodi — dodajte favorite za personalizaciju.';
  }
}
