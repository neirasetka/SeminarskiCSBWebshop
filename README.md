# SeminarskiCSBWebshop

## CSB Webshop — Pokretanje aplikacije

### Docker (backend/infrastruktura)
U direktoriju gdje se nalazi projekat pokrenite sljedece naredbe:

```bash
docker-compose build
docker-compose up
```

### Backend (ASP.NET Core API)
Preduslov: SQL Server (lokalni ili Express). Podesite connection string u
`CSBWebshopSeminarski/CSBWebshopSeminarski/appsettings.json` po potrebi.

```bash
cd CSBWebshopSeminarski
dotnet restore
dotnet run --project CSBWebshopSeminarski/CSBWebshopSeminarski.csproj
```

API ce biti dostupan na `http://localhost:5265` (Swagger: `/swagger`).

### Desktop klijent (Windows)
- Prijava:
  - username: admin
  - password: Admin123!
- Pokretanje aplikacije:

```bash
cd csb_webshop_desktop
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:5265 -d windows
```

### Mobilni klijent (Android Emulator)
- Prijava:
  - username: buyer
  - password: Buyer123!
- Pokretanje aplikacije:

```bash
cd csb_webshop_mobile
flutter pub get
flutter emulators --launch "Pixel 2 API 35"
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5265
```

### Testna kreditna kartica
- Broj kartice: 5555 5555 5555 4444
