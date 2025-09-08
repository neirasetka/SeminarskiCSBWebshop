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
cd csb_webshop_mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:7015/api/ -d windows
```

### Mobilni klijent (Android Emulator)
- Prijava:
  - username: customer
  - password: Customer123!
- Pokretanje aplikacije:

```bash
cd csb_webshop_mobile
flutter pub get
flutter emulators --launch "Pixel 2 API 35"
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:7015/api/
```

### Testna kreditna kartica
- Broj kartice: 5555 5555 5555 4444
