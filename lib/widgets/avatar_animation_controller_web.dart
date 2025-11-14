import 'dart:html' as html;
import 'dart:js_util' as js_util;

bool playAvatarAnimation(String elementId) {
  final element = html.document.getElementById(elementId);
  if (element == null) {
    return false;
  }
  js_util.setProperty(element, 'animationName', 'Walk');
  js_util.callMethod(element, 'play', const []);
  return true;
}

bool pauseAvatarAnimation(String elementId, {double currentTime = 0}) {
  final element = html.document.getElementById(elementId);
  if (element == null) {
    return false;
  }
  js_util.setProperty(element, 'animationName', 'Walk');
  js_util.callMethod(element, 'pause', const []);
  js_util.setProperty(element, 'currentTime', currentTime);
  return true;
}
