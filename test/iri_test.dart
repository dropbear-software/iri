import 'package:iri/iri.dart';
import 'package:test/test.dart';

void main() {
  group('Iri Core and Punycode mapping', () {
    test('toUri handles ASCII host', () {
      final iri = Iri.parse('http://example.org/path');
      final uri = iri.toUri();
      expect(uri.host, 'example.org');
      expect(uri.toString(), 'http://example.org/path');
    });

    test('toUri converts non-ASCII host to Punycode', () {
      // résumé -> xn--rsum-bpad
      final iri = Iri.parse('http://résumé.example.org');
      final uri = iri.toUri();
      expect(uri.host, 'xn--rsum-bpad.example.org');
      expect(uri.toString(), 'http://xn--rsum-bpad.example.org');
    });

    test('toUri converts multi-label non-ASCII host', () {
      // münchen.test -> xn--mnchen-3ya.test
      final iri = Iri.parse('http://münchen.test');
      final uri = iri.toUri();
      expect(uri.host, 'xn--mnchen-3ya.test');
    });

    test('toUri handles international separators', () {
      // mañana。com -> xn--maana-pta.com
      final iri = Iri.parse('http://mañana\u3002com');
      final uri = iri.toUri();
      expect(uri.host, 'xn--maana-pta.com');
    });

    test('toUriString handles percent-encoding of path', () {
      final iri = Iri.parse('http://example.org/résumé');
      expect(iri.toUriString(), 'http://example.org/r%C3%A9sum%C3%A9');
    });
  });

  group('Iri mailto: special handling', () {
    test('toUri converts domain part of mailto: path', () {
      // mailto:user@münchen.test -> mailto:user@xn--mnchen-3ya.test
      final iri = Iri.parse('mailto:user@münchen.test');
      final uri = iri.toUri();
      expect(uri.path, 'user@xn--mnchen-3ya.test');
      expect(uri.toString(), 'mailto:user@xn--mnchen-3ya.test');
    });

    test('toUri handles international characters in local part', () {
      // mailto:джумла@münchen.test
      final iri = Iri.parse('mailto:джумла@münchen.test');
      final uri = iri.toUri();
      // local part should be percent-encoded, domain part Punycode
      expect(uri.path, contains('xn--mnchen-3ya.test'));
      expect(uri.toString(), contains('%D0%B4%D0%B6%D1%83%D0%BC%D0%BB%D0%B0'));
    });

    test('path getter returns Unicode for mailto: domains', () {
      final uri = Uri.parse('mailto:user@xn--mnchen-3ya.test');
      final iri = Iri.fromUri(uri);
      expect(iri.path, 'user@münchen.test');
    });

    test('path getter handles complex mailto: gracefully', () {
      // multiple recipients or headers might not match emailToUnicode pattern
      final iri = Iri.parse('mailto:a@b.com,c@d.com?subject=hi');
      expect(iri.path, 'a@b.com,c@d.com');
    });
  });

  group('Iri constructors', () {
    test('default constructor with components', () {
      final iri = Iri(
        scheme: 'https',
        host: 'résumé.example.org',
        path: '/path',
      );
      expect(iri.toString(), 'https://résumé.example.org/path');
      expect(iri.toUri().host, 'xn--rsum-bpad.example.org');
    });

    test('Iri.http', () {
      final iri = Iri.http('münchen.test', '/path');
      expect(iri.toString(), 'http://münchen.test/path');
      expect(iri.toUri().host, 'xn--mnchen-3ya.test');
    });

    test('Iri.https', () {
      final iri = Iri.https('münchen.test', '/path');
      expect(iri.toString(), 'https://münchen.test/path');
      expect(iri.toUri().host, 'xn--mnchen-3ya.test');
    });

    test('Iri.file', () {
      final iri = Iri.file('/path/to/résumé.txt');
      expect(iri.scheme, 'file');
      expect(iri.toString(), contains('résumé.txt'));
    });

    test('Iri.tryParse', () {
      expect(Iri.tryParse('http://example.org'), isNotNull);
      expect(Iri.tryParse('::'), isNull);
    });

    test('Iri.fromUri', () {
      final uri = Uri.parse(
        'http://xn--rsum-bpad.example.org/r%C3%A9sum%C3%A9',
      );
      final iri = Iri.fromUri(uri);
      expect(iri.host, 'résumé.example.org');
      expect(iri.path, '/résumé');
      expect(iri.toString(), 'http://résumé.example.org/résumé');
    });
  });

  group('Iri component accessors', () {
    test('Unicode-aware getters', () {
      final iri = Iri.parse('http://user:pass@résumé.test/münchen?q=résumé#f');
      expect(iri.host, 'résumé.test');
      expect(iri.path, '/münchen');
      expect(iri.query, 'q=résumé');
      expect(iri.fragment, 'f');
      expect(iri.userInfo, 'user:pass');
    });

    test('pathSegments and queryParameters', () {
      final iri = Iri.parse('http://example.org/a/b?q=1&v=2');
      expect(iri.pathSegments, ['a', 'b']);
      expect(iri.queryParameters, {'q': '1', 'v': '2'});
    });
  });

  group('Iri equality', () {
    test('operator == and hashCode handles basic equality', () {
      final iri1 = Iri.parse('http://résumé.test');
      final iri2 = Iri.parse('http://résumé.test');
      final iri3 = Iri.parse('http://other.test');

      expect(iri1 == iri2, isTrue);
      expect(iri1 == iri3, isFalse);
      expect(iri1.hashCode == iri2.hashCode, isTrue);
    });

    test('operator == handles Unicode vs Punycode host', () {
      final iriUnicode = Iri.parse('http://résumé.example.org');
      final iriPunycode = Iri.parse('http://xn--rsum-bpad.example.org');

      expect(iriUnicode == iriPunycode, isTrue);
      expect(iriUnicode.hashCode == iriPunycode.hashCode, isTrue);
    });

    test('operator == handles NFC normalization', () {
      // 'e' + combining acute accent (U+0301) vs 'é' (U+00E9)
      final iri1 = Iri.parse('http://example.org/re\u0301sume\u0301');
      final iri2 = Iri.parse('http://example.org/résumé');

      expect(iri1 == iri2, isTrue);
      expect(iri1.hashCode == iri2.hashCode, isTrue);
    });

    test('operator == handles case normalization of scheme and host', () {
      final iri1 = Iri.parse('HTTP://EXAMPLE.ORG/');
      final iri2 = Iri.parse('http://example.org/');

      expect(iri1 == iri2, isTrue);
    });
  });

  group('Normalization and Unicode Representation', () {
    test('NFC normalization during parse', () {
      // 'e' + combining acute accent (U+0301)
      const input = 'http://example.org/re\u0301sume\u0301';
      final iri = Iri.parse(input);
      // Normalized to 'é' (U+00E9)
      expect(iri.path, '/résumé');
      expect(iri.toString(), 'http://example.org/résumé');
    });

    test('toString returns Unicode representation', () {
      final iri = Iri.parse('http://résumé.example.org/münchen?q=résumé#f');
      expect(iri.toString(), 'http://résumé.example.org/münchen?q=résumé#f');
    });

    test('toString handles port and userInfo', () {
      final iri = Iri.parse('http://user:pass@example.org:8080/path');
      expect(iri.toString(), 'http://user:pass@example.org:8080/path');
    });

    test('NFKC normalization (Compatibility Decomposition)', () {
      // Full-width Latin 'A' (U+FF21) should be normalized to 'A' (U+0041)
      final iri = Iri.parse('http://\uFF21.com/');
      expect(
        iri.host,
        'a.com',
      ); // Note: host getter might also be lowercase if punycode was involved
      expect(iri.toString(), 'http://a.com/');
    });
  });

  group('Iri Resolution', () {
    test('resolve(String) handles relative path', () {
      final base = Iri.parse('http://résumé.example.org/a/b');
      final resolved = base.resolve('c/d');
      expect(resolved.toString(), 'http://résumé.example.org/a/c/d');
    });

    test('resolve(String) handles absolute path', () {
      final base = Iri.parse('http://résumé.example.org/a/b');
      final resolved = base.resolve('/c/d');
      expect(resolved.toString(), 'http://résumé.example.org/c/d');
    });

    test('resolve(String) handles full IRI', () {
      final base = Iri.parse('http://résumé.example.org/a/b');
      final resolved = base.resolve('https://münchen.test/');
      expect(resolved.toString(), 'https://münchen.test/');
    });

    test('resolve(String) normalizes input to NFKC', () {
      final base = Iri.parse('http://example.org/');
      // Full-width 'a' (U+FF41)
      final resolved = base.resolve('\uFF41');
      expect(resolved.path, '/a');
    });

    test('resolveIri(Iri) works', () {
      final base = Iri.parse('http://résumé.example.org/a/b');
      final relative = Iri.parse('c/d');
      final resolved = base.resolveIri(relative);
      expect(resolved.toString(), 'http://résumé.example.org/a/c/d');
    });
  });

  group('Iri.replace', () {
    test('replace component works', () {
      final base = Iri.parse('http://example.org/path');
      final replaced = base.replace(host: 'résumé.test', fragment: 'f');
      expect(replaced.toString(), 'http://résumé.test/path#f');
    });

    test('replace normalizes inputs to NFKC', () {
      final base = Iri.parse('http://example.org/');
      // Full-width 'a' (U+FF41)
      final replaced = base.replace(path: '/\uFF41');
      expect(replaced.path, '/a');
    });

    test('replace handles pathSegments and queryParameters', () {
      final base = Iri.parse('http://example.org/');
      final replaced = base.replace(
        pathSegments: ['a', 'b'],
        queryParameters: {'q': 'résumé'},
      );
      expect(replaced.toString(), 'http://example.org/a/b?q=résumé');
    });
  });

  group('RFC Specicifc complaince', () {
    group('RFC 3987 Section 3.1: Mapping IRIs to URIs', () {
      test('Idempotency: Applying mapping twice changes nothing', () {
        final iri = Iri.parse('http://résumé.example.org/path');
        final uri1 = iri.toUri();
        final iri2 = Iri.fromUri(uri1);
        final uri2 = iri2.toUri();
        expect(uri1, uri2);
      });

      test('Percent-encoding uses uppercase letters for hex (Step 2.2)', () {
        final iri = Iri.parse('http://example.org/é');
        // é is U+00E9, UTF-8: C3 A9
        expect(iri.toUriString(), contains('%C3%A9'));
      });

      test('Characters NOT to be converted: #, %, [, ]', () {
        // These are reserved or have special meaning, should not be converted in Step 2
        final iri = Iri.parse('http://example.org/path%20#frag');
        expect(iri.toUriString(), 'http://example.org/path%20#frag');
      });

      test('Non-BMP characters (Step 2 Example)', () {
        // Old Italic letters: U+10300 U+10301 U+10302
        // Correct URI: %F0%90%8C%80%F0%90%8C%81%F0%90%8C%82
        final iri = Iri.parse('http://example.com/\u{10300}\u{10301}\u{10302}');
        expect(
          iri.toUriString(),
          contains('%F0%90%8C%80%F0%90%8C%81%F0%90%8C%82'),
        );
      });
    });

    group('RFC 3987 Section 3.2: Converting URIs to IRIs', () {
      test('Valid UTF-8 is decoded (Example 1)', () {
        final uri = Uri.parse('http://www.example.org/D%C3%BCrst');
        final iri = Iri.fromUri(uri);
        expect(iri.path, '/D\u00FCrst');
        expect(iri.toString(), 'http://www.example.org/D\u00FCrst');
      });

      test(
        'Invalid UTF-8 sequence remains percent-encoded (Example 2)',
        () {
          // %FC is not a valid UTF-8 start byte for a single character or valid sequence here
          final uri = Uri.parse('http://www.example.org/D%FCrst');
          final iri = Iri.fromUri(uri);
          // We expect it to NOT decode if it's invalid UTF-8
          // Note: Dart's Uri.decodeComponent might throw or return something else.
          // If it throws, Iri should handle it.
          expect(iri.path, contains('%FC'));
        },
        skip: 'Not currently implemented',
      );

      test(
        'Bidi control characters remain percent-encoded (Example 3)',
        () {
          // U+202E RIGHT-TO-LEFT OVERRIDE is %E2%80%AE
          final uri = Uri.parse('http://example.org/%E2%80%AE');
          final iri = Iri.fromUri(uri);
          // Currently fails: it decodes it.
          expect(iri.path, contains('%E2%80%AE'));
        },
        skip: 'Not currently implemented',
      );
    });

    group('RFC 3987 Section 5: Normalization and Comparison', () {
      test('Percent-encoding normalization (Section 5.3.2.3)', () {
        // Unreserved characters should be decoded for comparison
        // ~ (U+007E) is unreserved.
        final iri1 = Iri.parse('http://example.org/%7Euser');
        final iri2 = Iri.parse('http://example.org/~user');
        expect(iri1, iri2);
      });

      test('Case normalization of hex digits', () {
        final iri1 = Iri.parse('http://example.org/%c3%a9');
        final iri2 = Iri.parse('http://example.org/%C3%A9');
        expect(iri1, iri2);
      });

      test('Path segment normalization (Section 5.3.2.4)', () {
        final iri1 = Iri.parse('http://example.org/a/./b/../c');
        final iri2 = Iri.parse('http://example.org/a/c');
        expect(iri1, iri2);
      });

      test('Scheme-based normalization: Default port (Section 5.3.3)', () {
        final iri1 = Iri.parse('http://example.com:80/');
        final iri2 = Iri.parse('http://example.com/');
        expect(iri1, iri2);
      });

      test('Host equivalence: Unicode vs Punycode (Section 5.3.3)', () {
        final iri1 = Iri.parse('http://résumé.example.org/');
        final iri2 = Iri.parse('http://xn--rsum-bpad.example.org/');
        expect(iri1, iri2);
      });

      test('Host equivalence: Case mapping in IDN', () {
        final iri1 = Iri.parse('http://RÉSUMÉ.example.org/');
        final iri2 = Iri.parse('http://résumé.example.org/');
        expect(iri1, iri2);
      });
    });

    group('RFC 3987 Section 6.1: Character limitations', () {
      test('Private use characters allowed in query', () {
        // U+E000 is a private use character
        final iri = Iri.parse('http://example.org/path?q=\uE000');
        expect(iri.query, 'q=\uE000');
      });

      test(
        'Prohibited US-ASCII characters should be percent-encoded in URI',
        () {
          // < > " { } | \ ^ `
          final iri = Iri.parse(r'http://example.org/path?q=<>&"{}|\^`');
          final uriStr = iri.toUriString();
          expect(uriStr, contains('%3C')); // <
          expect(uriStr, contains('%3E')); // >
          expect(uriStr, contains('%22')); // "
          expect(uriStr, contains('%7B')); // {
          expect(uriStr, contains('%7D')); // }
          expect(uriStr, contains('%7C')); // |
          expect(uriStr, contains('%5C')); // \
          expect(uriStr, contains('%5E')); // ^
          expect(uriStr, contains('%60')); // `
        },
      );
    });

    group('Relative IRI References (Section 6.5)', () {
      test('Relative resolution handles Unicode', () {
        final base = Iri.parse('http://résumé.example.org/a/b');
        // Resolve against c/d
        // Note: Iri doesn't have resolve() yet, but we can check if it should.
        // For now, let's see if we can use Uri.resolve on toUri().
        final resolvedUri = base.toUri().resolve('c/d');
        final resolvedIri = Iri.fromUri(resolvedUri);
        expect(resolvedIri.toString(), 'http://résumé.example.org/a/c/d');
      });
    });
  });
}
