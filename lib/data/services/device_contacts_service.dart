import 'package:admin/data/models/value/country.dart';

/// Platform-neutral snapshot of a contact the user picked from the device
/// address book. Keeps `flutter_contacts` types out of the UI/VM — the native
/// impl ([NativeDeviceContactsService]) maps the plugin's `Contact` onto this;
/// the web stub never produces one. Every field defaults to `''` so callers
/// (and tests) can build a partial import.
class DeviceContactImport {
  const DeviceContactImport({
    this.firstName = '',
    this.lastName = '',
    this.displayName = '',
    this.organization = '',
    this.email = '',
    this.phone = '',
    this.address1 = '',
    this.city = '',
    this.state = '',
    this.postalCode = '',
    this.countryIso = '',
    this.countryName = '',
    this.website = '',
  });

  final String firstName;
  final String lastName;

  /// The OS-computed display name (used only as a labelling fallback).
  final String displayName;

  /// Company / organization name → the client's `name` when it has no own name.
  final String organization;

  final String email;
  final String phone;
  final String address1;
  final String city;
  final String state;
  final String postalCode;

  /// ISO 3166-1 alpha-2 country code (locale-independent; iOS populates this).
  final String countryIso;

  /// Localized country name (device-locale; best-effort match only).
  final String countryName;

  final String website;

  /// Best-effort human label for toasts: the person's full name, else the
  /// OS display name, else the organization, else the email.
  String get displayLabel {
    final full = '$firstName $lastName'.trim();
    if (full.isNotEmpty) return full;
    if (displayName.trim().isNotEmpty) return displayName.trim();
    if (organization.trim().isNotEmpty) return organization.trim();
    return email.trim();
  }
}

/// Reads a single contact from the device address book via the OS-native
/// picker. Native-only (iOS today); the web stub and non-iOS native platforms
/// report [isAvailable] == false so the import button hides itself.
///
/// Mirrors [BiometricService]'s seam: an abstract interface, a native impl, and
/// an unsupported stub, selected per platform in `Services.build` via
/// `defaultDeviceContactsService()` (`device_contacts_service_factory.dart`).
abstract class DeviceContactsService {
  /// True only where the OS-native contact picker exists (iOS). Synchronous so
  /// the import button can show/hide at build time without a `FutureBuilder`.
  bool get isAvailable;

  /// Launches the OS contact picker and returns the chosen contact, or `null`
  /// if the user cancelled (or the platform is unsupported). Throws on a
  /// genuine platform failure so the caller can tell failure from cancel.
  Future<DeviceContactImport?> pickContact();
}

/// Resolves an Invoice Ninja country id (the server integer-as-string, e.g.
/// `"840"` for the US) from a device contact's ISO code or country name.
/// Returns `''` when nothing matches — the caller's blanks-only merge makes a
/// miss harmless.
///
/// Priority: ISO 3166-1 alpha-2 against [Country.iso2] (locale-independent),
/// then the country name against [Country.name] (best-effort — the device
/// returns names in its own locale, so this branch mostly hits for English).
String resolveCountryId(
  Iterable<Country> countries, {
  required String iso2,
  required String name,
}) {
  final iso = iso2.trim().toLowerCase();
  if (iso.isNotEmpty) {
    for (final c in countries) {
      if (c.iso2.trim().toLowerCase() == iso) return c.id;
    }
  }
  final n = name.trim().toLowerCase();
  if (n.isNotEmpty) {
    for (final c in countries) {
      if (c.name.trim().toLowerCase() == n) return c.id;
    }
  }
  return '';
}
