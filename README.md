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

### Desktop user (Windows)
- Prijava:
  - username: admin
  - password: Admin123!
 
- Prijava:
  - username: buyer
  - password: Buyer123!
- Pokretanje aplikacije:

```bash
If you want to start desktop application using dart define
flutter run --dart-define=baseUrl=http://10.0.2.2:8080/api -d windows
```

### Mobilni klijent (Android Emulator)
- Prijava:
  - username: buyer
  - password: Buyer123!
 
- Prijava:
  - username: admin
  - password: Admin123!
- Pokretanje aplikacije:

```bash
cd csb_webshop_mobile
flutter pub get
flutter emulators --launch Medium_Phone_API_36.1
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5265
```

### Testna kreditna kartica (Stripe Test mode)
- Broj kartice: **4242 4242 4242 4242**
- Datum isteka: bilo koji budući datum (npr. 12/34)
- CVC: bilo koje 3 cifre
