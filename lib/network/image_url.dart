import 'consts.dart';

class ImageUrl {
  static String? resolve(String? raw) {
    if (raw == null) return null;
    final value = raw.trim();
    if (value.isEmpty) return null;

    final serverBase = _serverBaseUri();

    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty) {
      final storageIndex = parsed.path.indexOf('/storage/');
      if (storageIndex != -1) {
        final storagePath = parsed.path.substring(storageIndex);
        return serverBase.replace(path: storagePath).toString();
      }
      return value;
    }

    if (value.contains('/storage/')) {
      final storagePath = value.substring(value.indexOf('/storage/'));
      return serverBase.replace(path: storagePath).toString();
    }

    if (value.startsWith('storage/')) {
      return serverBase.replace(path: '/$value').toString();
    }

    if (value.startsWith('/storage/')) {
      return serverBase.replace(path: value).toString();
    }

    return serverBase.replace(path: '/storage/$value').toString();
  }

  static Uri _serverBaseUri() {
    final apiUri = Uri.parse(kBaseUrl);
    final segments =
        List<String>.from(apiUri.pathSegments.where((s) => s.isNotEmpty));
    if (segments.isNotEmpty && segments.last.toLowerCase() == 'api') {
      segments.removeLast();
    }
    return apiUri.replace(pathSegments: segments);
  }
}
