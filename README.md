# SeminarskiCSBWebshop

## CSB Webshop — Pokretanje aplikacije

### Docker (backend/infrastruktura)
U direktoriju gdje se nalazi projekat pokrenite sljedece naredbe:

```bash
docker-compose build
docker-compose up
```

### Desktop user (Windows)
- Prijava:
  - username: admin
  - password: Admin123!
 
- Prijava:
  - username: buyer
  - password: Buyer123!
- Pokretanje aplikacije:

If you want to start desktop application using dart define
flutter run --dart-define=baseUrl=http://10.0.2.2:8080/api -d windows

### Mobilni klijent (Android Emulator)
- Prijava:
  - username: buyer
  - password: Buyer123!
 
- Prijava:
  - username: admin
  - password: Admin123!
 
  These are default mobile users. You can create your own by clicking register button.
- Pokretanje aplikacije:

```bash
flutter pub get
flutter emulators --launch Medium_Phone_API_36.1
flutter run
```
If you want to start application using dart define
flutter run --dart-define=baseUrl=http://10.0.2.2:8080/api

### Testna kreditna kartica (Stripe Test mode)
- Broj kartice: **4242 4242 4242 4242**
- Datum isteka: bilo koji budući datum (npr. 12/34)
- CVC: bilo koje 3 cifre
