/// @docImport 'src/iri_base.dart';
/// Provides support for Internationalized Resource Identifiers (IRIs)
/// based on RFC 3987 (https://www.rfc-editor.org/rfc/rfc3987).
///
/// This library defines the [Iri] class, which allows parsing, validation,
/// manipulation, and conversion of IRIs. IRIs extend the syntax of Uniform
/// Resource Identifiers (URIs) to support a wider range of characters from the
/// Universal Character Set (Unicode/ISO 10646).
///
/// Use the [Iri] class to work with resource identifiers that may contain
/// non-ASCII characters, commonly found in international contexts. It handles
/// conversions to and from standard URIs, including Punycode encoding for
/// internationalized domain names (IDNs) and percent-encoding for other
/// non-ASCII characters.
///
/// ## Usage Example
///
/// ```dart
/// import 'package:iri/iri.dart';
///
/// void main() {
///  // Create an IRI from a string containing non-ASCII characters.
///  final iri = Iri.parse(
///    'https://例子.com/pȧth?q=1',
///  ); // 例子 means "example"
///
///  // Print the original IRI string.
///  print('Original IRI: $iri');
///  // Output: Original IRI: https://例子.com/pȧth?q=1
///
///  // Convert the IRI to its standard URI representation.
///  // The host is Punycode-encoded, and path characters are percent-encoded.
///  final uri = iri.toUri();
///  print('Converted URI: $uri');
///  // Output: Converted URI: http://xn--fsqu00a.com/p%C8%A7th?q=1
///
///  // Access components of the IRI (decoded).
///  print('Scheme: ${iri.scheme}'); // Output: Scheme: https
///  print('Host: ${iri.host}'); // Output: Host: 例子.com
///  print('Path: ${iri.path}'); // Output: Path: /pȧth
///  print('Query: ${iri.query}'); // Output: Query: q=1
/// }
/// ```
///
/// See the [Iri] class documentation for more details on available methods
/// and properties.
library;

export 'src/iri_base.dart';
