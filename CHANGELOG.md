## 0.2.1
- Fix: preserve ASCII percent-encodings in component getters and `toString()` for RFC 3987 compliance.
- Fix: prevent over-decoding of characters like `%25`, `%20`, and `%2F`.
- Robust URI-to-IRI decoding: preserve invalid percent-encoded sequences instead of throwing.
- Implement preservation of prohibited bidirectional control characters (RFC 3987 Section 4.1).

## 0.2.0
- Complete package rewrite that is now implemented as a wrapper around the native `Uri` class.
- Automatic Punycode conversion for hostnames in `toUri()`.
- Unicode-aware component accessors (host, path, query, fragment, userInfo).
- Support for standard constructors: `Iri()`, `Iri.http()`, `Iri.https()`, `Iri.file()`.
- Static methods `Iri.parse()` and `Iri.tryParse()`.
- Immutable design with `@immutable` and equality support.

## 0.1.1
- Minor fixes in documentation

## 0.1.0

- Initial version.
