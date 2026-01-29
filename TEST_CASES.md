# CSB Webshop - Comprehensive Test Cases

This document contains all test cases for the CSB Webshop application, covering Mobile App, Desktop App, and Backend API.

## Test Case Summary

| Component | Test File | Test Cases |
|-----------|-----------|------------|
| Mobile - Auth | `csb_webshop_mobile/test/auth/login_screen_test.dart` | 10 |
| Mobile - Auth | `csb_webshop_mobile/test/auth/register_screen_test.dart` | 14 |
| Mobile - Navigation | `csb_webshop_mobile/test/navigation/root_screen_test.dart` | 12 |
| Mobile - Bags | `csb_webshop_mobile/test/products/bags_test.dart` | 17 |
| Mobile - Belts | `csb_webshop_mobile/test/products/belts_test.dart` | 14 |
| Mobile - Cart/Checkout | `csb_webshop_mobile/test/orders/cart_checkout_test.dart` | 14 |
| Mobile - Giveaways | `csb_webshop_mobile/test/giveaways/giveaways_test.dart` | 20 |
| Mobile - Profile/Orders | `csb_webshop_mobile/test/profile/profile_orders_test.dart` | 25 |
| Desktop - Home | `csb_webshop_desktop/test/home_screen_test.dart` | 16 |
| Desktop - Giveaway | `csb_webshop_desktop/test/giveaway_admin_test.dart` | 10 |
| Backend API | `CSBWebshopSeminarski/CSBWebshopSeminarski.Tests/ApiTestCases.md` | 60+ |

**Total: 200+ Test Cases**

---

## MOBILE APP (csb_webshop_mobile)

### 1. Autentikacija (Authentication)

#### Login Screen Tests (`test/auth/login_screen_test.dart`)

| ID | Flow | Koraci | Očekivani rezultat |
|----|------|--------|-------------------|
| TC-AUTH-001 | Login screen display | Otvori login screen | Prikazuje forme za username i password |
| TC-AUTH-002 | Empty username validation | Ostavi username prazno, tap Login | Greška "Unesite korisničko ime" |
| TC-AUTH-003 | Empty password validation | Unesi username, ostavi password prazno | Greška "Unesite lozinku" |
| TC-AUTH-004 | Successful login | Unesi ispravne kredencijale | Uspješna prijava, redirect na home |
| TC-AUTH-005 | Invalid credentials | Unesi pogrešne kredencijale | SnackBar s greškom |
| TC-AUTH-006 | Password visibility toggle | Tap na ikonu oka | Password vidljiv/skriven |
| TC-AUTH-007 | Navigate to register | Tap "Registrirajte se" | Otvara register screen |
| TC-AUTH-008 | Loading indicator | Tap Login s ispravnim podacima | Prikazuje loading spinner |
| TC-AUTH-009 | Embedded mode | Login screen u embedded modu | Nema "Natrag" button |
| TC-AUTH-010 | Username trimming | Unesi username s razmacima | Razmaci se uklanjaju |

#### Register Screen Tests (`test/auth/register_screen_test.dart`)

| ID | Flow | Koraci | Očekivani rezultat |
|----|------|--------|-------------------|
| TC-REG-001 | Register screen display | Otvori register screen | Prikazuje sve forme (ime, prezime, email, phone, username, password) |
| TC-REG-002 | Empty first name validation | Ostavi ime prazno | Greška "Ime je obavezno" |
| TC-REG-003 | Empty last name validation | Unesi ime, ostavi prezime prazno | Greška "Prezime je obavezno" |
| TC-REG-004 | Invalid email format | Unesi neispravan email | Greška "Unesite ispravnu email adresu" |
| TC-REG-005 | Short username validation | Unesi username kraći od 3 znaka | Greška "Korisničko ime mora imati najmanje 3 znaka" |
| TC-REG-006 | Short password validation | Unesi password kraći od 6 znakova | Greška "Lozinka mora imati najmanje 6 znakova" |
| TC-REG-007 | Password mismatch | Unesi različite passworde | Greška "Lozinke se ne podudaraju" |
| TC-REG-008 | Successful registration | Unesi sve ispravne podatke | Uspješna registracija, redirect na login |
| TC-REG-009 | Registration error | API vraća grešku | SnackBar s greškom |
| TC-REG-010 | Password visibility toggle | Tap ikone oka | Password vidljiv/skriven |
| TC-REG-011 | Navigate to login | Tap "Prijavite se" | Otvara login screen |
| TC-REG-012 | Back button | Tap back arrow | Vraća na login |
| TC-REG-013 | Optional phone | Registracija bez telefona | Uspješna registracija |
| TC-REG-014 | Valid email formats | Testiraj razne email formate | Validni formati prihvaćeni |

