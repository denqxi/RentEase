/// Display-time optimisation for stored Cloudinary `secure_url`s.
///
/// Inserts `f_auto,q_auto,w_<n>` after `/upload/` so Cloudinary serves a
/// right-sized, modern-format image instead of the stored original. Non
/// Cloudinary URLs and already-transformed URLs are returned unchanged.
class CloudinaryUrl {
  const CloudinaryUrl._();

  static const int thumbnailWidth = 400;
  static const int fullWidth = 1280;

  static const String _marker = '/image/upload/';

  static String optimized(String url, {required int width}) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host != 'res.cloudinary.com') return url;
    final i = url.indexOf(_marker);
    if (i < 0) return url;
    final after = url.substring(i + _marker.length);
    // A transformation segment appears before the `v123` version / public id.
    if (after.startsWith('f_auto') || after.contains('q_auto')) return url;
    final head = url.substring(0, i + _marker.length);
    return '${head}f_auto,q_auto,w_$width/$after';
  }

  static String thumbnail(String url) => optimized(url, width: thumbnailWidth);

  static String full(String url) => optimized(url, width: fullWidth);
}
