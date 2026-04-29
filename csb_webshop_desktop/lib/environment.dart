docker compose ps


  static const bool enableLogging =
      bool.fromEnvironment('ENABLE_LOGGING', defaultValue: false);

  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue:
        'pk_test_51T6hBZCTVgVOvGUsDwWQGj588wzdirVATXce19ah3iMUzjeElXoetFCZTVAwbrMhgMuSmCoPFzhIP5xsfGEL4tDP00sa9PWkct',
  );
}