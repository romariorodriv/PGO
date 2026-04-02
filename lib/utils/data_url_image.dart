import 'dart:convert';
import 'dart:typed_data';

Uint8List? tryDecodeDataUrl(String? value) {
  if (value == null || !value.startsWith('data:image/')) {
    return null;
  }

  final commaIndex = value.indexOf(',');
  if (commaIndex == -1) {
    return null;
  }

  try {
    return base64Decode(value.substring(commaIndex + 1));
  } catch (_) {
    return null;
  }
}
