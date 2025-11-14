import 'dart:typed_data';
import 'dart:html' as html;

Future<String?> createObjectUrlFromBytes(
  Uint8List bytes, {
  required String mimeType,
}) async {
  if (bytes.isEmpty) {
    return null;
  }
  final blob = html.Blob(<dynamic>[bytes], mimeType);
  return html.Url.createObjectUrlFromBlob(blob);
}

void revokeObjectUrl(String url) {
  html.Url.revokeObjectUrl(url);
}
