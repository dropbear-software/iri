import 'package:iri/iri.dart';

void main() {
  // Create an IRI from a string containing non-ASCII characters.
  final iri = IRI('https://例子.com/pȧth?q=1'); // 例子 means "example"

  // Print the original IRI string.
  print('Original IRI: ${iri.toString()}');
  // Output: Original IRI: https://例子.com/pȧth?q=1

  // Convert the IRI to its standard URI representation.
  // The host is Punycode-encoded, and path characters are percent-encoded.
  final uri = iri.toUri();
  print('Converted URI: ${uri.toString()}');
  // Output: Converted URI: http://xn--fsqu00a.com/p%C8%A7th?q=1

  // Access components of the IRI (decoded).
  print('Scheme: ${iri.scheme}'); // Output: Scheme: https
  print('Host: ${iri.host}'); // Output: Host: 例子.com
  print('Path: ${iri.path}'); // Output: Path: /pȧth
  print('Query: ${iri.query}'); // Output: Query: q=1
}