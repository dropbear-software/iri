import 'dart:convert';
import 'package:meta/meta.dart';
import 'package:punycoder/punycoder.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// An Internationalized Resource Identifier (IRI).
///
/// An IRI is a sequence of characters from the Universal Character Set (Unicode).
/// It provides a complement to the Uniform Resource Identifier (URI).
///
/// This implementation is a wrapper around the native [Uri] class, providing
/// Seamless mapping to URIs as defined in RFC 3987.
///
/// All strings passed to constructors or parsing methods are automatically
/// normalized to Normalization Form KC (NFKC).
@immutable
class Iri {
  final Uri _uri;

  late final Uri _convertedUri = _computeUri();

  /// Creates a new IRI from its components.
  ///
  /// This mirrors the [Uri] constructor. All string components are
  /// normalized to NFKC.
  Iri({
    String? scheme,
    String? userInfo,
    String? host,
    int? port,
    String? path,
    Iterable<String>? pathSegments,
    String? query,
    Map<String, dynamic>? queryParameters,
    String? fragment,
  }) : _uri = Uri(
         scheme: scheme,
         userInfo: userInfo != null ? unorm.nfkc(userInfo) : null,
         host: host != null ? unorm.nfkc(host) : null,
         port: port,
         path: path != null ? unorm.nfkc(path) : null,
         pathSegments: pathSegments?.map(unorm.nfkc),
         query: query != null ? unorm.nfkc(query) : null,
         queryParameters: _normalizeQueryParameters(queryParameters),
         fragment: fragment != null ? unorm.nfkc(fragment) : null,
       );

  /// Creates a new http IRI from its components.
  Iri.http(
    String host, [
    String path = '',
    Map<String, dynamic>? queryParameters,
  ]) : _uri = Uri.http(
         unorm.nfkc(host),
         unorm.nfkc(path),
         _normalizeQueryParameters(queryParameters),
       );

  /// Creates a new https IRI from its components.
  Iri.https(
    String host, [
    String path = '',
    Map<String, dynamic>? queryParameters,
  ]) : _uri = Uri.https(
         unorm.nfkc(host),
         unorm.nfkc(path),
         _normalizeQueryParameters(queryParameters),
       );

  /// Creates a new file IRI from its components.
  Iri.file(String path, {bool? windows})
    : _uri = Uri.file(unorm.nfkc(path), windows: windows);

  /// Creates a new IRI from an existing [Uri].
  Iri.fromUri(this._uri);

  /// Internal constructor for creating an [Iri] from an existing [Uri].
  Iri._(this._uri);

  /// Parses a string into an [Iri].
  ///
  /// The input string is normalized to NFKC before parsing.
  factory Iri.parse(String input) {
    final normalized = unorm.nfkc(input);
    return Iri._(Uri.parse(normalized));
  }

  /// Parses a string into an [Iri], or returns null if it fails.
  ///
  /// The input string is normalized to NFKC before parsing.
  static Iri? tryParse(String input) {
    final normalized = unorm.nfkc(input);
    final uri = Uri.tryParse(normalized);
    return uri == null ? null : Iri._(uri);
  }

  static Map<String, dynamic>? _normalizeQueryParameters(
    Map<String, dynamic>? params,
  ) {
    if (params == null) return null;
    return params.map((k, v) {
      final Object? normalizedValue;
      if (v is String) {
        normalizedValue = unorm.nfkc(v);
      } else if (v is Iterable<String>) {
        normalizedValue = v.map(unorm.nfkc);
      } else {
        normalizedValue = v;
      }
      return MapEntry(unorm.nfkc(k), normalizedValue);
    });
  }

  /// The scheme of this IRI.
  String get scheme => _uri.scheme;

  /// The Unicode-aware host of this IRI.
  ///
  /// If the host was Punycode-encoded (e.g., from a [Uri]), it is decoded back
  /// to its Unicode representation.
  String get host {
    final decoded = _decodeIriComponent(_uri.host);
    return domainToUnicode(decoded);
  }

  /// The Unicode-aware path of this IRI.
  String get path {
    final decoded = _decodeIriComponent(_uri.path);
    if (scheme == 'mailto') {
      try {
        return emailToUnicode(decoded);
      } on FormatException {
        return decoded;
      }
    }
    return decoded;
  }

  /// The Unicode-aware query of this IRI.
  String get query => _decodeIriComponent(_uri.query);

  /// The Unicode-aware fragment of this IRI.
  String get fragment => _decodeIriComponent(_uri.fragment);

  /// The Unicode-aware user information of this IRI.
  String get userInfo => _decodeIriComponent(_uri.userInfo);

  /// The port of this IRI.
  int get port => _uri.port;

  /// The authority component of this IRI.
  String get authority => _decodeIriComponent(_uri.authority);

  /// The URI query parameters as a map.
  Map<String, String> get queryParameters => _uri.queryParameters;

  /// The URI query parameters as a map, allowing for multiple values per key.
  ///
  /// The returned map's values are lists of strings.
  Map<String, List<String>> get queryParametersAll => _uri.queryParametersAll;

