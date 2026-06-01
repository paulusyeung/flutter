import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:logging/logging.dart';

import 'package:admin/data/services/device_contacts_service.dart';

final _log = Logger('DeviceContactsService');

/// Reads a single device contact via the OS-native picker (`flutter_contacts`).
///
/// iOS-only today: the native picker exists on iOS and Android, but no
/// `android/` target is configured, so [isAvailable] gates to iOS. macOS
/// compiles this file (the package ships a macOS plugin) but has no native
/// picker — `showPicker` throws there — so it reports unavailable and the
/// button hides itself.
class NativeDeviceContactsService implements DeviceContactsService {
  const NativeDeviceContactsService();

  @override
  // Android-ready: `|| defaultTargetPlatform == TargetPlatform.android` once an
  // `android/` target + READ_CONTACTS manifest entry exist.
  bool get isAvailable => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<DeviceContactImport?> pickContact() async {
    if (!isAvailable) return null;
    final Contact? picked;
    try {
      // Request the fields we map. Without `properties` the picker returns only
      // id + displayName; passing them keeps the picker permission-free on iOS
      // (no address-book permission prompt — the user hands over one contact).
      picked = await FlutterContacts.native.showPicker(
        properties: const {
          ContactProperty.name,
          ContactProperty.phone,
          ContactProperty.email,
          ContactProperty.address,
          ContactProperty.organization,
          ContactProperty.website,
        },
      );
    } on PlatformException catch (e, st) {
      _log.warning('device contact pick failed', e, st);
      rethrow; // genuine failure → caller shows an error toast (≠ cancel).
    }
    if (picked == null) return null; // user cancelled.
    return _map(picked);
  }

  DeviceContactImport _map(Contact c) {
    final address = c.addresses.isNotEmpty ? c.addresses.first : null;
    return DeviceContactImport(
      firstName: c.name?.first ?? '',
      lastName: c.name?.last ?? '',
      displayName: c.displayName ?? '',
      organization: c.organizations.isNotEmpty
          ? (c.organizations.first.name ?? '')
          : '',
      email: c.emails.isNotEmpty ? c.emails.first.address : '',
      phone: _preferredPhone(c),
      address1: address?.street ?? '',
      city: address?.city ?? '',
      state: address?.state ?? '',
      postalCode: address?.postalCode ?? '',
      countryIso: address?.isoCountryCode ?? '',
      countryName: address?.country ?? '',
      website: c.websites.isNotEmpty ? c.websites.first.url : '',
    );
  }

  /// Prefer a mobile / iPhone number; fall back to the first listed.
  String _preferredPhone(Contact c) {
    if (c.phones.isEmpty) return '';
    for (final p in c.phones) {
      final label = p.label.label;
      if (label == PhoneLabel.mobile || label == PhoneLabel.iPhone) {
        return p.number;
      }
    }
    return c.phones.first.number;
  }
}

DeviceContactsService defaultDeviceContactsService() =>
    const NativeDeviceContactsService();
