import 'package:flutter_test/flutter_test.dart';
import 'package:inkognito/core/deeplink/deep_link_listener.dart';

void main() {
  group('DeepLinkParser.challengeId', () {
    test('parses custom scheme inkognito://challenge/<id>', () {
      final uri = Uri.parse('inkognito://challenge/abc123');
      expect(DeepLinkParser.challengeId(uri), 'abc123');
    });

    test('parses https universal link /c/<id>', () {
      final uri = Uri.parse('https://inkognito.page.link/c/xyz789');
      expect(DeepLinkParser.challengeId(uri), 'xyz789');
    });

    test('parses query-style ?id=<id>', () {
      final uri = Uri.parse('inkognito://challenge?id=q42');
      expect(DeepLinkParser.challengeId(uri), 'q42');
    });

    test('returns null for unrelated links', () {
      expect(
        DeepLinkParser.challengeId(Uri.parse('https://example.com/about')),
        isNull,
      );
    });
  });
}
