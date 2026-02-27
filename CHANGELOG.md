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
