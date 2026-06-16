namespace CBSWebshopSeminarski.Model
{
    /// <summary>
    /// Poruke validacije usklađene s <c>csb_webshop_shared/form_validators.dart</c>.
    /// </summary>
    public static class ValidationMessages
    {
        // Auth / korisnik
        public const string NameRequired = "Ime je obavezno";
        public const string NameMinLength = "Ime mora imati najmanje 2 znaka";
        public const string SurnameRequired = "Prezime je obavezno";
        public const string SurnameMinLength = "Prezime mora imati najmanje 2 znaka";
        public const string EmailRequired = "Email je obavezan";
        public const string EmailInvalid = "Unesite ispravnu email adresu";
        public const string UsernameRequired = "Korisničko ime je obavezno";
        public const string UsernameMinLength = "Korisničko ime mora imati najmanje 3 znaka";
        public const string PasswordRequired = "Lozinka je obavezna";
        public const string PasswordMinLength = "Lozinka mora imati najmanje 6 znakova";
        public const string PasswordConfirmRequired = "Potvrda lozinke je obavezna";
        public const string PasswordsDoNotMatch = "Lozinke se ne podudaraju";
        public const string ResetCodeRequired = "Reset kod je obavezan";
        public const string ResetCodeFormat = "Reset kod mora imati točno 6 brojeva";
        public const string NewPasswordRequired = "Nova lozinka je obavezna";

        // Proizvodi
        public const string ProductNameRequired = "Naziv je obavezan";
        public const string ProductNameMinLength = "Naziv mora imati najmanje 2 znaka";
        public const string ProductNameMaxLength = "Naziv može imati najviše 200 znakova";
        public const string ProductCodeRequired = "Šifra je obavezna";
        public const string ProductCodeMaxLength = "Šifra može imati najviše 50 znakova";
        public const string PriceRequired = "Cijena je obavezna";
        public const string PriceGreaterThanZero = "Cijena mora biti veća od 0";
        public const string DescriptionMaxLength = "Opis može imati najviše 2000 znakova";
        public const string BagTypeNameRequired = "Naziv tipa torbe je obavezan";
        public const string BagTypeNameMinLength = "Naziv tipa torbe mora imati najmanje 2 znaka";
        public const string BagTypeNameMaxLength = "Naziv tipa torbe može imati najviše 100 znakova";
        public const string BeltTypeNameRequired = "Naziv tipa kaiša je obavezan";
        public const string BeltTypeNameMinLength = "Naziv tipa kaiša mora imati najmanje 2 znaka";
        public const string BeltTypeNameMaxLength = "Naziv tipa kaiša može imati najviše 100 znakova";

        // Recenzije / ocjene
        public const string CommentRequired = "Komentar je obavezan";
        public const string CommentMinLength = "Komentar mora imati najmanje 3 znaka";
        public const string CommentMaxLength = "Komentar može imati najviše 1000 znakova";
        public const string RatingRequired = "Ocjena je obavezna";
        public const string RatingRange = "Ocjena mora biti između 1 i 5";

        // Narudžbe / korpa
        public const string OrderIdRequired = "ID narudžbe je obavezan";
        public const string OrderIdValid = "ID narudžbe mora biti valjan";
        public const string OrderNumberMaxLength = "Broj narudžbe može imati najviše 50 znakova";
        public const string QuantityRequired = "Količina je obavezna";
        public const string QuantityMin = "Količina mora biti cijeli broj veći od 0";
        public const string DiscountRange = "Popust mora biti između 0 i 100";
        public const string UserIdRequired = "ID korisnika je obavezan";
        public const string UserIdValid = "ID korisnika mora biti valjan";

        // Plaćanje
        public const string SessionIdRequired = "Session ID je obavezan";
        public const string SessionIdNotEmpty = "Session ID ne smije biti prazan";
        public const string PaymentIntentIdRequired = "Payment intent ID je obavezan";
        public const string PaymentIntentIdNotEmpty = "Payment intent ID ne smije biti prazan";
        public const string OrderIdValidWhenProvided = "ID narudžbe mora biti valjan kada je naveden";

        // Giveaway / vijesti / lookbook
        public const string TitleRequired = "Naslov je obavezan";
        public const string TitleMinLength = "Naslov mora imati najmanje 2 znaka";
        public const string TitleMaxLength = "Naslov može imati najviše 200 znakova";
        public const string StartDateRequired = "Datum početka je obavezan";
        public const string EndDateRequired = "Datum kraja je obavezan";
        public const string ParticipantNameMinLength = "Ime mora imati najmanje 2 znaka";
        public const string ParticipantNameMaxLength = "Ime može imati najviše 100 znakova";
        public const string MessageContentRequired = "Sadržaj poruke je obavezan";
        public const string MessageContentMinLength = "Sadržaj poruke mora imati najmanje 10 znakova";
        public const string BodyMinLength = "Tekst ne smije biti prazan";
        public const string BodyMaxLength = "Tekst može imati najviše 10000 znakova";
        public const string CaptionMaxLength500 = "Opis može imati najviše 500 znakova";
        public const string TagsMaxLength = "Oznake mogu imati najviše 300 znakova";
        public const string DisplayOrderPositive = "Redoslijed mora biti pozitivan broj";

        // Outfit ideje / slike
        public const string OutfitIdeaIdValid = "ID outfit ideje mora biti valjan";
        public const string ImageRequired = "Slika je obavezna";
        public const string ImageDataNotEmpty = "Podaci slike ne smiju biti prazni";
        public const string DisplayOrderNonNegative = "Redoslijed prikaza mora biti nula ili veći";
        public const string DescriptionMaxLength1000 = "Opis može imati najviše 1000 znakova";

        // Dostava
        public const string CarrierCodeMaxLength = "Kod kurira može imati najviše 50 znakova";
        public const string TrackingNumberRequired = "Broj za praćenje je obavezan";
        public const string TrackingNumberMinLength = "Broj za praćenje mora imati najmanje 3 znaka";
        public const string TrackingNumberMaxLength = "Broj za praćenje može imati najviše 100 znakova";
        public const string StatusRequired = "Status je obavezan";
        public const string MessageMaxLength = "Poruka može imati najviše 500 znakova";
        public const string LocationMaxLength = "Lokacija može imati najviše 200 znakova";

        // Admin / pretraga / paginacija
        public const string PageMin = "Stranica mora biti najmanje 1";
        public const string PageSizeRange = "Veličina stranice mora biti između 1 i 100";
        public const string UsernameFilterMaxLength = "Filter korisničkog imena može imati najviše 100 znakova";
        public const string OrderNumberFilterMaxLength = "Filter broja narudžbe može imati najviše 100 znakova";
        public const string BagTypeNameFilterMaxLength = "Filter naziva tipa torbe može imati najviše 200 znakova";
        public const string BeltTypeNameFilterMaxLength = "Filter naziva tipa kaiša može imati najviše 200 znakova";
        public const string BeltNameFilterMaxLength = "Filter naziva kaiša može imati najviše 200 znakova";
        public const string TagFilterMaxLength = "Filter oznake može imati najviše 100 znakova";
        public const string TitleFilterMaxLength = "Filter naslova može imati najviše 200 znakova";
        public const string CommentFilterMaxLength = "Filter komentara može imati najviše 500 znakova";
        public const string GiveawayStatusFilterMaxLength = "Filter statusa može imati najviše 20 znakova";
        public const string GiveawayStatusFilterValues = "Status mora biti active, closed ili all";

        // Purchase / transaction (admin)
        public const string PurchaseIdValid = "ID kupovine mora biti valjan";
        public const string PurchaseDateRequired = "Datum kupovine je obavezan";
        public const string OrderNumberRequired = "Broj narudžbe je obavezan";
        public const string StripeIdRequired = "Stripe ID je obavezan";
        public const string TransactionDateRequired = "Datum transakcije je obavezan";

        // Carrier webhook
        public const string OrderIdPositiveWhenProvided = "OrderID mora biti pozitivan cijeli broj kada je naveden";
        public const string StatusMaxLength64 = "Status može imati najviše 64 znaka";
        public const string RawJsonMaxLength = "RawJson može imati najviše 10000 znakova";
        public const string ReportsTakeRange = "Take mora biti između 1 i 10000 kada je naveden";
        public const string BagNameFilterMaxLength = "Filter naziva torbe može imati najviše 200 znakova";
    }
}