---

### 2. Navigacija (Bottom Nav + Home Menu)

#### Root Screen Tests (`test/navigation/root_screen_test.dart`)

| ID | Flow | Koraci | Očekivani rezultat |
|----|------|--------|-------------------|
| TC-NAV-001 | Home menu buttons | Otvori početnu | Prikazuje 4 gumba: Torbice, Kaiševi, Giveaway, Lookbook |
| TC-NAV-002 | Bottom nav tabs | Pregledaj donju navigaciju | Prikazuje 5 tabova: Početna, Torbe, Kaiševi, Korpa, Profil |
| TC-NAV-003 | Torbe tab | Tap "Torbe" tab | Prikazuje Katalog torbi |
| TC-NAV-004 | Kaiševi tab | Tap "Kaiševi" tab | Prikazuje Katalog kaiševa |
| TC-NAV-005 | Korpa tab | Tap "Korpa" tab | Prikazuje cart screen |
| TC-NAV-006 | Profil tab | Tap "Profil" tab | Prikazuje profil screen |
| TC-NAV-007 | Cart header icon | Tap cart ikonu u headeru | Navigira na korpu |
| TC-NAV-008 | Torbice menu button | Tap "Torbice" na home | Navigira na bags list |
| TC-NAV-009 | Logo tap | Tap logo | Vraća na home |
| TC-NAV-010 | Tab highlight | Navigiraj na tab | Aktivan tab je highlightan |
| TC-NAV-011 | Page state preserved | Prebacuj između tabova | Stanje stranica sačuvano |
| TC-NAV-012 | Welcome message | Prijavljeni korisnik | Prikazuje "Dobro došli, [ime]!" |

---

### 3. Proizvodi - Torbice (Bags)

#### Bags Tests (`test/products/bags_test.dart`)

| ID | Flow | Koraci | Očekivani rezultat |
|----|------|--------|-------------------|
| TC-BAG-001 | Bags list display | Otvori katalog torbi | Lista svih torbi sa slikom, imenom, cijenom |
| TC-BAG-002 | Bag item details | Pregledaj bag item | Prikazuje ime, cijenu, opis |
| TC-BAG-003 | Search filter | Unesi query u search | Filtrira torbe po imenu |
| TC-BAG-004 | Type filter dropdown | Pregledaj filter | Dropdown sa tipovima torbi |
| TC-BAG-005 | Navigate to detail | Tap na torbu | Otvara detalje torbe |
| TC-BAG-006 | Toggle favorite | Tap heart ikonu | Srce crveno/prazno |
| TC-BAG-007 | Add to cart | Tap "Dodaj u korpu" | SnackBar "Dodano u korpu" |
| TC-BAG-008 | Rating display | Torba ima rating | Prikazuje zvjezdice i ocjenu |
| TC-BAG-009 | Pull to refresh | Povuci prema dolje | Lista se osvježava |
| TC-BAG-010 | Empty state | Nema rezultata | Poruka "Nema rezultata." |
| TC-BAG-011 | Detail screen info | Otvori detalje | Puni detalji: slika, ime, cijena, opis |
| TC-BAG-012 | Detail description | Detalji torbe | Prikazuje sekciju "Opis" |
| TC-BAG-013 | Add to cart from detail | Detalji → Dodaj u korpu | SnackBar potvrda |
| TC-BAG-014 | Favorite from detail | Detalji → Heart | Toggle favorita |
| TC-BAG-015 | Outfit Idea button | Detalji → Outfit Idea | Navigira na outfit idea screen |
| TC-BAG-016 | Rating on detail | Detalji s ratingom | Prikazuje rating |
| TC-BAG-017 | Code on detail | Detalji | Prikazuje šifru proizvoda |

