/// Outline SVG icons used across the app navigation and UI.
abstract final class AppSvgIcons {
  /// Home / dashboard icon (24x24 viewBox outline, 1.35 stroke).
  static const String home = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.35" stroke-linecap="round" stroke-linejoin="round">
  <path d="M19 8.71l-5.333 -4.148a2.666 2.666 0 0 0 -3.274 0l-5.334 4.148a2.665 2.665 0 0 0 -1.029 2.105v7.2a2 2 0 0 0 2 2h12a2 2 0 0 0 2 -2v-7.2c0 -.823 -.38 -1.6 -1.03 -2.105" />
  <path d="M16 15c-2.21 1.333 -5.792 1.333 -8 0" />
</svg>''';

  /// Building / house icon for map pins and properties near button (Tabler-style house).
  static const String mapBuildingHouse = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round">
  <path d="M5 12l-2 0l9 -9l9 9l-2 0" />
  <path d="M5 12v7a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-7" />
  <path d="M9 21v-6a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2v6" />
</svg>''';

  /// Search / magnifying glass icon (24x24 viewBox outline, 1.35 stroke).
  static const String search = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.35" stroke-linecap="round" stroke-linejoin="round">
  <path d="M10 10m-7 0a7 7 0 1 0 14 0a7 7 0 1 0 -14 0" />
  <path d="M21 21l-6 -6" />
</svg>''';

  /// Inquiry / chat message bubble icon (24x24 viewBox outline, 1.35 stroke).
  static const String inquiry = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.35" stroke-linecap="round" stroke-linejoin="round">
  <path d="M8 9h8" />
  <path d="M8 13h6" />
  <path d="M18 3a4 4 0 0 1 4 4v8a4 4 0 0 1 -4 4h-4.724l-5.276 3v-3h-2a4 4 0 0 1 -4 -4v-8a4 4 0 0 1 4 -4z" />
</svg>''';

  /// Save / heart outline icon (24x24 viewBox outline, 1.35 stroke).
  static const String save = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.35" stroke-linecap="round" stroke-linejoin="round">
  <path d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12Z" />
</svg>''';

  /// Owner add / create property plus-in-circle icon (24x24 viewBox outline, 1.35 stroke).
  static const String ownerAdd = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.35" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="12" cy="12" r="10" />
  <path d="M12 8v8" />
  <path d="M8 12h8" />
</svg>''';

  /// Notification / bell outline icon (24x24 viewBox outline, 1.35 stroke).
  static const String notification = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.35" stroke-linecap="round" stroke-linejoin="round">
  <path d="M10 5a2 2 0 1 1 4 0a7 7 0 0 1 4 6v3a4 4 0 0 0 2 3h-16a4 4 0 0 0 2 -3v-3a7 7 0 0 1 4 -6" />
  <path d="M9 17v1a3 3 0 0 0 6 0v-1" />
</svg>''';

  /// Profile / user outline icon (24x24 viewBox outline, 1.35 stroke).
  static const String profile = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.35" stroke-linecap="round" stroke-linejoin="round">
  <path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2" />
  <circle cx="12" cy="7" r="4" />
</svg>''';

