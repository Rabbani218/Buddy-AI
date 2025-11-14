import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

Future<List<String>> fetchAvailableAnimations(String elementId) async {
  // Wait a tick to ensure the DOM element exists.
  await Future<void>.delayed(const Duration(milliseconds: 50));

  final html.Element? element = html.document.getElementById(elementId);
  if (element == null) {
    return const <String>[];
  }

  final dynamic animations = js_util.getProperty(element, 'availableAnimations');
  if (animations == null) {
    return const <String>[];
  }

  List<dynamic> rawList;
  if (animations is List) {
    rawList = animations;
  } else {
    final Object? dartified = js_util.dartify(animations);
    if (dartified is List) {
      rawList = dartified;
    } else {
      return const <String>[];
    }
  }

  return rawList
      .whereType<String>()
      .map((name) => name.trim())
      .where((name) => name.isNotEmpty)
      .toList();
}