---

### 4. Proizvodi - Kaiševi (Belts)

#### Belts Tests (`test/products/belts_test.dart`)

| ID | Flow | Koraci | Očekivani rezultat |
|----|------|--------|-------------------|
| TC-BELT-001 | Belts list display | Otvori katalog kaiševa | Lista svih kaiševa |
| TC-BELT-002 | Belt item details | Pregledaj belt item | Prikazuje ime i cijenu |
| TC-BELT-003 | Search filter | Unesi query u search | Filtrira kaiševe po imenu |
| TC-BELT-004 | Type filter dropdown | Pregledaj filter | Dropdown sa tipovima |
| TC-BELT-005 | Navigate to detail | Tap na kaiš | Otvara detalje kaiša |
| TC-BELT-006 | Add to cart | Tap "Dodaj u korpu" | SnackBar potvrda |
| TC-BELT-007 | Rating display | Kaiš ima rating | Prikazuje ocjenu |
| TC-BELT-008 | Pull to refresh | Povuci prema dolje | Lista se osvježava |
| TC-BELT-009 | Empty state | Nema rezultata | Poruka "Nema rezultata." |
| TC-BELT-010 | Detail screen info | Otvori detalje | Puni detalji kaiša |
| TC-BELT-011 | Detail description | Detalji kaiša | Prikazuje opis |
| TC-BELT-012 | Add to cart from detail | Detalji → Dodaj | SnackBar potvrda |
| TC-BELT-013 | Code on detail | Detalji | Prikazuje šifru |
| TC-BELT-014 | Rating on detail | Detalji s ratingom | Prikazuje rating |

---

### 5. Korpa i Checkout

#### Cart/Checkout Tests (`test/orders/cart_checkout_test.dart`)

| ID | Flow | Koraci | Očekivani rezultat |
|----|------|--------|-------------------|
| TC-CART-001 | Empty cart | Otvori korpu bez stavki | Poruka "Korpa je prazna." |
| TC-CART-002 | Cart with items | Dodaj proizvode → Korpa | Lista stavki |
| TC-CART-003 | Item quantities | Stavka s količinom | Prikazuje "Količina: X" |
| TC-CART-004 | Total amount | Više stavki | Prikazuje ukupan iznos |
| TC-CART-005 | Checkout button | Korpa sa stavkama | "Nastavi na plaćanje" navigira na checkout |
| TC-CART-006 | Cart title | Otvori korpu | AppBar prikazuje "Korpa" |
| TC-CART-007 | Item prices | Stavke u korpi | Prikazuje cijene |
| TC-CART-008 | Empty cart no checkout | Prazna korpa | Nema checkout button |
| TC-CART-009 | Line total calculation | Količina × cijena | Ispravno izračunato |
| TC-CHECKOUT-001 | Success screen | Nakon plaćanja | Prikazuje potvrdu narudžbe |
| TC-CHECKOUT-002 | Return home button | Success screen | Button za povratak na home |
| TC-CHECKOUT-003 | Full checkout flow | Dodaj → Korpa → Plati | Kompletan flow uspješan |
| TC-CHECKOUT-004 | Multiple item types | Torba + kaiš u korpi | Obje stavke prikazane |
| TC-CHECKOUT-005 | Payment icon | Checkout button | Prikazuje payment ikonu |

---

### 6. Narudžbe (Orders)

#### Profile/Orders Tests (`test/profile/profile_orders_test.dart`)

