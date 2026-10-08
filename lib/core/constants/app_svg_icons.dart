/// Outline SVG icons used across the app navigation and UI.
abstract final class AppSvgIcons {
  /// Home / dashboard icon (24x24 viewBox outline, 1.75 stroke).
  static const String home = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round">
  <path d="M19 8.71l-5.333 -4.148a2.666 2.666 0 0 0 -3.274 0l-5.334 4.148a2.665 2.665 0 0 0 -1.029 2.105v7.2a2 2 0 0 0 2 2h12a2 2 0 0 0 2 -2v-7.2c0 -.823 -.38 -1.6 -1.03 -2.105" />
  <path d="M16 15c-2.21 1.333 -5.792 1.333 -8 0" />
</svg>''';

  /// Search / magnifying glass icon (24x24 viewBox outline, 1.75 stroke).
  static const String search = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round">
  <path d="M10 10m-7 0a7 7 0 1 0 14 0a7 7 0 1 0 -14 0" />
  <path d="M21 21l-6 -6" />
</svg>''';

  /// Inquiry / chat message bubble icon (24x24 viewBox outline, 1.75 stroke).
  static const String inquiry = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round">
  <path d="M8 9h8" />
  <path d="M8 13h6" />
  <path d="M18 3a4 4 0 0 1 4 4v8a4 4 0 0 1 -4 4h-4.724l-5.276 3v-3h-2a4 4 0 0 1 -4 -4v-8a4 4 0 0 1 4 -4z" />
</svg>''';

  /// Save / heart outline icon (24x24 viewBox outline, 1.75 stroke).
  static const String save = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round">
  <path d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12Z" />
</svg>''';

  /// Owner add / create property plus-in-circle icon (24x24 viewBox outline, 1.5 stroke).
  static const String ownerAdd = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="12" cy="12" r="10" />
  <path d="M12 8v8" />
  <path d="M8 12h8" />
</svg>''';

  /// Notification / bell outline icon (24x24 viewBox outline, 1.75 stroke).
  static const String notification = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round">
  <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
  <path d="M13.73 21a2 2 0 0 1-3.46 0" />
</svg>''';

  /// Profile / user outline icon (24x24 viewBox outline, 1.75 stroke).
  static const String profile = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round">
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
}
