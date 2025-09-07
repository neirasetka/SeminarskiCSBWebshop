# SeminarskiCSBWebshop

## FurnitureStore — Pokretanje aplikacije

### Docker (backend/infrastruktura)
U direktoriju gdje se nalazi projekat pokrenite sljedeće naredbe:

```bash
docker-compose build
docker-compose up
```

### Desktop klijent (Windows)
- Prijava:
  - username: admin
  - password: Admin123!
- Pokretanje aplikacije:

```bash
cd csb_webshop_app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:7015/api/ -d windows
```

### Mobilni klijent (Android Emulator)
- Prijava:
  - username: customer
  - password: Customer123!
- Pokretanje aplikacije:

```bash
cd csb_webshop_app
flutter pub get
flutter emulators --launch "Pixel 2 API 35"
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:7015/api/
```

### Testna kreditna kartica
- Broj kartice: 5555 5555 5555 4444

## Stripe plaćanja (server-side)

### Konfiguracija okruženja
Dodajte u konfiguraciju (npr. `appsettings.json` ili varijable okruženja):

- `Stripe:SecretKey`: vaš Stripe secret key (npr. `sk_test_...`)
- `Stripe:WebhookSecret`: endpoint secret za Stripe webhook (preuzeti iz Stripe Dashboarda nakon kreiranja webhook endpointa)

API koristi ove vrijednosti u `Program.cs`:
- `StripeConfiguration.ApiKey = Configuration["Stripe:SecretKey"]`
- Verifikacija potpisa: `EventUtility.ConstructEvent(..., Stripe:WebhookSecret)`

### Endpointi
- Kreiranje PaymentIntent-a (za web/mob klijent):
  - `POST /api/payments/create-payment-intent`
  - Body: `{ "orderID": 123, "amountInCents": 0, "currency": "eur", "receiptEmail": "user@email.com" }`
  - Odgovor: `{ "clientSecret": "...", "paymentIntentId": "pi_..." }`

- Stripe Webhook (interni, ne koristi se iz klijenta):
  - `POST /api/webhooks/stripe`
  - Obrada događaja:
    - `payment_intent.succeeded`: kreira `Purchase` (idempotentno) i postavlja `Orders.PaymentStatus = Paid`
    - `payment_intent.payment_failed`: postavlja `Orders.PaymentStatus = Failed`

### Status narudžbe
- Entitet `Orders` ima polje `PaymentStatus` (enum: Pending, Paid, Failed, Refunded)
- Na modelu `Order` iz API-ja se izlaže kao string projekcija

### Testiranje lokalno
1) Pokrenite API (sa postavljenim `Stripe:SecretKey`):
   - `dotnet run` iz projekta `CSBWebshopSeminarski`

2) Pokrenite Stripe CLI i prosljeđivanje webhook-a:
   - Instalirajte Stripe CLI: `https://stripe.com/docs/stripe-cli`
   - Prijava: `stripe login`
   - Forward: `stripe listen --forward-to localhost:PORT/api/webhooks/stripe`
   - Kopirajte prikazani `webhook signing secret` i postavite kao `Stripe:WebhookSecret`

3) Kreirajte PaymentIntent sa klijenta ili cURL-om, npr.:
   - `curl -X POST http://localhost:PORT/api/payments/create-payment-intent -H "Content-Type: application/json" -H "Authorization: Bearer <JWT>" -d '{"orderID":123}'`

4) Potvrdite uplatu sa Stripe test karticom (preko frontenda ili Stripe dashboarda/CLI scenarija) i provjerite:
   - `Orders.PaymentStatus` = `Paid`
   - `Purchases` sadrži novi unos sa `StripeId = payment_intent.id`

### Napomene
- Webhook je izvor istine za finansijski status; ne oslanjati se na klijentske callback-e.
- Za web aplikaciju možete koristiti Stripe Elements (Checkout ili custom UI) uz `client_secret` iz PaymentIntent-a.
- Za mobilne aplikacije preporučen je Stripe PaymentSheet (koristeći isti `client_secret`).

## Flutter aplikacija (csb_webshop_app) — Testiranje

### Pokretanje testova
1) Pređite u direktorij projekta:
   - `cd csb_webshop_app`

2) Preuzmite zavisnosti:
   - `flutter pub get`

3) Pokrenite sve testove:
   - `flutter test`

4) Pokrenite jedan fajl testa (primjer):
   - `flutter test test/local_favorites_storage_test.dart`

### Šta je pokriveno
- Unit testovi:
  - `LocalFavoritesStorage` (čitanje/spremanje/toggle favorita preko `SharedPreferences` mocka)
  - `LocalCollectionsStorage` (dodavanje/uklanjanje, preimenovanje i brisanje kolekcija)
- Widget testovi:
  - `AnnouncementsListScreen` prazan state (`Nema obavijesti.`)
  - `AnnouncementsListScreen` sa mock podacima (render naslova)

Napomena: Testovi koriste `SharedPreferences.setMockInitialValues` i Riverpod override za API sloj, tako da ne rade stvarni IO/umrežavanje.

## Backend (.NET) — Testiranje

### Postavljanje i pokretanje
1) Instalirajte .NET 8 SDK.
2) Na nivou rješenja:
   - `cd CSBWebshopSeminarski`
   - `dotnet restore`
3) Pokretanje svih testova:
   - `dotnet test CSBWebshopSeminarski.sln`

### Šta je pokriveno
- `PaymentsService` unit testovi: idempotentna obrada Stripe payment-a i update statusa narudžbe.
- `ShipmentTrackingService` unit testovi: promjena statusa, dodavanje tracking event-ova i mapiranje eksternih statusa.
- `PaymentsController` negativan slučaj: 404 kada narudžba ne postoji za kreiranje PaymentIntent-a.

Napomena: Testovi koriste EF Core InMemory provider; nema spajanja na pravu bazu niti Stripe API.