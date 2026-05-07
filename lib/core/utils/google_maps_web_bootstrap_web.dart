import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('window')
external JSObject get _window;

bool hasGoogleMapsJsApi() {
  if (!_window.hasProperty('google'.toJS).toDart) return false;
  final googleAny = _window.getProperty('google'.toJS);
  if (googleAny == null) return false;
  final google = googleAny as JSObject;
  return google.hasProperty('maps'.toJS).toDart;
}

bool hasPlaceholderGoogleMapsKey() => false;