  /// Verified starburst checkmark badge with blue linear gradient.
  static const String verifiedBadge = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="url(#badgeGradient)" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round">
  <defs>
    <linearGradient id="badgeGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#60C5FA" />
      <stop offset="35%" stop-color="#249DEB" />
      <stop offset="70%" stop-color="#2563EB" />
      <stop offset="100%" stop-color="#1D4ED8" />
    </linearGradient>
  </defs>
  <path d="M12 2a3.2 3.2 0 0 1 2.26.94l.7.7a1.2 1.2 0 0 0 .85.36h1a3.2 3.2 0 0 1 3.2 3.2v1a1.2 1.2 0 0 0 .35.85l.7.7a3.2 3.2 0 0 1 0 4.52l-.7.7a1.2 1.2 0 0 0-.35.85v1a3.2 3.2 0 0 1-3.2 3.2h-1a1.2 1.2 0 0 0-.85.35l-.7.7a3.2 3.2 0 0 1-4.52 0l-.7-.7a1.2 1.2 0 0 0-.85-.35h-1a3.2 3.2 0 0 1-3.2-3.2v-1a1.2 1.2 0 0 0-.35-.85l-.7-.7a3.2 3.2 0 0 1 0-4.52l.7-.7a1.2 1.2 0 0 0 .35-.85v-1a3.2 3.2 0 0 1 3.2-3.2h1a1.2 1.2 0 0 0 .85-.35l.7-.7A3.2 3.2 0 0 1 12 2z" />
  <path d="m8 12 3 3 5-5" />
</svg>''';

  /// Sparkle starburst badge for unverified owners with warm amber-gold gradient.
  static const String sparkleBadge = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="url(#sparkleGradient)">
  <defs>
    <linearGradient id="sparkleGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#3B82F6" />
      <stop offset="12%" stop-color="#F59E0B" />
      <stop offset="35%" stop-color="#FDE68A" />
      <stop offset="65%" stop-color="#FACC15" />
      <stop offset="100%" stop-color="#F59E0B" />
    </linearGradient>
  </defs>
  <path d="M16.41 10.41a.998.998 0 0 0 0-1.82l-4.15-1.84-1.84-4.15a.998.998 0 0 0-.91-.59c-.4-.03-.75.22-.92.58L6.74 6.6 2.56 8.61c-.35.17-.57.53-.57.92s.24.74.59.9l4.15 1.84 1.84 4.15a.998.998 0 0 0 1.82 0l1.84-4.15 4.15-1.84Zm-5.82.68L9.5 13.53l-1.09-2.44a.98.98 0 0 0-.51-.51L5.37 9.46l2.55-1.23c.21-.1.38-.27.47-.48l1.08-2.33 1.1 2.48c.1.23.28.41.51.51l2.44 1.09-2.44 1.09c-.23.1-.41.28-.51.51Zm11.01 5.3-2.77-1.23-1.23-2.77a.68.68 0 0 0-.6-.4c-.27-.02-.5.15-.61.39l-1.23 2.67-2.78 1.34c-.23.11-.38.35-.38.61s.16.49.4.6l2.77 1.23 1.23 2.77a.663.663 0 0 0 1.22 0l1.23-2.77 2.77-1.23c.24-.11.4-.35.4-.61s-.16-.5-.4-.61ZM7.76 18.63l-1.66-.74-.74-1.66a.41.41 0 0 0-.36-.24c-.16-.01-.3.09-.37.23l-.74 1.6-1.67.8c-.14.07-.23.21-.23.37s.1.3.24.36l1.66.74.74 1.66a.404.404 0 0 0 .74 0l.74-1.66 1.66-.74a.404.404 0 0 0 0-.74Z" />
</svg>''';

  /// Moon icon with sparkles (Boxicons).
  static const String moon = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
  <path d="M20.71 13.51c-.78.23-1.58.35-2.38.35-4.52 0-8.2-3.68-8.2-8.2 0-.8.12-1.6.35-2.38.11-.35.01-.74-.25-1s-.64-.36-1-.25A10.17 10.17 0 0 0 2 11.8C2 17.42 6.57 22 12.2 22c4.53 0 8.45-2.91 9.76-7.24.11-.35.01-.74-.25-1s-.64-.36-1-.25M12.2 20C7.68 20 4 16.32 4 11.8a8.15 8.15 0 0 1 4.18-7.15c-.03.34-.05.68-.05 1.02 0 5.62 4.57 10.2 10.2 10.2.34 0 .68-.02 1.02-.05C17.93 18.38 15.23 20 12.2 20M16 8l.94-2.06L19 5l-2.06-.94L16 2l-.94 2.06L13 5l2.06.94zm4.25-.5-.55 1.2-1.2.55 1.2.55.55 1.2.55-1.2 1.2-.55-1.2-.55z" />
</svg>''';

  /// Shield alert outline icon for verification pending banner.
  static const String shieldAlert = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round">
  <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
  <line x1="12" y1="8" x2="12" y2="12" />
  <line x1="12" y1="16" x2="12.01" y2="16" />
</svg>''';

  /// Hourglass / timer outline icon for pending verification card.
  static const String hourglass = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
  <path d="M6 20v-2a6 6 0 1 1 12 0v2a1 1 0 0 1 -1 1h-10a1 1 0 0 1 -1 -1z" />
  <path d="M6 4v2a6 6 0 1 0 12 0v-2a1 1 0 0 0 -1 -1h-10a1 1 0 0 0 -1 1z" />
</svg>''';

  /// Modern iOS-style person / profile outline icon with curved contours (1.35 stroke).
  static const String personOutline = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.35" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="12" cy="7.25" r="3.75" />
  <path d="M4.75 20c0-3.6 3.25-6.5 7.25-6.5s7.25 2.9 7.25 6.5" />
</svg>''';

