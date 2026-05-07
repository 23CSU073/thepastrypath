import 'google_maps_web_bootstrap_stub.dart'
    if (dart.library.html) 'google_maps_web_bootstrap_web.dart'
    as impl;

bool hasGoogleMapsJsApi() => impl.hasGoogleMapsJsApi();

bool hasPlaceholderGoogleMapsKey() => impl.hasPlaceholderGoogleMapsKey();
