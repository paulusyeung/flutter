import 'package:admin/data/services/device_contacts_service.dart';

/// Web stub: the browser has no OS-native contact picker, so the import button
/// hides itself ([isAvailable] == false) and [pickContact] is a no-op. Never
/// imports `flutter_contacts` (which has no web implementation and would break
/// `flutter build web --wasm`).
class UnsupportedDeviceContactsService implements DeviceContactsService {
  const UnsupportedDeviceContactsService();

  @override
  bool get isAvailable => false;

  @override
  Future<DeviceContactImport?> pickContact() async => null;
}

DeviceContactsService defaultDeviceContactsService() =>
    const UnsupportedDeviceContactsService();