| ID | Flow | Koraci | Očekivani rezultat |
|----|------|--------|-------------------|
| TC-ORDERS-001 | Order history list | Moje narudžbe | Lista svih narudžbi |
| TC-ORDERS-002 | Order amount | Pregledaj narudžbu | Prikazuje iznos |
| TC-ORDERS-003 | Payment status | Pregledaj narudžbu | Prikazuje status plaćanja |
| TC-ORDERS-004 | Shipping status | Pregledaj narudžbu | Prikazuje status dostave |
| TC-ORDERS-005 | Order detail | Tap na narudžbu | Detalji sa statusom |
| TC-ORDERS-006 | Empty orders | Nema narudžbi | Poruka "Nemate narudžbi." |
| TC-ORDERS-007 | Order number | Detalji narudžbe | Prikazuje broj narudžbe |
| TC-ORDERS-008 | Order items | Detalji narudžbe | Lista stavki |
| TC-ORDERS-009 | Order total | Detalji narudžbe | Ukupan iznos |
| TC-ORDERS-010 | Shipping timeline | Detalji narudžbe | Vizualni prikaz statusa |

---

### 7. Profil

| ID | Flow | Koraci | Očekivani rezultat |
|----|------|--------|-------------------|
| TC-PROFILE-001 | Profile display | Otvori profil | Prikazuje ime, prezime, username |
| TC-PROFILE-002 | Email display | Profil | Prikazuje email |
| TC-PROFILE-003 | Phone display | Profil (ima telefon) | Prikazuje telefon |
| TC-PROFILE-004 | Orders button | Profil | "Moje narudžbe" link |
| TC-PROFILE-005 | Avatar initials | Nema avatar slike | Prikazuje inicijale |
| TC-PROFILE-006 | Edit FAB | Profil | Floating button "Uredi profil" |
| TC-PROFILE-007 | Refresh button | Profil AppBar | Ikona za refresh |
| TC-PROFILE-008 | Logout button | Profil AppBar | Ikona za odjavu |
| TC-PROFILE-009 | Contact info card | Profil | "Kontakt informacije" kartica |
| TC-PROFILE-010 | Quick actions | Profil | "Brze akcije" kartica |
| TC-PROFILE-011 | Update screen data | Uredi profil | Pre-filled podaci |
| TC-PROFILE-012 | Save button | Uredi profil | "Sačuvaj" button |
| TC-PROFILE-013 | Edit first name | Uredi profil | Ime se može promijeniti |
| TC-PROFILE-014 | Edit last name | Uredi profil | Prezime se može promijeniti |
| TC-PROFILE-015 | Edit phone | Uredi profil | Telefon se može promijeniti |

---

### 8. Giveaway

#### Giveaways Tests (`test/giveaways/giveaways_test.dart`)

| ID | Flow | Koraci | Očekivani rezultat |
|----|------|--------|-------------------|
| TC-GIVEAWAY-001 | Giveaways list | Home → Giveaway | Lista svih giveawaya |
| TC-GIVEAWAY-002 | Active chip | Aktivan giveaway | Chip "Aktivan" |
| TC-GIVEAWAY-003 | Closed chip | Završen giveaway | Chip "Zatvoren" |
| TC-GIVEAWAY-004 | Filter chips | Lista | "Aktivni" i "Završeni" chipovi |
| TC-GIVEAWAY-005 | Show all | Tap "Svi" | Svi giveawayi vidljivi |
| TC-GIVEAWAY-006 | Navigate to detail | Tap na giveaway | Detalji giveawaya |
| TC-GIVEAWAY-007 | Admin create button | Admin view | "Kreiraj" button |
| TC-GIVEAWAY-008 | Planned status | Budući giveaway | Status "Planiran" |
| TC-GIVEAWAY-009 | Detail title | Detalji | Naslov giveawaya |
| TC-GIVEAWAY-010 | Date range | Detalji | Datumi start/end |
| TC-GIVEAWAY-011 | Status chip | Detalji | Status chip |
| TC-GIVEAWAY-012 | Registration form | Aktivan giveaway | Forma za prijavu |
| TC-GIVEAWAY-013 | Email validation | Prijava | "Email je obavezan" |
| TC-GIVEAWAY-014 | Invalid email | Neispravan email | "Unesite ispravan email" |
| TC-GIVEAWAY-015 | Successful registration | Ispravni podaci | SnackBar "Prijava uspješna" |
| TC-GIVEAWAY-016 | Optional name | Prijava bez imena | Uspješno |
| TC-GIVEAWAY-017 | Admin actions | Admin detalji | Izvuci/Objavi/Email buttons |
| TC-GIVEAWAY-018 | Draw disabled for open | Aktivan giveaway | Izvuci button enabled |
| TC-GIVEAWAY-019 | Participants list | Admin view | Lista prijavljenih |
| TC-GIVEAWAY-020 | Create form validation | Kreiraj giveaway | Naslov obavezan |