  /// Modern iOS-style star outline icon with rounded curved vertices (1.35 stroke).
  static const String starOutline = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.35" stroke-linecap="round" stroke-linejoin="round">
  <path d="M12 2.75l2.76 5.59 6.17.9-4.46 4.35 1.05 6.14L12 16.84l-5.52 2.9 1.05-6.15-4.46-4.34 6.17-.9L12 2.75z" />
</svg>''';

  /// Modern iOS-style sliders / preferences icon with circular nodes and rounded tracks (1.35 stroke).
  static const String preferencesSliders = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.35" stroke-linecap="round" stroke-linejoin="round">
  <path d="M3.5 6h7.5m3.5 0h6" />
  <circle cx="13" cy="6" r="2" />
  <path d="M3.5 12h3m3.5 0h10.5" />
  <circle cx="8" cy="12" r="2" />
  <path d="M3.5 18h11m3.5 0h2.5" />
  <circle cx="16" cy="18" r="2" />
</svg>''';

  /// Modern iOS-style leaderboard / ranking podium bars with rounded pill caps (1.35 stroke).
  static const String rankingBars = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.35" stroke-linecap="round" stroke-linejoin="round">
  <rect x="3.75" y="13" width="4.5" height="7.5" rx="2" />
  <rect x="9.75" y="4.5" width="4.5" height="16" rx="2" />
  <rect x="15.75" y="9" width="4.5" height="11.5" rx="2" />
</svg>''';

  /// Modern iOS-style crescent moon outline icon with smooth curves (1.35 stroke).
  static const String crescentMoon = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.35" stroke-linecap="round" stroke-linejoin="round">
  <path d="M20.2 14.7A8.25 8.25 0 0 1 9.3 3.8a8.25 8.25 0 1 0 10.9 10.9z" />
</svg>''';

  /// Modern iOS-style padlock icon with rounded body, curved shackle (1.35 stroke).
  static const String lockOutline = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.35" stroke-linecap="round" stroke-linejoin="round">
  <rect x="4.5" y="10" width="15" height="10.5" rx="3.5" ry="3.5" />
  <path d="M8 10V6.5a4 4 0 0 1 8 0V10" />
  <circle cx="12" cy="15.25" r="1.1" fill="currentColor" stroke="none" />
</svg>''';

  /// Modern iOS-style logout / exit door icon with rounded curves (1.35 stroke).
  static const String logoutOutline = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.35" stroke-linecap="round" stroke-linejoin="round">
  <path d="M15 3.75h3a2.5 2.5 0 0 1 2.5 2.5v11.5a2.5 2.5 0 0 1-2.5 2.5h-3" />
  <path d="M10.5 16.5l4.5-4.5-4.5-4.5" />
  <path d="M15 12H3.5" />
</svg>''';

  /// Modern iOS-style subtle chevron right with rounded caps (1.35 stroke).
  static const String chevronRight = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.35" stroke-linecap="round" stroke-linejoin="round">
  <path d="M9.5 17.5l5-5-5-5" />
</svg>''';

  /// Owner property type building icon (24x24 viewBox outline, 1.35 stroke).
  static const String propertyType = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.35" stroke-linecap="round" stroke-linejoin="round">
  <path d="M3 21l18 0" />
  <path d="M5 21v-14l8 -4v18" />
  <path d="M19 21v-10l-6 -4" />
  <path d="M9 9l0 .01" />
  <path d="M9 12l0 .01" />
  <path d="M9 15l0 .01" />
  <path d="M9 18l0 .01" />
</svg>''';

  /// Rent and Capacity icon (24x24 viewBox outline, 1.40 stroke).
  static const String rentAndCapacity = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.40" stroke-linecap="round" stroke-linejoin="round">
  <path d="M17 8v-3a1 1 0 0 0 -1 -1h-10a2 2 0 0 0 0 4h12a1 1 0 0 1 1 1v3m0 4v3a1 1 0 0 1 -1 1h-12a2 2 0 0 1 -2 -2v-12" />
  <path d="M20 12v4h-4a2 2 0 0 1 0 -4h4" />
</svg>''';

  /// House Rules icon (24x24 viewBox outline, 1.40 stroke).
  static const String houseRules = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.40" stroke-linecap="round" stroke-linejoin="round">
  <path d="M9 5h-2a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-12a2 2 0 0 0 -2 -2h-2" />
  <path d="M9 3m0 2a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2v0a2 2 0 0 1 -2 2h-2a2 2 0 0 1 -2 -2z" />
  <path d="M9 12l.01 0" />
  <path d="M13 12l2 0" />
  <path d="M9 16l.01 0" />
  <path d="M13 16l2 0" />
</svg>''';

