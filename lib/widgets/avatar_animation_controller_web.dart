import 'dart:html' as html;
import 'dart:js_util' as js_util;

List<String>? getAvatarAnimationNames(String elementId) {
  final element = html.document.getElementById(elementId);
  if (element == null) {
    return null;
  }
  final animations = js_util.getProperty(element, 'availableAnimations');
  if (animations == null) {
    return <String>[];
  }
  if (animations is List) {
    return animations.cast<String>();
  }
  if (animations is Iterable) {
    return List<String>.from(animations);
  }
  return <String>[];
}

bool playAvatarAnimation(String elementId, {String? animationName}) {
  final element = html.document.getElementById(elementId);
  if (element == null) {
    return false;
  }
  if (animationName != null && animationName.isNotEmpty) {
    js_util.setProperty(element, 'animationName', animationName);
  }
  js_util.callMethod(element, 'play', const []);
  return true;
}

bool pauseAvatarAnimation(
  String elementId, {
  double currentTime = 0,
  String? animationName,
}) {
  final element = html.document.getElementById(elementId);
  if (element == null) {
    return false;
  }
  if (animationName != null && animationName.isNotEmpty) {
    js_util.setProperty(element, 'animationName', animationName);
  }
  js_util.callMethod(element, 'pause', const []);
  js_util.setProperty(element, 'currentTime', currentTime);
  return true;
}
