/// Zajednički validatori usklađeni s backend DataAnnotations pravilima.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';



class FormValidators {

  FormValidators._();



  /// Backend: `ValidationPatterns.Phone`

  static final RegExp optionalPhoneRegex = RegExp(r'^\d{9}$');

  static const int phoneDigitCount = 9;

  static const String phoneValidationMessage =
      'Unesite ispravan broj telefona (9 brojeva)';

  static List<TextInputFormatter> get phoneInputFormatters => <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(phoneDigitCount),
      ];



  static final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');



  static String? required(String? value, {required String fieldName}) {

    if (value == null || value.trim().isEmpty) {

      return '$fieldName je obavezno';

    }

    return null;

  }



  static String? minLength(

    String? value,

    int min, {

    required String fieldName,

  }) {

    final String? requiredError = required(value, fieldName: fieldName);

    if (requiredError != null) return requiredError;

    if (value!.trim().length < min) {

      return '$fieldName mora imati najmanje $min znaka';

    }

    return null;

  }



  static String? email(String? value) {

    final String? requiredError = required(value, fieldName: 'Email');

    if (requiredError != null) return requiredError;

    if (!emailRegex.hasMatch(value!.trim())) {

      return 'Unesite ispravnu email adresu';

    }

    return null;

  }



  /// Opcionalni telefon — prazno je dopušteno; inače mora odgovarati backend regexu.

  static String? optionalPhone(String? value) {

    if (value == null || value.trim().isEmpty) return null;

    if (!optionalPhoneRegex.hasMatch(value.trim())) {

      return phoneValidationMessage;

    }

    return null;

  }



  /// Obavezni telefon za dostavu/plaćanje — isti format kao backend.

  static String? requiredPhone(String? value) {

    final String? requiredError = required(value, fieldName: 'Broj telefona');

    if (requiredError != null) return requiredError;

    if (!optionalPhoneRegex.hasMatch(value!.trim())) {

      return phoneValidationMessage;

    }

    return null;

  }



  static String? price(String? value) {

    final String? requiredError = required(value, fieldName: 'Cijena');

    if (requiredError != null) return requiredError;

    final String normalized = value!.replaceAll(',', '.').trim();

    final double? parsed = double.tryParse(normalized);

    if (parsed == null) return 'Unesite ispravan broj';

    if (parsed <= 0) return 'Cijena mora biti veća od 0';

    final List<String> parts = normalized.split('.');

    if (parts.length > 2) {

      return 'Cijena mora biti u formatu xx.yy (maks. 2 decimale)';

    }

    if (parts.length == 2 && parts[1].length > 2) {

      return 'Cijena mora biti u formatu xx.yy (maks. 2 decimale)';

    }

    return null;

  }



  static String? password(String? value) {

    final String? requiredError = required(value, fieldName: 'Lozinka');

    if (requiredError != null) return requiredError;

    if (value!.length < 6) {

      return 'Lozinka mora imati najmanje 6 znakova';

    }

    return null;

  }



  static String? passwordConfirm(String? value, String password) {

    final String? requiredError = required(value, fieldName: 'Potvrda lozinke');

    if (requiredError != null) return requiredError;

    if (value != password) {

      return 'Lozinke se ne podudaraju';

    }

    return null;

  }



  static String? username(String? value) {

    return minLength(value, 3, fieldName: 'Korisničko ime');

  }



  /// BagUpsertRequest / BeltUpsertRequest — naziv proizvoda.

  static String? productName(String? value) {

    return minLength(value, 2, fieldName: 'Naziv');

  }



  /// BagUpsertRequest / BeltUpsertRequest — šifra proizvoda.

  static String? productCode(String? value) {

    return required(value, fieldName: 'Šifra');

  }



  /// BagTypeUpsertRequest / BeltTypeUpsertRequest — novi tip bez duplikata.

  static String? uniqueTypeName(

    String? value, {

    required Iterable<String> existingNames,

    String? currentName,

  }) {

    final String? nameError = required(value, fieldName: 'Naziv');

    if (nameError != null) return nameError;

    final String normalized = value!.trim().toLowerCase();

    final String? current = currentName?.trim().toLowerCase();

    if (current != null && normalized == current) return null;

    for (final String existing in existingNames) {

      if (existing.trim().toLowerCase() == normalized) {

        return 'Tip sa ovim nazivom već postoji';

      }

    }

    return null;

  }



  static String? quantity(String? value, {String fieldName = 'Količina'}) {
    final String? requiredError = required(value, fieldName: fieldName);
    if (requiredError != null) return requiredError;
    final int? parsed = int.tryParse(value!.trim());
    if (parsed == null || parsed < 1) {
      return '$fieldName mora biti cijeli broj veći od 0';
    }
    return null;
  }

  /// Ime/prezime — min 2 znaka (RegisterRequest).
  static String? personName(String? value, {required String fieldName}) {
    return minLength(value, 2, fieldName: fieldName);
  }

  static String? loginUsername(String? value) {

    return required(value, fieldName: 'Korisničko ime');

  }



  static String? loginPassword(String? value) {

    return required(value, fieldName: 'Lozinka');

  }



  static String? resetToken(String? value) {

    return required(value, fieldName: 'Reset kod');

  }



  static String? fullName(String? value) {

    return required(value, fieldName: 'Ime i prezime');

  }



  static String? shippingAddress(String? value) {

    return required(value, fieldName: 'Adresa dostave');

  }



  static final RegExp _lettersWithSpaceRegex =

      RegExp(r'^[A-Za-z\sčćžšđČĆŽŠĐ]+$');



  static String? announcementBagName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Naziv torbice je obavezan';
    }
    if (value.trim().length < 2) {
      return 'Naziv torbice mora imati najmanje 2 znaka';
    }
    final String trimmed = value.trim();

    if (trimmed.length > 25) return 'Naziv može imati najviše 25 znakova';

    if (!_lettersWithSpaceRegex.hasMatch(trimmed)) {

      return 'Dozvoljena su samo slova';

    }

    return null;

  }



  static String? announcementPriceDigits(String? value) {

    final String trimmed = value?.trim() ?? '';

    if (trimmed.isEmpty) return 'Cijena je obavezna';

    if (trimmed.length > 5) return 'Cijena može imati najviše 5 cifara';

    if (!RegExp(r'^[0-9]+$').hasMatch(trimmed)) {

      return 'Dozvoljeni su samo brojevi';

    }

    final double? parsed = double.tryParse(trimmed);

    if (parsed == null || parsed <= 0) return 'Cijena mora biti veća od 0';

    return null;

  }



  static String? announcementColor(String? value) {

    final String? requiredError = required(value, fieldName: 'Boja');

    if (requiredError != null) return requiredError;

    final String trimmed = value!.trim();

    if (trimmed.length > 15) return 'Boja može imati najviše 15 znakova';

    if (!_lettersWithSpaceRegex.hasMatch(trimmed)) {

      return 'Dozvoljena su samo slova';

    }

    return null;

  }



  static String? shippingCity(String? value) {

    final String city = value?.trim() ?? '';

    if (city.isEmpty) return 'Unesite grad';

    if (!RegExp(r'^[A-Za-zČĆŽŠĐčćžšđ]{1,12}$').hasMatch(city)) {

      return 'Grad može sadržavati samo slova (max 12)';

    }

    return null;

  }



  static String? postalCodeBiH(String? value) {

    final String postalCode = value?.trim() ?? '';

    if (postalCode.isEmpty) return 'Unesite poštanski broj';

    if (!RegExp(r'^\d{5}$').hasMatch(postalCode)) {

      return 'Poštanski broj mora imati 5 cifara';

    }

    return null;

  }



  static String? participantName(String? value) {

    return minLength(value, 2, fieldName: 'Ime');

  }



  /// Opcionalno ime (giveaway brza prijava) — prazno je OK.

  static String? optionalParticipantName(String? value) {

    if (value == null || value.trim().isEmpty) return null;

    return minLength(value, 2, fieldName: 'Ime');

  }



  static String? requiredBeltType(int? value) {

    if (value == null) return 'Odaberite tip kaiša';

    return null;

  }



  /// Dijalog s inline validacijom umjesto običnog TextField + snackbar.

  static Future<String?> promptValidatedText(

    BuildContext context, {

    required String title,

    required String label,

    required String initial,

    required String? Function(String? value) validator,

  }) async {

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final TextEditingController controller = TextEditingController(text: initial);

    return showDialog<String>(

      context: context,

      builder: (BuildContext dialogContext) => AlertDialog(

        title: Text(title),

        content: Form(

          key: formKey,

          child: TextFormField(

            controller: controller,

            decoration: InputDecoration(labelText: label),

            validator: validator,

            autofocus: true,

          ),

        ),

        actions: <Widget>[

          TextButton(

            onPressed: () => Navigator.of(dialogContext).pop(),

            child: const Text('Odustani'),

          ),

          ElevatedButton(

            onPressed: () {

              if (formKey.currentState?.validate() ?? false) {

                Navigator.of(dialogContext).pop(controller.text.trim());

              }

            },

            child: const Text('Sačuvaj'),

          ),

        ],

      ),

    );

  }

}


