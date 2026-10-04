import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/utils/cloudinary_url.dart';

void main() {
  const url =
      'https://res.cloudinary.com/demo/image/upload/v123/rentease/a.jpg';

  test('inserts f_auto,q_auto,w_n after /upload/', () {
    expect(
      CloudinaryUrl.optimized(url, width: 400),
      'https://res.cloudinary.com/demo/image/upload/f_auto,q_auto,w_400/v123/rentease/a.jpg',
    );
  });

  test('thumbnail and full use their widths', () {
    expect(CloudinaryUrl.thumbnail(url), contains('w_400'));
    expect(CloudinaryUrl.full(url), contains('w_1280'));
  });

  test('is idempotent and ignores non-Cloudinary URLs', () {
    final once = CloudinaryUrl.thumbnail(url);
    expect(CloudinaryUrl.thumbnail(once), once);
    expect(CloudinaryUrl.thumbnail('https://example.com/a.jpg'),
        'https://example.com/a.jpg');
    expect(CloudinaryUrl.thumbnail('not a url'), 'not a url');
  });
}