  /// The URI path segments as an iterable.
  List<String> get pathSegments =>
      _uri.pathSegments.map(_decodeIriComponent).toList();

  /// Resolves [reference] against this IRI.
  ///
  /// The [reference] is normalized to NFKC before being parsed and resolved.
  Iri resolve(String reference) {
    final normalized = unorm.nfkc(reference);
    return Iri.fromUri(_uri.resolve(normalized));
  }

  /// Resolves [reference] against this IRI.
  Iri resolveIri(Iri reference) {
    return Iri.fromUri(_uri.resolveUri(reference._uri));
  }

  /// Creates a new IRI by replacing some of the components of this IRI.
  ///
  /// This mirrors the [Uri.replace] method. All string components are
  /// normalized to NFKC.
  Iri replace({
    String? scheme,
    String? userInfo,
    String? host,
    int? port,
    String? path,
    Iterable<String>? pathSegments,
    String? query,
    Map<String, dynamic>? queryParameters,
    String? fragment,
  }) {
    return Iri.fromUri(
      _uri.replace(
        scheme: scheme,
        userInfo: userInfo != null ? unorm.nfkc(userInfo) : null,
        host: host != null ? unorm.nfkc(host) : null,
        port: port,
        path: path != null ? unorm.nfkc(path) : null,
        pathSegments: pathSegments?.map(unorm.nfkc),
        query: query != null ? unorm.nfkc(query) : null,
        queryParameters: _normalizeQueryParameters(queryParameters),
        fragment: fragment != null ? unorm.nfkc(fragment) : null,
      ),
    );
  }

  /// Converts this IRI to a standard [Uri].
  ///
  /// Any non-ASCII characters in the hostname are converted to Punycode
  /// according to RFC 3492. Other components are percent-encoded using UTF-8.
  Uri toUri() => _convertedUri;

  Uri _computeUri() {
    if (scheme == 'mailto') {
      final decodedPath = _decodeIriComponent(_uri.path);
      try {
        final punyEmail = emailToAscii(decodedPath, validate: false);
        return _uri.replace(path: punyEmail);
      } on FormatException {
        return _uri;
      }
    }

    final decodedHost = _decodeIriComponent(_uri.host);
    if (decodedHost.isEmpty) {
      return _uri;
    }

    final punyHost = domainToAscii(decodedHost, validate: false);
    return _uri.replace(host: punyHost);
  }

  /// Returns the Unicode representation of this IRI.
  @override
  String toString() {
    final sb = StringBuffer();
    if (scheme.isNotEmpty) {
      sb.write(scheme);
      sb.write(':');
    }
    if (_uri.hasAuthority || scheme == 'file') {
      sb.write('//');
      if (userInfo.isNotEmpty) {
        sb.write(userInfo);
        sb.write('@');
      }
      sb.write(host);
      if (_uri.hasPort) {
        sb.write(':');
        sb.write(port);
      }
    }
    sb.write(path);
    if (_uri.hasQuery) {
      sb.write('?');
      sb.write(query);
    }
    if (_uri.hasFragment) {
      sb.write('#');
      sb.write(fragment);
    }
    return sb.toString();
  }

