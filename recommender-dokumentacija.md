# Recommender System – Dokumentacija

## Pregled

CocoSunBags Webshop koristi **content-based recommender** sistem koji preporučuje proizvode (torbe i kaiševe) na osnovu korisnikovog profila — favorita, ocjena i historije kupovine.

Algoritam je **deterministički** (bez randomizacije), **objašnjiv** (svaka preporuka ima `Reason` polje) i pokriva **cold-start** scenarij (korisnici bez historije dobijaju popularne proizvode).

## Signali koji se koriste

| Signal | Opis | Težina u profilu |
|--------|------|------------------|
| Favoriti (tip proizvoda) | Tipovi torbi/kaiševa koje je korisnik označio kao omiljene | **3.0** |
| Ocjene (rating ≥ 3) | Tipovi proizvoda koje je korisnik visoko ocijenio | **2.0** |
| Historija kupovine (tip) | Tipovi proizvoda iz završenih narudžbi | **1.0** |
| Cijena (referentni raspon) | Prosječna cijena favorita, ocjena i kupnji | Bonus u scoringu |
| Prosječna ocjena proizvoda | Prosječna ocjena od svih korisnika za kandidatski proizvod | Bonus bodovi |
| Broj kupnji proizvoda | Koliko puta je proizvod kupljen (OrderItems) | Bonus bodovi |
| Kupljeni proizvodi | Proizvodi koje je korisnik već kupio | **Isključeni** iz preporuka |
| Proizvodi u favoritima | Proizvodi koji su već u favoritima korisnika | **Isključeni** iz preporuka |

Više signala za isti tip se **zbraja** (npr. favorit + kupnja istog tipa → težina 4.0).

## Algoritam

### 1. Gradi se korisnički profil (`BuildUserProfileAsync`)

Za prijavljenog korisnika servis učitava:
- favorite → dodaje težinu tipu (+3.0) i cijenu u referentni skup
- ocjene ≥ 3 → dodaje težinu tipu (+2.0) i cijenu
- kupnje (Purchase → OrderItems) → dodaje težinu tipu (+1.0) i cijenu

Rezultat profila:
- `TypeWeights` — mapa `TipID → akumulirana težina`
- `PreferredPrice` — prosječna cijena iz svih referentnih proizvoda

### 2. Filtriranje kandidata

- Uzimaju se proizvodi čiji **tip** postoji u profilu (`TypeWeights.Keys`).
- Isključuju se već **kupljeni** i već **favorizirani** proizvodi.
- Ako nema kandidata nakon filtriranja → prelazi se na **popular fallback**.

### 3. Scoring (`ComputeScore`)

Za svakog kandidata:

| Kriterij | Formula / uvjet | Bodovi |
|----------|-----------------|--------|
| Podudaranje tipa | `težina_tipa × 5.0` | Varira po profilu (npr. 15 za favorit, 10 za ocjenu, 5 za kupnju) |
| Sličnost cijene | Odstupanje ≤ 25% od `PreferredPrice` | do **+5.0** (linearno opada) |
| Popularnost (kupnje) | Broj kupnji proizvoda | `kupnje × 0.5` |
| Popularnost (ocjena) | Prosječna ocjena ≥ 3.5 | `avgRating × 2.0` |

**Važno:** Bodovi za tip **razlikuju** kandidate — proizvod čiji tip dolazi iz favorita dobija više bodova nego onaj samo iz kupnje.

### 4. Sortiranje i selekcija

- Sortiranje: `Score` silazno, zatim `ProductId` (stabilan redoslijed).
- Vraća se `take` rezultata (default: 3).

### 5. Cold-start fallback (`GetPopularFallbackAsync`)

Aktivira se kada:
- korisnik nema signale tipova (nema favorita, ocjena ≥ 3 ni kupnji), **ili**
- nema kandidata nakon personalizovanog filtriranja.

Fallback rangira sve dostupne proizvode po:
- broju kupnji × 0.5
- prosječnoj ocjeni × 2.0 (ako je ≥ 3.5)

Odgovor ima `IsPersonalized = false` i `Reason` poput: *"Popularan proizvod u ponudi; 12 kupnji; Prosječna ocjena 4.2"*.

