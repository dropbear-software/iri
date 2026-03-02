# IRI (Internationalized Resource Identifiers)

A pure Dart implementation of Internationalized Resource Identifiers (IRI) as defined in [RFC 3987](https://datatracker.ietf.org/doc/html/rfc3987).

This package provides an `Iri` class that acts as a Unicode-aware wrapper around Dart's native `Uri` class. It handles the mapping between IRIs and URIs, including automatic Punycode conversion for hostnames and UTF-8 percent-encoding for other components.

## Features

- **Standard Compliant**: Implements the IRI-to-URI mapping and URI-to-IRI conversion rules from RFC 3987.
- **Punycode Support**: Automatically converts non-ASCII hostnames to Punycode.
- **Unicode-Aware**: Access components (path, query, fragment, etc.) in their original Unicode form.
- **Normalization**: Automatically applies **NFKC** (Normalization Form KC) to all inputs as recommended by RFC 3987 to prevent comparison false-negatives.
- **Robust Decoding**: Preserves invalid percent-encoded sequences (e.g., `%FC`) and prohibited characters (like bidi controls) instead of throwing or over-decoding.
- **IDNA Separators**: Supports international domain separators (`。`, `．`, `｡`) during parsing and conversion.
- **Mailto Support**: Special handling for `mailto:` IRIs, ensuring email domain parts are correctly Punycode-encoded.
- **Familiar API**: Mirrors the Dart `Uri` class API, including `resolve`, `resolveIri`, and `replace`.
- **Immutable**: The `Iri` class is immutable and supports equality checks.

## RFC 3987 Compliance & Limitations

While this package aims for high compatibility with RFC 3987, there are still some known areas where the current implementation deviates from the strict specification:

1.  **Prohibited Characters (RFC 3987 Section 4.1)**: While bidirectional control characters are now preserved as percent-encodings, other classes of prohibited characters (e.g., certain non-character codepoints) may still be decoded if present in a URI.
2.  **Bidi Validation (RFC 3987 Section 4.2)**: The package does not currently perform structural validation of bidirectional IRIs (e.g., ensuring RTL components don't mix directions incorrectly).

These areas **may** be a part of future updates. For most common use cases involving standard Unicode text in paths and hosts, the package provides a robust experience.

## Getting started

Add `iri` to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  iri: ^0.2.1
```

## Usage

### Basic Parsing and Conversion

```dart
import 'package:iri/iri.dart';

void main() {
  // Parse an IRI with Unicode characters
  final iri = Iri.parse('http://résumé.example.org/résumé');

  print('IRI host: ${iri.host}'); // résumé.example.org
  print('IRI path: ${iri.path}'); // /résumé

  // Convert to a standard URI for network operations
  final uri = iri.toUri();
  print('URI host: ${uri.host}'); // xn--rsum-bpad.example.org
  print('URI string: $uri');      // http://xn--rsum-bpad.example.org/r%C3%A9sum%C3%A9
}
```

### Creating IRIs from Components

```dart
final iri = Iri(
  scheme: 'https',
  host: 'münchen.test',
  path: '/city',
);

print(iri.toUri()); // https://xn--mnchen-3ya.test/city
```