  /// Returns the percent-encoded URI string representation of this IRI.
  String toUriString() => toUri().toString();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Iri && toUri() == other.toUri());

  @override
  int get hashCode => toUri().hashCode;

  /// Decodes percent-encoded sequences in [text] that represent
  /// valid characters allowed in an IRI but not in a URI (i.e. > U+007F).
  ///
  /// This method is a specialized decoder that follows RFC 3987 rules:
  /// 1. Non-ASCII characters (UTF-8 sequences) are decoded for readability.
  /// 2. ASCII percent-encodings (e.g. %20, %2F, %25) are preserved to
  ///    maintain structural integrity and semantic validity.
  /// 3. Robustness: Invalid UTF-8 sequences remain percent-encoded.
  /// 4. Security: Prohibited bidirectional control characters remain
  ///    percent-encoded (Section 4.1).
  static String _decodeIriComponent(String text) {
    // If there are no percent signs, there is nothing to decode.
    if (!text.contains('%')) return text;

    final bytes = text.codeUnits;
    final resultBytes = <int>[];

    for (var i = 0; i < bytes.length; i++) {
      if (bytes[i] == 0x25) {
        // We found a '%', start of a potential percent-encoded sequence.
        if (i + 2 < bytes.length) {
          // Peek ahead and collect ALL consecutive %XX sequences.
          // We need them together because a single Unicode character
          // might be spread across multiple percent-encoded bytes.
          final encodedSequence = <int>[];
          var j = i;
          while (j + 2 < bytes.length && bytes[j] == 0x25) {
            final byteVal = _parseHex(bytes[j + 1], bytes[j + 2]);
            if (byteVal != null) {
              encodedSequence.add(byteVal);
              j += 3;
            } else {
              break;
            }
          }

          if (encodedSequence.isNotEmpty) {
            // Process the collected bytes to decide what to decode.
            var k = 0;
            while (k < encodedSequence.length) {
              final firstByte = encodedSequence[k];
              if (firstByte < 0x80) {
                // RULE 1: ASCII (0-127).
                // RFC 3987: ASCII encodings must be preserved.
                // We add the original %XX characters from the source.
                resultBytes.add(0x25); // %
                resultBytes.add(bytes[i + k * 3 + 1]);
                resultBytes.add(bytes[i + k * 3 + 2]);
                k++;
              } else {
                // RULE 2: Potential non-ASCII character (UTF-8).
                // Determine the length of the UTF-8 sequence.
                var charLen = 0;
                if ((firstByte & 0xE0) == 0xC0) {
                  charLen = 2; // 110xxxxx
                } else if ((firstByte & 0xF0) == 0xE0) {
                  charLen = 3; // 1110xxxx
                } else if ((firstByte & 0xF8) == 0xF0) {
                  charLen = 4; // 11110xxx
                } else {
                  // Not a valid UTF-8 start byte. Keep it encoded.
                  resultBytes.add(0x25);
                  resultBytes.add(bytes[i + k * 3 + 1]);
                  resultBytes.add(bytes[i + k * 3 + 2]);
                  k++;
                  continue;
                }

                // Ensure we have enough bytes left in our sequence for the full character.
                if (k + charLen <= encodedSequence.length) {
                  // Validate trailing bytes (must be 10xxxxxx).
                  var valid = true;
                  for (var m = 1; m < charLen; m++) {
                    if ((encodedSequence[k + m] & 0xC0) != 0x80) {
                      valid = false;
                      break;
                    }
                  }

                  if (valid) {
                    try {
                      // Attempt to decode the UTF-8 sequence.
                      final decodedStr = const Utf8Decoder().convert(
                        encodedSequence.sublist(k, k + charLen),
                      );
                      // Apply NFKC normalization as recommended by RFC 3987.
                      final decodedChar = unorm.nfkc(decodedStr);

                      // RFC 3987 Section 4.1: Prohibited characters.
                      // Bidirectional control characters should remain encoded.
                      var shouldDecode = true;
                      if (decodedChar.length == 1) {
                        final codePoint = decodedChar.runes.first;
                        // Bidi control characters:
                        // U+200E (LRM), U+200F (RLM),
                        // U+202A-U+202E (LRE, RLE, PDF, LRO, RLO),
                        // U+2066-U+2069 (LRI, RLI, FSI, PDI).
                        if (codePoint == 0x200E ||
                            codePoint == 0x200F ||
                            (codePoint >= 0x202A && codePoint <= 0x202E) ||
                            (codePoint >= 0x2066 && codePoint <= 0x2069)) {
                          shouldDecode = false;
                        }
                      }

                      if (shouldDecode) {
                        // Success: add the decoded character bytes.
                        resultBytes.addAll(
                          const Utf8Encoder().convert(decodedChar),
                        );
                      } else {
                        // Prohibited: keep as original %XX sequences.
                        for (var m = 0; m < charLen; m++) {
                          resultBytes.add(0x25);
                          resultBytes.add(bytes[i + (k + m) * 3 + 1]);
                          resultBytes.add(bytes[i + (k + m) * 3 + 2]);
                        }
                      }
                      k += charLen;
                    } on FormatException catch (_) {
                      // Robustness: If decoding fails, keep as %XX.
                      for (var m = 0; m < charLen; m++) {
                        resultBytes.add(0x25);
                        resultBytes.add(bytes[i + (k + m) * 3 + 1]);
                        resultBytes.add(bytes[i + (k + m) * 3 + 2]);
                      }
                      k += charLen;
                    }
                  } else {
                    // Sequence validation failed: keep first byte encoded.
                    resultBytes.add(0x25);
                    resultBytes.add(bytes[i + k * 3 + 1]);
                    resultBytes.add(bytes[i + k * 3 + 2]);
                    k++;
                  }
                } else {
                  // Incomplete sequence: keep current byte encoded.
                  resultBytes.add(0x25);
                  resultBytes.add(bytes[i + k * 3 + 1]);
                  resultBytes.add(bytes[i + k * 3 + 2]);
                  k++;
                }
              }
            }

            // Jump the outer loop index past all processed %XX sequences.
            i += (j - i) - 1;
            continue;
          }
        }
      }

      // Not a percent sign or part of an encoded sequence: add raw byte.
      resultBytes.add(bytes[i]);
    }

    return const Utf8Decoder().convert(resultBytes);
  }

  /// Parses two hex characters into a single byte value.
  /// Returns null if [c1] or [c2] are not valid hex digits.
  static int? _parseHex(int c1, int c2) {
    final dig1 = _hexDigit(c1);
    final dig2 = _hexDigit(c2);
    if (dig1 == -1 || dig2 == -1) return null;
    return (dig1 << 4) | dig2;
  }

  /// Maps an ASCII character code to its hex digit value.
  static int _hexDigit(int c) {
    if (c >= 0x30 && c <= 0x39) return c - 0x30; // 0-9
    if (c >= 0x41 && c <= 0x46) return c - 0x37; // A-F
    if (c >= 0x61 && c <= 0x66) return c - 0x57; // a-f
    return -1;
  }
}
