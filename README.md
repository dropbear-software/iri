[![pub package](https://img.shields.io/pub/v/iri.svg)](https://pub.dev/packages/iri)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Open in Firebase Studio](https://cdn.firebasestudio.dev/btn/open_light_20.svg)](https://studio.firebase.google.com/import?url=https%3A%2F%2Fgithub.com%2Fdropbear-software%iri)
# IRI - Internationalized Resource Identifiers
A Dart library for parsing, validating, manipulating, and converting
Internationalized Resource Identifiers (IRIs) based on [RFC 3987](https://www.rfc-editor.org/rfc/rfc3987).

## Overview

Internationalized Resource Identifiers (IRIs) extend the syntax of Uniform
Resource Identifiers (URIs) to support a wider range of characters from the
Universal Character Set (Unicode/ISO 10646). This is essential for representing
resource identifiers in languages that use characters outside the US-ASCII range.

This package provides the `IRI` class to work with IRIs in Dart applications.
It handles the necessary conversions between IRIs and standard URIs, including:

* **Punycode encoding/decoding** for internationalized domain names (IDNs) within the host component.
* **Percent encoding/decoding** for other non-ASCII characters in various IRI components, using UTF-8 as required by the standard.

## Features

* **Parse IRI strings:** Create `IRI` objects from strings.
* **Validate IRIs:** Check if strings conform to RFC 3987 syntax.
* **Access Components:** Easily get decoded IRI components like `scheme`, `host`, `path`, `query`, `fragment`, `userInfo`, `port`.
* **IRI-to-URI Conversion:** Convert an `IRI` object to a standard Dart `Uri` object, applying Punycode and percent-encoding according to RFC 3987 rules.
* **URI-to-IRI Conversion:** Convert a standard `Uri` back into an `IRI`, decoding percent-encoded sequences where appropriate.
* **Normalization:** Applies syntax-based normalization including:
    * Case normalization (scheme, host).
    * Percent-encoding normalization (uses uppercase hex, decodes unreserved characters where possible in IRI representation).
    * Path segment normalization (removes `.` and `..` segments).
* **Comparison:** Compare `IRI` objects based on their code point sequence (simple string comparison).

## Getting Started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  iri: ^0.1.0
```

Then, import the library in your Dart code:

```dart
import 'package:iri/iri.dart';
```

## Usage
Here's a basic example demonstrating how to create an `IRI` and convert it to a `Uri`:

```dart
import 'package:iri/iri.dart';

void main() {
  // 1. Create an IRI from a string containing non-ASCII characters.
  //    例子 means "example" in Chinese.
  //    The path contains 'ȧ' (U+0227 LATIN SMALL LETTER A WITH DOT ABOVE).
  final iri = IRI('https://例子.com/pȧth?q=1');

  // 2. Print the original IRI string representation.
  print('Original IRI: $iri');
  // Output: Original IRI: https://例子.com/pȧth?q=1

  // 3. Convert the IRI to its standard URI representation.
  //    - The host (例子.com) is converted to Punycode (xn--fsqu00a.com).
  //    - The non-ASCII path character 'ȧ' (UTF-8 bytes C8 A7) is percent-encoded (%C8%A7).
  final uri = iri.toUri();
  print('Converted URI: $uri');
  // Output: Converted URI: https://xn--fsqu00a.com/p%C8%A7th?q=1

  // 4. Access components (values are decoded for IRI representation).
  print('Scheme: ${iri.scheme}');       // Output: Scheme: https
  print('Host: ${iri.host}');           // Output: Host: 例子.com
  print('Path: ${iri.path}');           // Output: Path: /pȧth
  print('Query: ${iri.query}');         // Output: Query: q=1

  // 5. Compare IRIs
  final iri2 = IRI('https://例子.com/pȧth?q=1');
  print('IRIs equal: ${iri == iri2}'); // Output: IRIs equal: true

  final iri3 = IRI('https://example.com/');
  print('IRIs equal: ${iri == iri3}'); // Output: IRIs equal: false
}
```