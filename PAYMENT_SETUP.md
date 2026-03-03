# Konfiguracija plaćanja (Stripe)

Ovaj vodič objašnjava kako konfigurirati Stripe plaćanje za CSB Webshop.

## 1. Stripe nalog i API ključevi

1. Registruj se na [Stripe](https://dashboard.stripe.com/register) (besplatno za testiranje).
2. U Stripe Dashboard → **Developers** → **API keys** uzmi:
   - **Publishable key** (počinje sa `pk_test_...` za test)
   - **Secret key** (počinje sa `sk_test_...` za test)

## 2. Backend (ASP.NET Core API)

### Opcija A: appsettings.Development.json (za lokalni razvoj)

Otvorite `CSBWebshopSeminarski/appsettings.Development.json` i unesite svoje ključeve:

```json
{
  "Stripe": {
    "SecretKey": "sk_test_VASA_STRIPE_SECRET_KEY",
    "WebhookSecret": "whsec_VAS_WEBHOOK_SECRET",
    "PublishableKey": "pk_test_VASA_STRIPE_PUBLISHABLE_KEY"
  }
}
```

**⚠️ Napomena:** Ne commit-ujte stvarne ključeve u git. Za produkciju koristite User Secrets ili environment varijable.

### Opcija B: User Secrets (preporučeno za razvoj)

```powershell
cd CSBWebshopSeminarski
dotnet user-secrets set "Stripe:SecretKey" "sk_test_VASA_Tajni_KLJUC"
dotnet user-secrets set "Stripe:WebhookSecret" "whsec_VAS_WEBHOOK_SECRET"
```

### Webhook konfiguracija

Za primanje Stripe webhook eventa (`payment_intent.succeeded`, `payment_intent.payment_failed`) u razvoju:

1. Instaliraj [Stripe CLI](https://stripe.com/docs/stripe-cli).
2. Pokreni webhook forwarding:
   ```bash
   stripe listen --forward-to https://localhost:7224/api/webhooks/stripe
   ```
   (Prilagodite port ako API radi na drugom portu.)
3. Stripe CLI će ispisati webhook signing secret (`whsec_...`). Taj secret postavite u `Stripe:WebhookSecret`.

## 3. Flutter aplikacija (Desktop / Mobile)

### Desktop (`csb_webshop_desktop`)

Stripe publishable ključ se postavlja preko environment varijable ili `run_with_stripe.ps1` skripte:

```powershell
# Opcija 1: Skripta run_with_stripe.ps1 (u csb_webshop_desktop/)
$env:STRIPE_PUBLISHABLE_KEY="pk_test_VASA_PUBLISHABLE_KEY"
.\run_with_stripe.ps1

# Opcija 2: Environment varijabla
$env:STRIPE_PUBLISHABLE_KEY="pk_test_VASA_PUBLISHABLE_KEY"
flutter run -d windows

# Opcija 3: Direktno pri pokretanju
flutter run -d windows --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_VASA_PUBLISHABLE_KEY
```

### Mobile (`csb_webshop_mobile`)

```powershell
flutter run --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_VASA_PUBLISHABLE_KEY
```

### Alternativa: environment.dart

Ako želite hardkodirati za lokalni razvoj (samo test ključ, ne commit-ujte u produkciju), u `lib/environment.dart` možete privremeno postaviti:

```dart
static const String stripePublishableKey = 'pk_test_VASA_PUBLISHABLE_KEY';
```

## 4. Test kartice (Stripe Test mode)

U Stripe Dashboard → Developers → Testing koristite test kartice, npr.:

| Broj kartice | Rezultat |
|--------------|----------|
| 4242 4242 4242 4242 | Uspješno plaćanje |
| 4000 0000 0000 0002 | Odbijeno (decline) |
| 4000 0025 0000 3155 | Zahtijeva 3D Secure |

- **Datum:** bilo koji budući datum
- **CVC:** bilo koje 3 cifre
- **ZIP:** bilo koja 5-cifrena vrijednost

## 5. Tok plaćanja

1. Buyer dodaje proizvode u korpu.
2. Na ekranu plaćanja unosi adresu dostave i email.
3. Klik na „Platiti“ pokreće Stripe Payment Sheet.
4. Buyer unosi podatke kartice u Stripe modal.
5. Stripe obrađuje plaćanje.
6. Klijent ažurira status narudžbe na „Paid“.
7. Stripe webhook šalje potvrdu na backend → kreira se Purchase.

## 6. Provjera da li radi

1. Pokrenite API (`CSBWebshopSeminarski` projekt).
2. Pokrenite Flutter desktop app sa `STRIPE_PUBLISHABLE_KEY`.
3. Ulogujte se kao Buyer.
4. Dodajte proizvod u korpu i idite na plaćanje.
5. Koristite test karticu `4242 4242 4242 4242`.
6. Nakon uspješnog plaćanja trebate biti preusmjereni na `/checkout/success`.