---

## DESKTOP APP (csb_webshop_desktop)

### Home Screen Tests (`test/home_screen_test.dart`)

| ID | Flow | Koraci | Očekivani rezultat |
|----|------|--------|-------------------|
| TC-DESKTOP-001 | Welcome message | Home | "Dobro došli" |
| TC-DESKTOP-002 | Navigation shortcuts | Home | Bags, Torbice, Belts, Kaisevi, Lookbook, Giveaway, Korpa |
| TC-DESKTOP-003 | Bags shortcut | Click Bags | Bags screen |
| TC-DESKTOP-004 | Torbice shortcut | Click Torbice | Torbice shop |
| TC-DESKTOP-005 | Belts shortcut | Click Belts | Belts screen |
| TC-DESKTOP-006 | Kaisevi shortcut | Click Kaisevi | Kaisevi shop |
| TC-DESKTOP-007 | Lookbook shortcut | Click Lookbook | Lookbook screen |
| TC-DESKTOP-008 | Giveaway shortcut | Click Giveaway | Giveaways screen |
| TC-DESKTOP-009 | Korpa shortcut | Click Korpa | Checkout screen |
| TC-DESKTOP-010 | For You section | Logged in | "For You" sekcija |
| TC-DESKTOP-011 | Recommendations subtitle | For You | "recommended" tekst |
| TC-DESKTOP-012 | Refresh button | For You | Refresh ikona |
| TC-DESKTOP-013 | Empty recommendations | No favorites | "No recommendations" message |
| TC-DESKTOP-014 | Browse buttons | Empty state | "Browse Bags" i "Browse Belts" |
| TC-DESKTOP-015 | Recommended Bags section | Has data | "Recommended Bags" |
| TC-DESKTOP-016 | Recommended Belts section | Has data | "Recommended Belts" |

### Giveaway Admin Tests (`test/giveaway_admin_test.dart`)

| ID | Flow | Koraci | Očekivani rezultat |
|----|------|--------|-------------------|
| TC-DESKTOP-GIVE-001 | List display | Giveaways | Svi giveawayi |
| TC-DESKTOP-GIVE-002 | Status chips | Lista | Chipovi statusa |
| TC-DESKTOP-GIVE-003 | Filter chips | Lista | Filter chipovi |
| TC-DESKTOP-GIVE-004 | Register form | Register screen | Form fields |
| TC-DESKTOP-GIVE-005 | Submit button | Register | ElevatedButton |
| TC-DESKTOP-GIVE-006 | Email validation | Register → Submit | Validacija |
| TC-DESKTOP-GIVE-007 | Admin create | Admin role | Create button |
| TC-DESKTOP-GIVE-008 | Draw winner | Admin closed | Draw function |
| TC-DESKTOP-GIVE-009 | Announce winner | Admin with winner | Announce function |
| TC-DESKTOP-GIVE-010 | Notify winner | Admin with winner | Email function |

---

## BACKEND API

See detailed test cases in `CSBWebshopSeminarski/CSBWebshopSeminarski.Tests/ApiTestCases.md`

### Summary of API Test Categories:
- **Authentication**: 14 test cases
- **Bags**: 21 test cases
- **Belts**: 8 test cases  
- **Orders**: 11 test cases
- **Giveaways**: 20 test cases
- **Recommendations**: 4 test cases
- **RabbitMQ Events**: 4 test cases

---

## Running Tests

### Mobile App Tests
```bash
cd csb_webshop_mobile
flutter test
```

### Desktop App Tests
```bash
cd csb_webshop_desktop
flutter test
```

### Backend API Tests
Use Postman, curl, or integration test framework with the test cases defined in `ApiTestCases.md`.

---

## Test Coverage Goals

- **Unit Tests**: 80%+ coverage
- **Widget Tests**: All screens and major components
- **Integration Tests**: Critical user flows
- **API Tests**: All endpoints with success and error cases