## Korisnici bez historije

Korisnik **uvijek dobija preporuke** — nikad praznu listu zbog nedostatka profila (osim ako je katalog prazan).

- **Bez favorita/ocjena/kupnji** → popularni proizvodi (cold-start).
- **Sa profilom** → personalizovane preporuke (`IsPersonalized = true`).

## Integracija u aplikaciju

### Backend

| Komponenta | Putanja | Uloga |
|------------|---------|-------|
| `RecommendationController` | `CSBWebshopSeminarski/Controllers/RecommendationController.cs` | REST API, JWT |
| `RecommendationService` | `CBSWebshopSeminarski.Services/Services/RecommendationService.cs` | Cijela logika |
| `IRecommendationService` | `CBSWebshopSeminarski.Services/Interfaces/IRecommendationService.cs` | Interface |
| `RecommendedProductDto` | `CBSWebshopSeminarski.Model/Models/RecommendedProductDto.cs` | Response model |

**Endpointi:**
- `GET /api/Recommendation/GetRecommendedBags?take=3`
- `GET /api/Recommendation/GetRecommendedBelts?take=3`

Oba zahtijevaju `[Authorize]`. `UserID` se čita iz JWT (`ClaimTypes.NameIdentifier`), ne iz URL-a.

**Ključne metode u servisu:**

| Metoda | Svrha |
|--------|-------|
| `GetRecommendedBags` / `GetRecommendedBelts` | Javni ulaz |
| `GetRecommendationsAsync` | Orkestracija profila, scoringa i fallbacka |
| `BuildUserProfileAsync` | Gradi profil iz favorita, ocjena i kupnji |
| `GetExcludedProductIdsAsync` | ID-jevi kupljenih i favoriziranih proizvoda |
| `ScoreAndRankBagsAsync` / `ScoreAndRankBeltsAsync` | Personalizovani scoring |
| `ComputeScore` | Formula bodovanja + generisanje `Reason` |
| `GetPopularFallbackAsync` | Cold-start preporuke |
| `GetBagStatsAsync` / `GetBeltStatsAsync` | Agregati ocjena i kupnji po proizvodu |

### Flutter (mobilna + desktop)

| Komponenta | Uloga |
|------------|-------|
| `recommendations_api.dart` | Pozivi `/api/Recommendation/*` |
| `recommended_product.dart` | Parsiranje `RecommendedProductDto` |
| `recommendations_provider.dart` | Riverpod state |
| `recommendations_screen.dart` (mobile) | Ekran „Za vas“ sa score i reason |
| `home_screen.dart` (desktop) | Sekcija „For You“ sa objašnjenjem preporuke |

## Response model (`RecommendedProductDto`)

```json
{
  "productId": 15,
  "productName": "Elegantna torba Classic",
  "productType": "Bag",
  "description": "Ručno rađena kožna torba...",
  "price": 89.99,
  "image": "...",
  "score": 22.5,
  "reason": "Tip \"Clutch\" iz vaših omiljenih; Cijena blizu vašeg uobičajenog raspona; Visoka prosječna ocjena (4.6)",
  "isPersonalized": true
}
```

## Konstante algoritma (u kodu)

Definisane u `RecommendationService.cs`:

```csharp
FavoriteTypeWeight = 3.0
RatedTypeWeight = 2.0
PurchasedTypeWeight = 1.0
TypeMatchMultiplier = 5.0
MaxPriceSimilarityBonus = 5.0
PopularityPurchaseMultiplier = 0.5
PopularityRatingMultiplier = 2.0
MinRatingForBonus = 3.5
```

## Dijagram toka

```
JWT UserID
    │
    ▼
BuildUserProfileAsync (favoriti + ocjene + kupnje)
    │
    ├─ Nema tipova u profilu ──► GetPopularFallbackAsync
    │
    ▼
Filtriraj kandidate (tip + isključi kupljene/favorite)
    │
    ├─ Nema kandidata ──► GetPopularFallbackAsync
    │
    ▼
ComputeScore za svakog kandidata
    │
    ▼
Sortiraj po Score ↓, ProductId ↑
    │
    ▼
RecommendedProductDto (Score, Reason, IsPersonalized)
```
