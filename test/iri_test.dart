// test/iri_test.dart
import 'package:iri/iri.dart';
import 'package:test/test.dart';

void main() {
  group('IRI to URI Conversion Tests', () {
    // --- Basic ASCII URIs (Should pass through mostly unchanged) ---
    test('Simple HTTP URI', () {
      const inputIri = 'http://example.com/path?query#fragment';
      const expectedUriString = 'http://example.com/path?query#fragment';
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(expectedUriString));
    });

    test('HTTPS with default port', () {
      const inputIri = 'https://example.com/path';
      const expectedUriString =
          'https://example.com/path'; // Note: Uri toString might omit default ports
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(expectedUriString));
    });

    test('HTTP with explicit default port 80', () {
      const inputIri = 'http://example.com:80/path';
      const expectedUriString =
          'http://example.com/path'; // Uri toString omits default port
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(expectedUriString));
    });

    test('URI with userinfo', () {
      const inputIri = 'ftp://user:password@example.com/';
      const expectedUriString = 'ftp://user:password@example.com/';
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(expectedUriString));
    });

    test('URI with empty path after authority', () {
      const inputIri = 'http://example.com';
      const expectedUriString =
          'http://example.com/'; // Uri parsing/construction typically adds '/'
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(expectedUriString));
    });

    // --- Host Handling (IDN, Punycode, IPs) ---
    test('Simple IDN Host (Chinese)', () {
      const inputIri = 'http://例子.com/'; // 例子 = example
      const expectedUriString = 'http://xn--fsqu00a.com/'; // Punycode encoded
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(inputIri));
    });

    test('Simple IDN Host (German)', () {
      const inputIri = 'http://Exämple.org/path'; // Mixed case input host
      const expectedUriString =
          'http://xn--exmple-cua.org/path'; // Punycode of lowercased host
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(inputIri.toLowerCase()));
    });

    test('IDN Host, no Punycode needed', () {
      const inputIri = 'http://example.com/';
      const expectedUriString = 'http://example.com/';
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(expectedUriString));
    });

    test('schemes are normalized as lowercase', () {
      const inputIri = 'HTTP://example.com/';
      const expectedUriString = 'http://example.com/';
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(expectedUriString));
    });

    test('hosts are normalized as lowercase', () {
      const inputIri = 'http://EXAMPLE.com/';
      const expectedUriString = 'http://example.com/';
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(expectedUriString));
    });

    test('paths are not normalized as lowercase', () {
      const inputIri = 'http://example.com/UPPERCASE';
      const expectedUriString = 'http://example.com/UPPERCASE';
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(expectedUriString));
    });

    // test('IDN Host with non-ASCII TLD', () {
    //   const inputIri =
    //       'http://example.xn--iñvalidtld/'; // Test case for potential future TLDs, Punycode should apply
    //   const expectedUriString = 'http://example.xn--iinvalidtld-9na/';
    //   final iri = IRI(inputIri);
    //   final uri = iri.toUri();
    //   expect(uri.toString(), equals(expectedUriString));
    //   expect(iri.toString(), equals(inputIri));
    // });

    test('IPv4 Host', () {
      const inputIri = 'http://192.168.0.1/path';
      const expectedUriString = 'http://192.168.0.1/path'; // No Punycode
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(expectedUriString));
    });

    test('IPv6 Host (Simple)', () {
      const inputIri = 'http://[::1]/path';
      const expectedUriString = 'http://[::1]/path'; // No Punycode
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(expectedUriString));
    });

    test('IPv6 Host (Full) - Checks preservation of uncompressed form', () {
      const inputIri = 'http://[2001:0db8:85a3:0000:0000:8a2e:0370:7334]/';
      // Dart's Uri class preserves the input IPv6 form (does not apply RFC 5952)
      const expectedUriString =
          'http://[2001:0db8:85a3:0000:0000:8a2e:0370:7334]/';
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(expectedUriString));
    });

    test('IPv6 Host (Normalization Check - Input Uppercase)', () {
      const inputIri = 'http://[2001:DB8::1]/path';
      const expectedUriString =
          'http://[2001:db8::1]/path'; // Expect lowercase hex output
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(expectedUriString));
    });

    // TODO: https://github.com/dart-lang/sdk/issues/60483
    // test('IPvFuture Host (Normalization Check - Input Uppercase V)', () {
    //   const inputIri = 'http://[vFe.foo_bar]/';
    //   const expectedUriString =
    //       'http://[vfe.foo_bar]/'; // Expect lowercase 'v' and content
    //   final iri = IRI(inputIri);
    //   final uri = iri.toUri();
    //   expect(uri.toString(), equals(expectedUriString));
    // });

    // --- Path Component (Unicode, Percent Encoding) ---
    test('Path with Latin Extended (Umlaut)', () {
      const inputIri = 'http://example.com/pȧth'; // a with dot above
      const expectedUriString = 'http://example.com/p%C8%A7th'; // UTF-8: C8 A7
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(inputIri));
    });

    // Add test for the other a-dot (U+0121) using explicit codepoint
    test('Path with Latin Extended (a-dot U+0121)', () {
      const inputIri = 'http://example.com/p\u{0121}th'; // Explicitly U+0121
      // UTF-8 for U+0121 is C4 A1
      const expectedUriString = 'http://example.com/p%C4%A1th';
      const expectedIriString = 'http://example.com/pġth';
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(expectedIriString));
    });

    test('Path with Greek', () {
      const inputIri = 'http://example.com/αβγ'; // alpha beta gamma
      const expectedUriString =
          'http://example.com/%CE%B1%CE%B2%CE%B3'; // UTF-8: CE B1, CE B2, CE B3
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(inputIri));
    });

    test('Path with Japanese', () {
      const inputIri = 'http://example.com/path/資料'; // 資料 = material/data
      const expectedUriString =
          'http://example.com/path/%E8%B3%87%E6%96%99'; // UTF-8: E8 B3 87 E6 96 99
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(inputIri));
    });

    test('Path with existing valid percent encoding', () {
      const inputIri = 'http://example.com/path%20with%20spaces'; // %20 = space
      const expectedUriString =
          'http://example.com/path%20with%20spaces'; // Should be preserved
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(expectedUriString));
    });

    test('Path with existing mixed-case percent encoding', () {
      const inputIri = 'http://example.com/path%e2%82%ac'; // %e2%82%ac = €
      const expectedUriString = 'http://example.com/path%E2%82%AC';
      const expectedIriString = 'http://example.com/path€';
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(expectedIriString));
    });

    // --- Query Component ---
    test('Query with Unicode', () {
      const inputIri = 'http://example.com/?k€y=vÄlue'; // Euro, A-umlaut
      const expectedUriString =
          'http://example.com/?k%E2%82%ACy=v%C3%84lue'; // UTF-8: E2 82 AC, C3 84
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(inputIri));
    });

    test('Query with reserved chars & / ?', () {
      const inputIri = 'http://example.com/?a=b&c=d/e?f=g';
      const expectedUriString =
          'http://example.com/?a=b&c=d/e?f=g'; // / and ? are allowed in query
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(inputIri));
    });

    test(
      'Query with chars allowed in path but not query unencoded (test needed?)',
      () {
        // Generally pchar / "/" / "?" are allowed, so this is less common
        const inputIri = 'http://example.com/?email=a@b'; // @ allowed via pchar
        const expectedUriString = 'http://example.com/?email=a@b';
        final iri = IRI(inputIri);
        final uri = iri.toUri();
        expect(uri.toString(), equals(expectedUriString));
        expect(iri.toString(), equals(inputIri));
      },
    );

    // --- Fragment Component ---
    test('Fragment with Unicode', () {
      const inputIri = 'http://example.com/#frag™ent'; // Trademark symbol
      const expectedUriString =
          'http://example.com/#frag%E2%84%A2ent'; // UTF-8: E2 84 A2
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(inputIri));
    });

    test('Fragment with / and ?', () {
      const inputIri = 'http://example.com/#a/b?c';
      const expectedUriString =
          'http://example.com/#a/b?c'; // / and ? allowed in fragment
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(inputIri));
    });

    // --- UserInfo Component ---
    test('UserInfo with Unicode', () {
      const inputIri = 'http://úser@example.com/'; // u acute
      const expectedUriString = 'http://%C3%BAser@example.com/'; // UTF-8: C3 BA
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(inputIri));
    });

    test('UserInfo with sub-delims and colon', () {
      const inputIri = r'http://u!$&()*+,;=:p@example.com/';
      const expectedUriString =
          r'http://u!$&()*+,;=:p@example.com/'; // These are allowed raw
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(inputIri));
    });

    // test('UserInfo with slash (needs encoding)', () {
    //   const inputIri =
    //       'http://user/name@example.com/'; // / not allowed raw in userinfo
    //   const expectedUriString = 'http://user%2Fname@example.com/'; // %2F = /
    //   final iri = IRI(inputIri);
    //   final uri = iri.toUri();
    //   expect(uri.toString(), equals(expectedUriString));
    //   expect(iri.toString(), equals(inputIri));
    // });

    // --- Path Normalization (Dot Segments) ---
    test('Path Normalization: Simple dot segment', () {
      const inputIri = 'http://example.com/a/./b';
      const expectedUriString = 'http://example.com/a/b';
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(expectedUriString));
    });

    test('Path Normalization: Simple dot-dot segment', () {
      const inputIri = 'http://example.com/a/b/../c';
      const expectedUriString = 'http://example.com/a/c';
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(expectedUriString));
    });

    test('Path Normalization: Leading dot-dot', () {
      const inputIri = 'http://example.com/../a';
      const expectedUriString =
          'http://example.com/a'; // Leading ../ is removed relative to root
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(expectedUriString));
    });

    test('Path Normalization: Mid dot-dot climbs too high', () {
      const inputIri = 'http://example.com/a/../../b';
      const expectedUriString =
          'http://example.com/b'; // Climbs above root, effectively /b
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(expectedUriString));
    });

    test('Path Normalization: Trailing dots', () {
      const inputIri = 'http://example.com/a/b/.';
      const expectedUriString =
          'http://example.com/a/b/'; // Trailing /. becomes /
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(expectedUriString));
    });

    test('Path Normalization: Trailing dot-dots', () {
      const inputIri = 'http://example.com/a/b/c/..';
      const expectedUriString =
          'http://example.com/a/b/'; // Trailing /.. removes last segment + becomes /
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(expectedUriString));
    });

    test('Path Normalization: Complex mix', () {
      const inputIri = 'http://example.com/a/./b/../c/d/../../e';
      const expectedUriString = 'http://example.com/a/e'; // Final result
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(expectedUriString));
    });

    // --- Relative References ---
    test('Relative Path', () {
      const inputIri = 'pȧth/ñ?q=1'; // a-dot, n-tilde
      const expectedUriString = 'p%C8%A7th/%C3%B1?q=1';
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(inputIri));
    });

    test('Relative Absolute Path', () {
      const inputIri = '/pȧth?q=1';
      const expectedUriString = '/p%C8%A7th?q=1';
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(inputIri));
    });

    test('Relative Network Path', () {
      const inputIri = '//例子.com/pȧth?q=1';
      const expectedUriString = '//xn--fsqu00a.com/p%C8%A7th?q=1';
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(inputIri));
    });

    test('Relative with dot segments', () {
      const inputIri = 'a/./b/../c/d';
      const expectedUriString =
          'a/c/d'; // Normalization applies to relative paths too
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(expectedUriString));
    });

    test('Relative empty path', () {
      const inputIri = '';
      const expectedUriString = '';
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(inputIri));
    });

    test('Relative fragment only', () {
      const inputIri = '#frågment';
      const expectedUriString = '#fr%C3%A5gment';
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(inputIri));
    });

    test('Relative query only', () {
      const inputIri = '?k€y=val';
      const expectedUriString = '?k%E2%82%ACy=val';
      final iri = IRI(inputIri);
      final uri = iri.toUri();
      expect(uri.toString(), equals(expectedUriString));
      expect(iri.toString(), equals(inputIri));
    });

    // --- Invalid IRI Handling (expect FormatException) ---
    test('Invalid IRI: Space in path', () {
      expect(() => IRI('http://example.com/a path'), throwsFormatException);
    });

    test('Invalid IRI: Space in host', () {
      expect(() => IRI('http://my host.com/'), throwsFormatException);
    });

    test('Invalid IRI: Bad IPv6 literal', () {
      expect(() => IRI('http://[:::1/'), throwsFormatException);
    });

    test('Invalid IRI: Starts with colon', () {
      expect(() => IRI('://example.com/'), throwsFormatException);
    });

    test('Invalid IRI: Empty host with authority marker', () {
      expect(() => IRI('http://'), throwsFormatException);
    });

    test('Invalid IRI: Invalid scheme format', () {
      expect(() => IRI('1http://example.com'), throwsFormatException);
    });

    test('Invalid IRI: Path with invalid percent encoding (non-hex)', () {
      expect(() => IRI('http://example.com/path%ax'), throwsFormatException);
    });

    test('Invalid IRI: Invalid characters in path (e.g., control chars)', () {
      // Note: _isValid check might catch this first
      expect(() => IRI('http://example.com/\x01'), throwsFormatException);
    });

    test('Invalid IRI: Path with lone percent sign', () {
      expect(() => IRI('http://example.com/path%25'), throwsFormatException);
    });

    test('Invalid IRI: Path with invalid percent encoding', () {
      expect(() => IRI('http://example.com/path%a'), throwsFormatException);
    });

    test('Invalid IRI: Path with reserved char needing encoding', () {
      // Assume '[' is not allowed raw in path by RFC 3986 (it's a gen-delim)
      expect(() => IRI('http://example.com/path[abc]'), throwsFormatException);
    });
  }); // End group: IRI to URI Conversion Tests
}
