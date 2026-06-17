# CSB Webshop — Seminarski rad

Webshop aplikacija za Coco Sun Bags — ASP.NET Core API, RabbitMQ email servis, Flutter (mobile + desktop).

## Arhitektura

| Komponenta | Opis |
|------------|------|
| `CSBWebshopSeminarski` | REST API (ASP.NET Core 8) |
| `CSBWebshopSeminarski.Notifications` | RabbitMQ worker (email) |
| `csb_webshop_mobile` | Flutter mobilna aplikacija |
| `csb_webshop_desktop` | Flutter desktop aplikacija |

## Preduvjeti

- Docker & Docker Compose
- .NET 8 SDK
- Flutter SDK
- Android Studio (AVD emulator) — za mobilnu verziju
- SQL Server / LocalDB — za lokalni razvoj bez Dockera

## Pokretanje s Dockerom (preporučeno)

1. Kloniraj repozitorij
2. U folderu `CSBWebshopSeminarski`:
   - raspakiraj `.env-tajne.zip` (šifra: **fit**)
   - ako Windows Explorer ne uspije, koristi **7-Zip** (desni klik → 7-Zip → Extract) ili raspakiraj u `C:\Temp` pa kopiraj `.env`
   - postavi `.env` u isti folder gdje je `docker-compose.yml`
3. Pokreni:

```bash
cd CSBWebshopSeminarski
docker compose up --build
```

| Servis | URL |
|--------|-----|
| API | http://localhost:8080 |
| Swagger | http://localhost:8080/swagger |
| RabbitMQ management | http://localhost:15672 |

## Lokalni razvoj (bez Dockera)

Raspakiraj `.env-tajne.zip` (šifra: **fit**) i postavi varijable iz `.env` fajla kao environment varijable prije `dotnet run`. Vidi [Konfiguracija i tajne](#konfiguracija-i-tajne).

### API

```powershell
cd CSBWebshopSeminarski\CSBWebshopSeminarski
# Ucitaj tajne iz .env (vidi .env-tajne.zip) npr.:
# $env:JWTSettings__Key = "..."
# $env:Smtp__User = "..."
# $env:Stripe__SecretKey = "..."
dotnet run --urls "http://localhost:5265"
```

### Notifications (email worker)

```powershell
cd CSBWebshopSeminarski\CSBWebshopSeminarski.Notifications
# Ucitaj SMTP i RabbitMQ varijable iz .env-tajne.zip
dotnet run
```
### Desktop (Flutter)

```bash
cd csb_webshop_desktop
flutter run -d windows --dart-define=baseUrl=http://localhost:8080/api
```

### Mobile (Flutter) — Android emulator

```bash
cd csb_webshop_mobile
flutter run --dart-define=baseUrl=http://10.0.2.2:8080/api
```

## Login podaci (seed)

| Uloga | Korisničko ime | Lozinka |
|-------|----------------|---------|
| Admin | admin | Admin123! |
| Buyer | buyer | Buyer123! |

## Stripe test kartica

- Broj: **4242 4242 4242 4242**
- Datum isteka: bilo koji budući (npr. 12/34)
- CVC: bilo koja 3 broja

## Konfiguracija i tajne

Tajne (JWT, SMTP, RabbitMQ, Stripe, SQL lozinka) **nisu** u `appsettings.json` — polja su prazna (`""`). Stvarne vrijednosti nalaze se u **`.env-tajne.zip`**.

**Šifra za raspakiranje: `fit`**

Na DL sistem postavi lozinku **fit** u zadatke.

Detaljnije Docker upute: [CSBWebshopSeminarski/README.docker.md](CSBWebshopSeminarski/README.docker.md)
