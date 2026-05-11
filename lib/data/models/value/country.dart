/// Statics-bundle country. Wire shape matches
/// `admin-portal/lib/data/models/static/country_model.dart` — note ISO
/// fields are wire-named `iso_3166_2` / `iso_3166_3`.
class Country {
  const Country({
    required this.id,
    required this.name,
    required this.iso2,
    required this.iso3,
    required this.swapCurrencySymbol,
    required this.thousandSeparator,
    required this.decimalSeparator,
    required this.swapPostalCode,
  });

  final String id;
  final String name;
  final String iso2;
  final String iso3;
  final bool swapCurrencySymbol;
  final String thousandSeparator;
  final String decimalSeparator;
  final bool swapPostalCode;

  factory Country.fromMap(Map<String, dynamic> json) => Country(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    iso2: json['iso_3166_2']?.toString() ?? '',
    iso3: json['iso_3166_3']?.toString() ?? '',
    swapCurrencySymbol: json['swap_currency_symbol'] == true,
    thousandSeparator: json['thousand_separator']?.toString() ?? '',
    decimalSeparator: json['decimal_separator']?.toString() ?? '',
    swapPostalCode: json['swap_postal_code'] == true,
  );
}