  /// Amenities icon (24x24 viewBox outline, 1.40 stroke).
  static const String amenities = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.40" stroke-linecap="round" stroke-linejoin="round">
  <path d="M4 4m0 1a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v4a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1z" />
  <path d="M14 4m0 1a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v4a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1z" />
  <path d="M4 14m0 1a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v4a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1z" />
  <path d="M14 14m0 1a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v4a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1z" />
</svg>''';

  /// Update preferences / equalizer sliders icon (24x24 viewBox outline, 1.25 stroke).
  static const String updatePreferences = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.25" stroke-linecap="round" stroke-linejoin="round">
  <path d="M14 6m-2 0a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" />
  <path d="M4 6l8 0" />
  <path d="M16 6l4 0" />
  <path d="M8 12m-2 0a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" />
  <path d="M4 12l2 0" />
  <path d="M10 12l10 0" />
  <path d="M17 18m-2 0a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" />
  <path d="M4 18l11 0" />
  <path d="M19 18l1 0" />
</svg>''';

  /// Explore / compass icon (24x24 viewBox outline, 1.25 stroke).
  static const String exploreListings = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.25" stroke-linecap="round" stroke-linejoin="round">
  <path d="M8 16l2 -6l6 -2l-2 6l-6 2" />
  <path d="M12 12m-9 0a9 9 0 1 0 18 0a9 9 0 1 0 -18 0" />
  <path d="M12 3l0 2" />
  <path d="M12 19l0 2" />
  <path d="M3 12l2 0" />
  <path d="M19 12l2 0" />
</svg>''';

  /// Location pin icon (24x24 viewBox outline, 1.40 stroke).
  static const String location = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.40" stroke-linecap="round" stroke-linejoin="round">
  <path d="M12 21c-4.5 -4.5 -8 -8.5 -8 -12.5a8 8 0 1 1 16 0c0 4 -3.5 8 -8 12.5z" />
  <circle cx="12" cy="8.5" r="3" />
</svg>''';

  /// Map with pin icon (24x24 viewBox outline, 2.0 stroke).
  static const String mapPinned = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round">
  <path d="M12 18.5l-3 -1.5l-6 3v-13l6 -3l6 3l6 -3v7.5" />
  <path d="M9 4v13" />
  <path d="M15 7v5.5" />
  <path d="M21.121 20.121a3 3 0 1 0 -4.242 0c.418 .419 1.125 1.045 2.121 1.879c1.051 -.89 1.759 -1.516 2.121 -1.879z" />
  <path d="M19 18v.01" />
</svg>''';

  /// Navigation route to destination pin icon (24x24 viewBox outline, 2.1 stroke).
  static const String routeToDestination = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round">
  <path d="M12 18l-2 -4l-7 -3.5a.55 .55 0 0 1 0 -1l18 -6.5l-2.901 8.034" />
  <path d="M21.121 20.121a3 3 0 1 0 -4.242 0c.418 .419 1.125 1.045 2.121 1.879c1.051 -.89 1.759 -1.516 2.121 -1.879z" />
  <path d="M19 18v.01" />
</svg>''';

  /// Google Maps stylized brand pin marker icon.
  static const String googleMaps = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.35" stroke-linecap="round" stroke-linejoin="round">
  <path d="M12 9.5m-2.5 0a2.5 2.5 0 1 0 5 0a2.5 2.5 0 1 0 -5 0" />
  <path d="M6.428 12.494l7.314 -9.252" />
  <path d="M10.002 7.935l-2.937 -2.545" />
  <path d="M17.693 6.593l-8.336 9.979" />
  <path d="M17.591 6.376c.472 .907 .715 1.914 .709 2.935a7.263 7.263 0 0 1 -.72 3.18a19.085 19.085 0 0 1 -2.089 3c-.784 .933 -1.49 1.93 -2.11 2.98c-.314 .62 -.568 1.27 -.757 1.938c-.121 .36 -.277 .591 -.622 .591c-.315 0 -.463 -.136 -.626 -.593a10.595 10.595 0 0 0 -.779 -1.978a18.18 18.18 0 0 0 -1.423 -2.091c-.877 -1.184 -2.179 -2.535 -2.853 -4.071a7.077 7.077 0 0 1 -.621 -2.967a6.226 6.226 0 0 1 1.476 -4.055a6.25 6.25 0 0 1 4.811 -2.245a6.462 6.462 0 0 1 1.918 .284a6.255 6.255 0 0 1 3.686 3.092z" />
</svg>''';
}


