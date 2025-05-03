import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:punycoder/punycoder.dart';

/// Represents an Internationalized Resource Identifier (IRI) according to RFC 3987.
///
/// This class focuses on the parsing, validation, component access, normalization,
/// and URI conversion of IRIs.
@immutable
class IRI {
  final Uri _encodedUri;
  final Runes _codepoints;

  static final PunycodeCodec _punycodeCodec = PunycodeCodec();

  /// Create a new Internationalized Resource Identifier from a String
  IRI(String originalValue)
    : _encodedUri = _convertToUri(originalValue),
      _codepoints = originalValue.runes;

  // Accessors

  /// Returns the original, un-normalized string value used to create this IRI.
  /// Uses the stored code points to reconstruct the string.
  String get originalValue => String.fromCharCodes(_codepoints);

  /// The scheme component of the IRI.
  ///
  /// The value is the empty string if there is no scheme component.
  ///
  /// A IRI scheme is case insensitive.
  /// The returned scheme is canonicalized to lowercase letters.
  String get scheme => _encodedUri.scheme;

  /// The authority component.
  ///
  /// The authority is formatted from the [userInfo], [host] and [port]
  /// parts.
  ///
  /// The value is the empty string if there is no authority component.
  String get authority => _encodedUri.authority;

  /// The user info part of the authority component.
  ///
  /// The value is the empty string if there is no user info in the
  /// authority component.
  String get userInfo => _decodeIriComponent(
    _encodedUri.userInfo,
    _IRIRegexHelper._iriUserInfoAllowedAsciiChars,
  );

  /// The host part of the authority component.
  ///
  /// The value is the empty string if there is no authority component and
  /// hence no host.
  ///
  /// If the host is an IP version 6 address, the surrounding `[` and `]` is
  /// removed.
  ///
  /// The host string is case-insensitive.
  /// The returned host name is canonicalized to lower-case
  String get host {
    // The host component of a URI is encoded using Punycode. We need to decode it.
    // Note that strings that are not encoded using Punycode will be returned as-is.
    return _punycodeCodec.decode(_encodedUri.host);
  }

  /// The path component.
  ///
  /// The path is the actual substring of the IRI representing the path,
  /// and it is encoded where necessary. To get direct access to the decoded
  /// path, use [pathSegments].
  ///
  /// The path value is the empty string if there is no path component.
  String get path => _decodeIriComponent(
    _encodedUri.path,
    '${_IRIRegexHelper._iriPathComponentAllowedAsciiChars}/', // Allow '/' in path
  );

  /// The fragment identifier component.
  ///
  /// The value is the empty string if there is no fragment identifier
  /// component.
  String get fragment => _decodeIriComponent(
    _encodedUri.fragment,
    _IRIRegexHelper._iriFragmentAllowedAsciiChars,
  );

  /// The query component.
  ///
  /// The value is the actual substring of the IRI representing the query part,
  /// and it is encoded where necessary.
  /// To get direct access to the decoded query, use [queryParameters].
  ///
  /// The value is the empty string if there is no query component.
  String get query => _decodeIriComponent(
    _encodedUri.query,
    _IRIRegexHelper._iriQueryAllowedAsciiChars,
    allowIprivate: true,
  ); // Query needs special handling for iprivate chars

  /// The port part of the authority component.
  ///
  /// The value is the default port if there is no port number in the authority
  /// component. That's 80 for http, 443 for https, and 0 for everything else.
  int get port => _encodedUri.port;

  /// Whether the IRI is absolute.
  ///
  /// A IRI is an absolute IRI in the sense of RFC 3986 if it has a scheme
  /// and no fragment.
  bool get isAbsolute => _encodedUri.isAbsolute;

  /// Whether the IRI has a [scheme] component.
  bool get hasScheme => _encodedUri.hasScheme;

  /// Whether the IRI has an [authority] component.
  bool get hasAuthority => _encodedUri.hasAuthority;

  /// The ITI path split into its segments.
  ///
  /// Each of the segments in the list has been decoded.
  /// If the path is empty, the empty list will
  /// be returned. A leading slash `/` does not affect the segments returned.
  ///
  /// The list is unmodifiable and will throw [UnsupportedError] on any
  /// calls that would mutate it.
  List<String> get pathSegments => _encodedUri.pathSegments;

  /// The IRI query split into a map according to the rules
  /// specified for FORM post in the [HTML 4.01 specification section
  /// 17.13.4](https://www.w3.org/TR/REC-html40/interact/forms.html#h-17.13.4
  /// "HTML 4.01 section 17.13.4").
  ///
  /// Each key and value in the resulting map has been decoded.
  /// If there is no query, the empty map is returned.
  ///
  /// Keys in the query string that have no value are mapped to the
  /// empty string.
  /// If a key occurs more than once in the query string, it is mapped to
  /// an arbitrary choice of possible value.
  /// The [queryParametersAll] getter can provide a map
  /// that maps keys to all of their values.
  ///
  /// Example:
  /// ```dart import:convert
  /// final uri =
  ///     Uri.parse('https://example.com/api/fetch?limit=10,20,30&unicode_pȧram=true');
  /// print(jsonEncode(uri.queryParameters));
  /// // {"limit":"10,20,30","unicode_pȧram":"true"}
  /// ```
  ///
  /// The map is unmodifiable.
  Map<String, String> get queryParameters => _encodedUri.queryParameters;

  /// Returns the IRI query split into a map according to the rules
  /// specified for FORM post in the [HTML 4.01 specification section
  /// 17.13.4](https://www.w3.org/TR/REC-html40/interact/forms.html#h-17.13.4
  /// "HTML 4.01 section 17.13.4").
  ///
  /// Each key and value in the resulting map has been decoded. If there is no
  /// query, the map is empty.
  ///
  /// Keys are mapped to lists of their values. If a key occurs only once,
  /// its value is a singleton list. If a key occurs with no value, the
  /// empty string is used as the value for that occurrence.
  ///
  /// Example:
  /// ```dart import:convert
  /// final uri =
  ///     Uri.parse('https://example.com/api/fetch?limit=10&limit=20&limit=30&unicode_pȧram=100');
  /// print(jsonEncode(uri.queryParametersAll)); // {"limit":["10","20","30"],"unicode_pȧram":["100"]}
  /// ```
  ///
  /// The map and the lists it contains are unmodifiable.
  Map<String, List<String>> get queryParametersAll =>
      _encodedUri.queryParametersAll;

  /// Whether the URI has an explicit port.
  ///
  /// If the port number is the default port number
  /// (zero for unrecognized schemes, with http (80) and https (443) being
  /// recognized),
  /// then the port is made implicit and omitted from the URI.
  bool get hasPort => _encodedUri.hasPort;

  /// Whether the URI has a query part.
  bool get hasQuery => _encodedUri.hasQuery;

  /// Whether the URI has a fragment part.
  bool get hasFragment => _encodedUri.hasFragment;

  /// Whether the URI has an empty path.
  bool get hasEmptyPath => _encodedUri.hasEmptyPath;

  /// Whether the URI has an absolute path (starting with '/').
  bool get hasAbsolutePath => _encodedUri.hasAbsolutePath;

  /// Converts the IRI to it's canonical Uri encoding
  Uri toUri() {
    return _encodedUri;
  }

  static bool _isValid(String input) {
    final pattern = '^${_IRIRegexHelper.patterns.iriReference}\$';
    final regex = RegExp(pattern, unicode: true);
    return regex.hasMatch(input);
  }

  /// A function which takes a String, confirms it is a valid IRI and returns
  /// it encoded as a URI as per the RFC 3987 spec.
  static Uri _convertToUri(String iri) {
    // Make sure the value is a valid IRI to begin with
    if (!_isValid(iri)) {
      throw FormatException('Invalid IRI: $iri');
    }

    // Parse and normalize all components according to IRI rules
    final normalizedComponents = _parseAndNormalize(iri);
    final scheme = normalizedComponents['scheme'] as String?;
    final userInfo = normalizedComponents['userInfo'] as String?;
    // Get the host details from the map
    final hostNormalized = normalizedComponents['hostNormalized'] as String?;
    final hostType = normalizedComponents['hostType'] as _HostType?;
    final port = normalizedComponents['port'] as int?;
    // Path is already percent-normalized, dot segments handled by Uri constructor/normalizePath
    final path = normalizedComponents['path'] as String;
    final query = normalizedComponents['query'] as String?;
    final fragment = normalizedComponents['fragment'] as String?;

    String? finalHostForUri; // Will hold Punycode-encoded or normalized IP host

    // Determine the final host string for the Uri constructor based on type
    if (hostNormalized != null) {
      switch (hostType) {
        case _HostType.registeredName:
          // Only apply Punycode to registered names
          try {
            // Use the normalized host (already lowercased) for Punycode
            finalHostForUri = _punycodeCodec.encode(hostNormalized);
          } catch (e) {
            // Handle potential Punycode errors
            throw FormatException(
              'Punycode encoding failed for host: $hostNormalized',
              e,
            );
          }
        case _HostType.ipLiteral:
        case _HostType.ipv4Address:
          // Use the already type-normalized IP address directly
          finalHostForUri = hostNormalized;
        case null:
          // This case should not happen if hostNormalized is not null due to _parseAndNormalize logic
          throw StateError(
            'Internal error: Host type is null when normalized host is present.',
          );
      }
    }

    // If hostNormalized was null, finalHostForUri remains null

    // Now construct the Uri based on components present, using the final host string

    // The Uri constructor correctly handles null components.
    // We leverage the built-in path normalization by calling .normalizePath() at the end.
    final constructedUri = Uri(
      scheme: scheme,
      userInfo: userInfo,
      host: finalHostForUri, // Correctly uses Punycode host or normalized IP
      port: port,
      path:
          path, // Path has percent-encoding normalized, needs dot-segment normalization
      query: query, // Already percent-encoding normalized
      fragment: fragment, // Already percent-encoding normalized
    );

    // Apply path normalization (removes dot segments like '.' and '..')
    return constructedUri.normalizePath();

    // The structure above covers all valid combinations:
    // - Absolute IRI: scheme is non-null. finalHostForUri may or may not be null.
    // - Relative Ref - Network Path: scheme is null, finalHostForUri is non-null.
    // - Relative Ref - Absolute Path: scheme is null, finalHostForUri is null, path starts with '/'.
    // - Relative Ref - Relative Path: scheme is null, finalHostForUri is null, path doesn't start with '/'.
    // The Uri constructor handles these combinations correctly.
  }

  @override
  int get hashCode {
    // Use IterableEquality to compute a hash code based on the elements (code points).
    return const IterableEquality<int>().hash(_codepoints);
  }

  // From https://www.w3.org/TR/rdf12-concepts/#dfn-iri
  // Two IRIs are equal if and only if they consist of the same sequence of
  // Unicode code points, as in Simple String Comparison in section 5.3.1 of [RFC3987].
  // (This is done in the abstract syntax, so the IRIs are resolved IRIs with no
  // escaping or encoding.) Further normalization MUST NOT be performed before this comparison.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! IRI) return false;
    return const IterableEquality<int>().equals(_codepoints, other._codepoints);
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    if (hasScheme) {
      buffer.write(scheme);
      buffer.write(':'); // Only one slash needed here
    }

    // Handle authority part reconstruction
    if (hasAuthority) {
      buffer.write('//'); // Start authority marker

      final encUserInfo = _encodedUri.userInfo; // Use encoded for check
      if (encUserInfo.isNotEmpty) {
        buffer.write(userInfo); // Use the IRI-decoded getter result
        buffer.write('@');
      }

      final encodedHost = _encodedUri.host; // Host value without brackets
      // Get the raw encoded host from the Uri to check for IP Literal brackets
      final isIpLiteralHost = _encodedUri.authority.startsWith('[');

      if (isIpLiteralHost) {
        buffer.write('[');
        buffer.write(encodedHost);
        buffer.write(']');
      } else {
        buffer.write(host);
      }

      // Only include the port if it's explicit and non-standard
      // Use _encodedUri.port directly to check against default Uri behavior
      if (hasPort) {
        // We need to know the default port for the scheme to decide if we print it
        final defaultPort =
            Uri.parse('$scheme://host').port; // Default port lookup
        if (port != defaultPort) {
          buffer.write(':');
          buffer.write(port);
        }
      }
    } else if (hasScheme) {
      // Handle cases like "mailto:user@example.com" which have scheme but no authority marker
      // The path getter will handle the rest. If path is empty, nothing more is added.
    }

    // Append path, query, fragment using the IRI-decoded getters
    buffer.write(path); // Path getter now provides IRI-correct string

    if (hasQuery) {
      buffer.write('?');
      buffer.write(query); // Query getter now provides IRI-correct string
    }

    if (hasFragment) {
      buffer.write('#');
      buffer.write(fragment); // Fragment getter now provides IRI-correct string
    }

    // Handle relative references starting with "//" but without scheme
    // The logic above should cover this via hasAuthority check.
    // If !hasScheme && hasAuthority, it correctly starts with "//".

    // Handle rootless paths for relative references (no scheme, no authority)
    // If !hasScheme && !hasAuthority, the buffer just contains path+query+fragment.
    // Need to ensure path doesn't start with "//" if authority isn't present.
    // The parser (_convertToUri) should prevent invalid combinations,
    // and Uri normalisation handles path resolution.

    // Final check for relative network path case (no scheme, starts with //)
    final result = buffer.toString();
    if (!hasScheme &&
        _encodedUri.toString().startsWith('//') &&
        !result.startsWith('//')) {
      // This case indicates a network-path relative reference where our reconstruction
      // might have missed the leading '//' if the authority part was complex.
      // Prepend '//' if the original URI had it but our reconstruction doesn't.
      // (This might need refinement based on edge cases)
      // A simpler check might be: if !hasScheme && hasAuthority, ensure result starts with //
      if (hasAuthority) {
        return '//$result'; // Ensure leading // if authority exists without scheme
      }
    }

    return result;
  }

  // RFC 3986 Unreserved Characters: ALPHA / DIGIT / "-" / "." / "_" / "~"
  static const String _uriUnreservedChars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

  // RFC 3986 Sub-delimiters: "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," / ";" / "="
  static const String _uriSubDelimsChars = r"!$&'()*+,;=";

  // Characters generally allowed *without* percent-encoding within a URI path segment
  // pchar = unreserved / pct-encoded / sub-delims / ":" / "@"
  // We define the *non*-pct-encoded ones here for the check.
  // Note: We don't include '/' here because it's handled structurally.
  static const String _uriPathComponentAllowedChars =
      '$_uriUnreservedChars$_uriSubDelimsChars:@/';

  // Characters generally allowed *without* percent-encoding within a URI query
  // query = *( pchar / "/" / "?" )
  static const String _uriQueryAllowedChars =
      '$_uriPathComponentAllowedChars/?';

  // Characters generally allowed *without* percent-encoding within a URI fragment
  // fragment = *( pchar / "/" / "?" )
  static const String _uriFragmentAllowedChars =
      '$_uriPathComponentAllowedChars/?';

  // Characters generally allowed *without* percent-encoding within URI userinfo
  // userinfo = *( unreserved / pct-encoded / sub-delims / ":" )
  static const String _uriUserInfoAllowedChars =
      '$_uriUnreservedChars$_uriSubDelimsChars:';

  // Main parsing and normalization method
  static Map<String, dynamic> _parseAndNormalize(String iri) {
    var remaining = iri;
    String? fragment;
    String? query;
    String? scheme;
    String? authority;
    String? userInfo;
    // Variables to store host details
    String? hostRaw; // Host as extracted
    String? hostNormalized; // Host after type-specific normalization
    _HostType? hostType; // Enum for the type
    int? port;
    String path; // Will hold the parsed path before normalization

    // 1. Extract Fragment (Raw)
    final fragmentIndex = remaining.indexOf('#');
    if (fragmentIndex >= 0) {
      fragment = remaining.substring(fragmentIndex + 1);
      remaining = remaining.substring(0, fragmentIndex);
    }

    // 2. Extract Query (Raw)
    final queryIndex = remaining.indexOf('?');
    if (queryIndex >= 0) {
      query = remaining.substring(queryIndex + 1);
      remaining = remaining.substring(0, queryIndex);
    }

    // 3. Extract Scheme (Raw + Normalize Case)
    final schemeIndex = remaining.indexOf(':');
    final firstSlashIndex = remaining.indexOf('/');
    if (schemeIndex > 0 &&
        (firstSlashIndex == -1 || schemeIndex < firstSlashIndex)) {
      final potentialScheme = remaining.substring(0, schemeIndex);
      if (_IRIRegexHelper.matchScheme(potentialScheme)) {
        scheme = potentialScheme.toLowerCase(); // Case normalization
        remaining = remaining.substring(schemeIndex + 1);
      } else {
        throw FormatException(
          'Invalid scheme format: $potentialScheme in $iri',
        );
      }
    } else if (schemeIndex == 0) {
      throw FormatException('IRI cannot start with a colon: $iri');
    }

    // 4. Extract Authority (Raw) and Path (Raw)
    if (remaining.startsWith('//')) {
      remaining = remaining.substring(
        2,
      ); // Remove '//', e.g., remaining = "user/name@example.com/"

      // Find the end of the authority part: the first '/' that marks the beginning of the path,
      // or the end of the string if no path follows.
      final pathStartIndex = remaining.indexOf('/');

      if (pathStartIndex == -1) {
        // No slash found, the entire remaining string is the authority
        authority = remaining; // e.g., "user/name@example.com"

        // Path is empty. Normalize it with a / per IRI guidelines outlined here
        // https://www.rfc-editor.org/rfc/rfc3987#section-5.3.3
        path = '/';
      } else {
        // Slash found, split authority and path
        authority = remaining.substring(
          0,
          pathStartIndex,
        ); // e.g., "user/name@example.com"
        path = remaining.substring(pathStartIndex); // e.g., "/"
      }

      // --- Start Authority Parsing (using the correctly extracted 'authority' string) ---
      // RFC 3986 requires authority to be non-empty if '//' is present.
      if (authority.isNotEmpty) {
        // Parse the extracted 'authority' string (e.g., "user/name@example.com")
        final authToParse = authority;
        final userInfoIndex = authToParse.lastIndexOf('@');
        final hostStartIndex = userInfoIndex >= 0 ? userInfoIndex + 1 : 0;

        if (userInfoIndex >= 0) {
          // Extract userInfo from the authority string
          userInfo = authToParse.substring(
            0,
            userInfoIndex,
          ); // e.g., "user/name"
        } else {
          // Ensure userInfo is null if no '@' is found
          userInfo = null;
        }

        // Process the host+port part from the authority string
        final hostAndPortString = authToParse.substring(
          hostStartIndex,
        ); // e.g., "example.com"

        // --- Separate Host and Port ---
        String potentialHost;
        final ipv6EndBracketIndex = hostAndPortString.lastIndexOf(']');
        final portSeparatorIndex = hostAndPortString.indexOf(
          ':',
          (ipv6EndBracketIndex == -1) ? 0 : ipv6EndBracketIndex + 1,
        );

        if (portSeparatorIndex != -1) {
          // Colon found after potential IPv6 literal
          final potentialPort = hostAndPortString.substring(
            portSeparatorIndex + 1,
          );
          // Check if potentialPort is all digits and non-empty
          if (potentialPort.isNotEmpty &&
              potentialPort.runes.every((r) => r >= 48 && r <= 57)) {
            port = int.tryParse(potentialPort); // Should succeed
            potentialHost = hostAndPortString.substring(0, portSeparatorIndex);
            if (port == null) {
              // Should not happen based on checks, but defense in depth
              throw FormatException(
                'Invalid port format: $potentialPort in $iri',
              );
            }
          } else if (potentialPort.isEmpty) {
            // Case like "host:", port is empty string, maps to null (default port)
            port = null;
            potentialHost = hostAndPortString.substring(0, portSeparatorIndex);
          } else {
            // Colon present but not followed by valid digits -> invalid port, treat colon as part of host
            port = null;
            potentialHost =
                hostAndPortString; // Includes the colon and invalid port string
          }
        } else {
          // No port separator found after host
          potentialHost = hostAndPortString;
          port = null;
        }

        // Host cannot be empty if authority is present
        if (potentialHost.isEmpty) {
          throw FormatException(
            'Host cannot be empty when authority is present: $iri',
          );
        }

        // --- Determine Host Type and Normalize ---
        hostRaw = potentialHost; // e.g., "example.com"
        if (_IRIRegexHelper.isIpLiteral(potentialHost)) {
          hostType = _HostType.ipLiteral;
          // Normalize IPv6/IPvFuture (and reject IPvFuture)
          final openBracket = potentialHost.indexOf('[');
          final closeBracket = potentialHost.lastIndexOf(']');
          if (openBracket != -1 && closeBracket > openBracket) {
            final ipContent = potentialHost.substring(
              openBracket + 1,
              closeBracket,
            );
            if (ipContent.startsWith('v') || ipContent.startsWith('V')) {
              // Reject IPvFuture explicitly as Uri class doesn't support it
              throw FormatException(
                'Unsupported host format: IPvFuture literals (e.g., "[vX.Y]") are not supported by the underlying Uri class.',
                iri,
              );
            } else {
              // Standard IPv6 normalization (lowercase hex)
              hostNormalized = '[${ipContent.toLowerCase()}]';
            }
          } else {
            // Should not happen if isIpLiteral is true (malformed literal)
            throw FormatException(
              'Malformed IP Literal host: $potentialHost',
              iri,
            );
          }
        } else if (_IRIRegexHelper.isIPv4Address(potentialHost)) {
          hostType = _HostType.ipv4Address;
          hostNormalized = potentialHost; // No normalization needed
        } else {
          // Fallback: Assume registered name. Could add isRegisteredName check for stricter validation.
          hostType = _HostType.registeredName;
          hostNormalized =
              potentialHost
                  .toLowerCase(); // Case normalization, e.g., "example.com"
        }
      } else {
        // Authority marker '//' was present, but authority string was empty (e.g., "http:///path")
        // This is invalid according to RFC 3986 Section 3.2.
        throw FormatException(
          'Authority cannot be empty when authority marker "//" is present: $iri',
        );
      }
      // --- End Authority Parsing ---
    } else {
      // No authority marker "//" found after scheme (or no scheme)
      authority = null; // Ensure authority component is null
      path = remaining; // The entire remaining string is the path

      // Ensure host/port/userInfo details are null if there's no authority
      userInfo = null;
      hostRaw = null;
      hostNormalized = null;
      hostType = null;
      port = null;
    }

    // --- Step 5: Normalize Other Components (Percent Encoding) ---
    // Now userInfo should be correctly extracted ("user/name") before normalization
    if (userInfo != null) {
      userInfo = _normalizePercentEncoding(
        userInfo,
        _uriUserInfoAllowedChars,
      ); // Should encode '/'
    }

    // Normalize path (now correctly receives "/" or the actual path part)
    path = _normalizePercentEncoding(
      path,
      _uriPathComponentAllowedChars,
    ); // Should preserve '/'

    if (query != null) {
      query = _normalizePercentEncoding(query, _uriQueryAllowedChars);
    }
    if (fragment != null) {
      fragment = _normalizePercentEncoding(fragment, _uriFragmentAllowedChars);
    }

    if (path.endsWith('%25')) {
      throw FormatException('Invalid IRI: $iri');
    }

    // Return map of *normalized* components including host details
    return {
      'scheme': scheme,
      'userInfo': userInfo,
      'hostRaw': hostRaw, // Raw extracted host
      'hostNormalized': hostNormalized, // Normalized host (case, etc.)
      'hostType': hostType, // Enum: ipLiteral, ipv4Address, registeredName
      'port': port,
      'path':
          path, // Path after percent normalization (dot segments handled later)
      'query': query,
      'fragment': fragment,
    };
  }

  /// Percent-encodes characters in an IRI component string to make it URI-compatible.
  ///
  /// It iterates through the input string and applies UTF-8 based percent-encoding
  /// to characters that are *not* in the `allowedChars` set and are *not* already
  /// part of a valid percent-encoding sequence (`%XX`).
  ///
  /// Args:
  ///   input: The IRI component string (e.g., path segment, query, fragment).
  ///   allowedChars: A string containing all characters allowed to appear *unencoded*
  ///                 in the corresponding *URI* component.
  ///
  /// Returns:
  ///   A string safe to use in a URI component.
  static String _normalizePercentEncoding(String input, String allowedChars) {
    final output = StringBuffer();
    // Create a Set for faster character lookup
    final allowedCharCodes = allowedChars.codeUnits.toSet();

    // We need to work with bytes for UTF-8 encoding and hex conversion
    final inputBytes = utf8.encode(input);

    for (var i = 0; i < inputBytes.length; i++) {
      final byte = inputBytes[i];

      // Check for existing percent encoding (%XX)
      // ASCII '%' is 37 (0x25)
      if (byte == 0x25) {
        // Check if there are enough characters left for a valid sequence
        if (i + 2 < inputBytes.length &&
            _isHexDigit(inputBytes[i + 1]) &&
            _isHexDigit(inputBytes[i + 2])) {
          // Valid %XX sequence found, append it directly
          output.write('%');
          output.writeCharCode(inputBytes[i + 1]);
          output.writeCharCode(inputBytes[i + 2]);
          i += 2; // Skip the two hex digits
          continue; // Move to the next byte
        }
        // If it's '%' but not followed by two hex digits, it's a literal '%'
        // that needs encoding itself according to RFC 3986.
        // Fall through to the encoding logic below.
      }

      // Check if the byte corresponds to a character in the allowed set
      // This works reliably only for single-byte characters (ASCII range)
      // For IRI processing, the assumption is that `allowedChars` contains only ASCII.
      // Non-ASCII chars from the IRI are *never* in `allowedChars` and will be encoded.
      if (byte < 128 && allowedCharCodes.contains(byte)) {
        // Allowed ASCII character, append directly
        output.writeCharCode(byte);
      } else {
        // Character is not allowed or is non-ASCII, percent-encode it
        output.write('%');
        output.write(byte.toRadixString(16).toUpperCase().padLeft(2, '0'));
      }
    }

    return output.toString();
  }

  /// Helper to check if a byte value represents an ASCII hex digit (0-9, A-F, a-f).
  static bool _isHexDigit(int byte) {
    return (byte >= 0x30 && byte <= 0x39) || // 0-9
        (byte >= 0x41 && byte <= 0x46) || // A-F
        (byte >= 0x61 && byte <= 0x66); // a-f
  }

  /// Decodes a percent-encoded URI component string into its IRI representation.
  ///
  /// It selectively decodes percent-encoded sequences based on whether the
  /// resulting character is allowed *unencoded* in the target IRI component context.
  ///
  /// - Decodes sequences representing valid IRI characters (`iunreserved`, `sub-delims`, etc.
  ///   depending on the component type).
  /// - Leaves sequences representing characters that *must* remain encoded in an IRI
  ///   (like space `%20` in a path) as they are (normalized to uppercase hex).
  /// - Handles UTF-8 decoding for multi-byte characters.
  ///
  /// Args:
  ///   encodedInput: The percent-encoded string from the `Uri` component.
  ///   allowedAsciiChars: A string containing ASCII characters allowed unencoded
  ///                      in the target *IRI* component.
  ///   allowIprivate: Whether to allow `iprivate` characters (used for query component).
  ///
  /// Returns:
  ///   The decoded IRI component string.
  static String _decodeIriComponent(
    String encodedInput,
    String allowedAsciiChars, {
    bool allowIprivate = false,
  }) {
    final allowedAsciiCodes = allowedAsciiChars.codeUnits.toSet();
    final output = StringBuffer();
    final bytes = <int>[]; // Buffer for potential multi-byte UTF-8 sequences

    // Regular expression to find percent-encoded sequences or other characters
    final pattern = RegExp('(%[0-9a-fA-F]{2})|.');
    final matches = pattern.allMatches(encodedInput);

    for (final match in matches) {
      final group = match.group(0)!;
      if (group.startsWith('%')) {
        // Found a percent-encoded sequence
        try {
          final byteValue = int.parse(group.substring(1), radix: 16);
          bytes.add(byteValue);

          // Try to decode the current byte sequence as UTF-8
          String decodedChar;
          try {
            // Use RuneIterator to handle potential surrogate pairs correctly
            final runeIterator = _RuneIterator.fromBytes(bytes);
            if (!runeIterator.moveNext()) {
              // Not enough bytes for a full character yet, continue accumulating
              continue;
            }
            final rune = runeIterator.current;
            // Check if there are remaining bytes (invalid sequence)
            if (runeIterator.moveNext()) {
              // If we could advance again, it means the previous bytes
              // formed a valid char, but there are leftover bytes.
              // This indicates an invalid sequence overall. Treat as undecodable.
              throw const FormatException('Invalid UTF-8 sequence');
            }
            decodedChar = String.fromCharCode(rune);
            // Successfully decoded a character, clear the byte buffer
            bytes.clear();

            // --- Check if the decoded character should remain encoded ---
            var isAllowedUnencoded = false;
            final charCode =
                decodedChar.runes.first; // Get the Unicode code point

            // 1. Check ASCII allowed set
            if (charCode < 128 && allowedAsciiCodes.contains(charCode)) {
              isAllowedUnencoded = true;
            }
            // 2. Check if it's an iunreserved character (includes ucschar)
            else if (_IRIRegexHelper._isIriUnreserved(charCode)) {
              isAllowedUnencoded = true;
            }
            // 3. Check sub-delims (already covered by allowedAsciiCodes if applicable)
            // else if (_subDelimsChars.contains(decodedChar)) { ... }
            // 4. Check component-specific extras (:, @, /, ?)
            // (already covered by allowedAsciiCodes if applicable)
            // 5. Check iprivate (only for query)
            else if (allowIprivate && _IRIRegexHelper._isIprivate(charCode)) {
              isAllowedUnencoded = true;
            }

            if (isAllowedUnencoded) {
              output.write(decodedChar); // Append the decoded character
            } else {
              // Character is not allowed unencoded in this IRI component
              // Append the original percent-encoded sequence (normalized)
              output.write(group.toUpperCase());
            }
          } on FormatException {
            // UTF-8 decoding failed for the current byte sequence.
            // This might mean it's an incomplete sequence, or invalid bytes.
            // If it's the last match, or the next match isn't '%',
            // treat the buffered bytes as literals to be re-encoded.
            // For simplicity now, let's assume the Uri encoding was valid
            // and a failed decode implies we should keep the original encoding.
            // Re-append the *first* byte's encoding and clear buffer.
            // This might be imperfect for complex invalid sequences.
            if (bytes.isNotEmpty) {
              output.write(
                '%${bytes.first.toRadixString(16).toUpperCase().padLeft(2, '0')}',
              );
              bytes.clear();
            }
          }
        } on Exception catch (_) {
          // Error parsing hex or other issue - append original group
          output.write(group.toUpperCase());
          bytes.clear(); // Clear buffer on error
        }
      } else {
        // Not a percent sign - check if bytes buffer should be flushed
        if (bytes.isNotEmpty) {
          // We encountered a non-% char after accumulating bytes that didn't form
          // a valid UTF-8 char. Flush the buffer as normalized % sequences.
          for (final byte in bytes) {
            output.write(
              '%${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}',
            );
          }
          bytes.clear();
        }
        // Append the literal character
        output.write(group);
      }
    }

    // Flush any remaining bytes in the buffer (e.g., incomplete sequence at the end)
    if (bytes.isNotEmpty) {
      for (final byte in bytes) {
        output.write(
          '%${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}',
        );
      }
    }

    return output.toString();
  }
}

// Intentional static helper class
// ignore: avoid_classes_with_only_static_members
/// Regular expressions for IRI components
/// The following rules are different from those in 'RFC3986':
///
/// ```abnf
/// IRI            = scheme ":" ihier-part [ "?" iquery ]
///                       [ "#" ifragment ]
///
/// ihier-part     = "//" iauthority ipath-abempty
///                / ipath-absolute
///                / ipath-rootless
///                / ipath-empty
///
/// IRI-reference  = IRI / irelative-ref
///
/// absolute-IRI   = scheme ":" ihier-part [ "?" iquery ]
///
/// irelative-ref  = irelative-part [ "?" iquery ] [ "#" ifragment ]
///
/// irelative-part = "//" iauthority ipath-abempty
///                     / ipath-absolute
///                   / ipath-noscheme
///                / ipath-empty
///
/// iauthority     = [ iuserinfo "@" ] ihost [ ":" port ]
/// iuserinfo      = *( iunreserved / pct-encoded / sub-delims / ":" )
/// ihost          = IP-literal / IPv4address / ireg-name
///
/// ireg-name      = *( iunreserved / pct-encoded / sub-delims )
///
/// ipath          = ipath-abempty   ; begins with "/" or is empty
///                / ipath-absolute  ; begins with "/" but not "//"
///                / ipath-noscheme  ; begins with a non-colon segment
///                / ipath-rootless  ; begins with a segment
///                / ipath-empty     ; zero characters
///
/// ipath-abempty  = *( "/" isegment )
/// ipath-absolute = "/" [ isegment-nz *( "/" isegment ) ]
/// ipath-noscheme = isegment-nz-nc *( "/" isegment )
/// ipath-rootless = isegment-nz *( "/" isegment )
/// ipath-empty    = 0<ipchar>
///
/// isegment       = *ipchar
/// isegment-nz    = 1*ipchar
/// isegment-nz-nc = 1*( iunreserved / pct-encoded / sub-delims
///                      / "@" )
///                ; non-zero-length segment without any colon ":"
///
/// ipchar         = iunreserved / pct-encoded / sub-delims / ":"
///                / "@"
///
/// iquery         = *( ipchar / iprivate / "/" / "?" )
///
/// ifragment      = *( ipchar / "/" / "?" )
///
/// iunreserved    = ALPHA / DIGIT / "-" / "." / "_" / "~" / ucschar
///
/// ucschar        = %xA0-D7FF / %xF900-FDCF / %xFDF0-FFEF
///                / %x10000-1FFFD / %x20000-2FFFD / %x30000-3FFFD
///                / %x40000-4FFFD / %x50000-5FFFD / %x60000-6FFFD
///                / %x70000-7FFFD / %x80000-8FFFD / %x90000-9FFFD
///                / %xA0000-AFFFD / %xB0000-BFFFD / %xC0000-CFFFD
///                / %xD0000-DFFFD / %xE1000-EFFFD
///
/// iprivate       = %xE000-F8FF / %xF0000-FFFFD / %x100000-10FFFD
///```
///
/// Some productions are ambiguous.  The "first-match-wins" (a.k.a.
/// "greedy") algorithm applies.  For details, see 'RFC3986'.
///
/// The following rules are the same as those in 'RFC3986':
/// ```abnf
/// scheme         = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
///
/// port           = *DIGIT
///
/// IP-literal     = "[" ( IPv6address / IPvFuture  ) "]"
///
/// IPvFuture      = "v" 1*HEXDIG "." 1*( unreserved / sub-delims / ":" )
///
/// IPv6address    =                            6( h16 ":" ) ls32
///                /                       "::" 5( h16 ":" ) ls32
///                / [               h16 ] "::" 4( h16 ":" ) ls32
///                / [ *1( h16 ":" ) h16 ] "::" 3( h16 ":" ) ls32
///                / [ *2( h16 ":" ) h16 ] "::" 2( h16 ":" ) ls32
///                / [ *3( h16 ":" ) h16 ] "::"    h16 ":"   ls32
///                / [ *4( h16 ":" ) h16 ] "::"              ls32
///                / [ *5( h16 ":" ) h16 ] "::"              h16
///                / [ *6( h16 ":" ) h16 ] "::"
///
/// h16            = 1*4HEXDIG
/// ls32           = ( h16 ":" h16 ) / IPv4address
///
/// IPv4address    = dec-octet "." dec-octet "." dec-octet "." dec-octet
///
/// dec-octet      = DIGIT                 ; 0-9
///                / %x31-39 DIGIT         ; 10-99
///                / "1" 2DIGIT            ; 100-199
///                / "2" %x30-34 DIGIT     ; 200-249
///                / "25" %x30-35          ; 250-255
///
/// pct-encoded    = "%" HEXDIG HEXDIG
///
/// unreserved     = ALPHA / DIGIT / "-" / "." / "_" / "~"
/// reserved       = gen-delims / sub-delims
/// gen-delims     = ":" / "/" / "?" / "#" / "[" / "]" / "@"
/// sub-delims     = "!" / "$" / "&" / "'" / "(" / ")"
///                / "*" / "+" / "," / ";" / "="
/// ```
class _IRIRegexHelper {
  static const String _scheme = r'[a-zA-Z][a-zA-Z0-9+\-.]*';
  static const String _ucschar =
      r'[\u{a0}-\u{d7ff}\u{f900}-\u{fdcf}\u{fdf0}-\u{ffef}\u{10000}-\u{1fffd}\u{20000}-\u{2fffd}\u{30000}-\u{3fffd}\u{40000}-\u{4fffd}\u{50000}-\u{5fffd}\u{60000}-\u{6fffd}\u{70000}-\u{7fffd}\u{80000}-\u{8fffd}\u{90000}-\u{9fffd}\u{a0000}-\u{afffd}\u{b0000}-\u{bfffd}\u{c0000}-\u{cfffd}\u{d0000}-\u{dfffd}\u{e1000}-\u{efffd}]';
  static const String _iunreserved = '([a-zA-Z0-9\\-._~]|$_ucschar)';
  static const String _pctEncoded = '%[0-9A-Fa-f][0-9A-Fa-f]';
  static const String _subDelims = r"[!$&'()*+,;=]";
  static const String _iuserinfo =
      '($_iunreserved|$_pctEncoded|$_subDelims|:)*';
  static const String _h16 = '[0-9A-Fa-f]{1,4}';
  static const String _decOctet =
      '([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])';
  static const String _ipv4address =
      '$_decOctet\\.$_decOctet\\.$_decOctet\\.$_decOctet';
  static const String _ls32 = '($_h16:$_h16|$_ipv4address)';
  static const String _ipv6address =
      '(($_h16:){6}$_ls32|::($_h16:){5}$_ls32|($_h16)?::($_h16:){4}$_ls32|(($_h16:)?$_h16)?::($_h16:){3}$_ls32|(($_h16:){0,2}$_h16)?::($_h16:){2}$_ls32|(($_h16:){0,3}$_h16)?::$_h16:$_ls32|(($_h16:){0,4}$_h16)?::$_ls32|(($_h16:){0,5}$_h16)?::$_h16|(($_h16:){0,6}$_h16)?::)';
  static const String _unreserved = r'[a-zA-Z0-9\-._~]';
  static const String _ipvfuture =
      '[vV][0-9A-Fa-f]+\\.($_unreserved|$_subDelims|:)+';
  static const String _ipLiteral = '\\[($_ipv6address|$_ipvfuture)\\]';
  static const String _iregName = '($_iunreserved|$_pctEncoded|$_subDelims)*';
  static const String _ihost = '($_ipLiteral|$_ipv4address|$_iregName)';
  static const String _port = '[0-9]*';
  static const String _iauthority = '($_iuserinfo@)?$_ihost(:$_port)?';
  static const String _ipchar = '($_iunreserved|$_pctEncoded|$_subDelims|[:@])';
  static const String _isegment = '($_ipchar)*';
  static const String _ipathAbempty = '(/$_isegment)*';
  static const String _isegmentNz = '($_ipchar)+';
  static const String _ipathAbsolute = '/($_isegmentNz(/$_isegment)*)?';
  static const String _ipathRootless = '$_isegmentNz(/$_isegment)*';
  static const String _ipathEmpty = '($_ipchar){0}';
  static const String _ihierPart =
      '(//$_iauthority$_ipathAbempty|$_ipathAbsolute|$_ipathRootless|$_ipathEmpty)';
  static const String _iprivate =
      r'[\u{e000}-\u{f8ff}\u{f0000}-\u{ffffd}\u{100000}-\u{10fffd}]';
  static const String _iquery = '($_ipchar|$_iprivate|[/?])*';
  static const String _ifragment = '($_ipchar|[/?])*';
  static const String _isegmentNzNc =
      '($_iunreserved|$_pctEncoded|$_subDelims|@)+';
  static const String _ipathNoscheme = '$_isegmentNzNc(/$_isegment)*';
  static const String _irelativePart =
      '(//$_iauthority$_ipathAbempty|$_ipathAbsolute|$_ipathNoscheme|$_ipathEmpty)';
  static const String _irelativeRef =
      '$_irelativePart(\\?$_iquery)?(#$_ifragment)?';
  static const String _iri =
      '$_scheme:$_ihierPart(\\?$_iquery)?(#$_ifragment)?';
  static const String _iriReference = '($_iri|$_irelativeRef)';

  static final patterns = (
    scheme: _scheme,
    ucschar: _ucschar,
    iunreserved: _iunreserved,
    pctEncoded: _pctEncoded,
    subDelims: _subDelims,
    iuserinfo: _iuserinfo,
    h16: _h16,
    decOctet: _decOctet,
    ipv4address: _ipv4address,
    ls32: _ls32,
    ipv6address: _ipv6address,
    unreserved: _unreserved,
    ipvfuture: _ipvfuture,
    ipLiteral: _ipLiteral,
    iregName: _iregName,
    ihost: _ihost,
    port: _port,
    iauthority: _iauthority,
    ipchar: _ipchar,
    isegment: _isegment,
    ipathAbempty: _ipathAbempty,
    isegmentNz: _isegmentNz,
    ipathAbsolute: _ipathAbsolute,
    ipathRootless: _ipathRootless,
    ipathEmpty: _ipathEmpty,
    ihierPart: _ihierPart,
    iprivate: _iprivate,
    iquery: _iquery,
    ifragment: _ifragment,
    isegmentNzNc: _isegmentNzNc,
    ipathNoscheme: _ipathNoscheme,
    irelativePart: _irelativePart,
    irelativeRef: _irelativeRef,
    iri: _iri,
    iriReference: _iriReference,
  );

  static bool matchScheme(String input) =>
      RegExp('^$_scheme\$').hasMatch(input);

  static bool isIpLiteral(String input) =>
      RegExp('^$_ipLiteral\$').hasMatch(input);

  static bool isIPv4Address(String input) =>
      RegExp('^$_ipv4address\$').hasMatch(input);

  // RFC 3987 iunreserved = ALPHA / DIGIT / "-" / "." / "_" / "~" / ucschar
  // Define the ASCII part first
  static const String _iriUnreservedAsciiChars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

  // RFC 3986 Sub-delimiters: "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," / ";" / "="
  static const String _subDelimsChars =
      r"!$&'()*+,;="; // Same as URI sub-delims

  // Characters allowed unencoded in IRI path segments (ipchar minus '/')
  // ipchar = iunreserved / pct-encoded / sub-delims / ":" / "@"
  static const String _iriPathComponentAllowedAsciiChars =
      '$_iriUnreservedAsciiChars$_subDelimsChars:@';

  // Characters allowed unencoded in IRI query (ipchar / iprivate / "/" / "?")
  // We'll handle iprivate check dynamically if needed, focus on ASCII for the set
  static const String _iriQueryAllowedAsciiChars =
      '$_iriPathComponentAllowedAsciiChars/?';

  // Characters allowed unencoded in IRI fragment (ipchar / "/" / "?")
  static const String _iriFragmentAllowedAsciiChars =
      '$_iriPathComponentAllowedAsciiChars/?';

  // Characters allowed unencoded in IRI userinfo (iunreserved / pct-encoded / sub-delims / ":")
  static const String _iriUserInfoAllowedAsciiChars =
      '$_iriUnreservedAsciiChars$_subDelimsChars:';

  // Helper Set for faster ASCII lookups in the decoder
  static final Set<int> _iriUnreservedAsciiCodes =
      _iriUnreservedAsciiChars.codeUnits.toSet();

  // Regular expression to match the ucschar ranges from RFC 3987
  // ucschar = %xA0-D7FF / %xF900-FDCF / %xFDF0-FFEF / %x10000-1FFFD / ... / %xE1000-EFFFD
  // (Simplified for this check - we just need to know if a decoded char is in these ranges)
  // We can create a helper function for this check.
  static bool _isUcschar(int charCode) {
    return (charCode >= 0xA0 && charCode <= 0xD7FF) ||
        (charCode >= 0xF900 && charCode <= 0xFDCF) ||
        (charCode >= 0xFDF0 && charCode <= 0xFFEF) ||
        (charCode >= 0x10000 && charCode <= 0x1FFFD) ||
        (charCode >= 0x20000 && charCode <= 0x2FFFD) ||
        (charCode >= 0x30000 && charCode <= 0x3FFFD) ||
        (charCode >= 0x40000 && charCode <= 0x4FFFD) ||
        (charCode >= 0x50000 && charCode <= 0x5FFFD) ||
        (charCode >= 0x60000 && charCode <= 0x6FFFD) ||
        (charCode >= 0x70000 && charCode <= 0x7FFFD) ||
        (charCode >= 0x80000 && charCode <= 0x8FFFD) ||
        (charCode >= 0x90000 && charCode <= 0x9FFFD) ||
        (charCode >= 0xA0000 && charCode <= 0xAFFFD) ||
        (charCode >= 0xB0000 && charCode <= 0xBFFFD) ||
        (charCode >= 0xC0000 && charCode <= 0xCFFFD) ||
        (charCode >= 0xD0000 && charCode <= 0xDFFFD) ||
        (charCode >= 0xE1000 && charCode <= 0xEFFFD);
  }

  // RFC 3987 iprivate characters (for query component)
  static bool _isIprivate(int charCode) {
    return (charCode >= 0xE000 && charCode <= 0xF8FF) ||
        (charCode >= 0xF0000 && charCode <= 0xFFFFD) ||
        (charCode >= 0x100000 && charCode <= 0x10FFFD);
  }

  // Helper to check if a character is an IRI 'iunreserved' character
  static bool _isIriUnreserved(int charCode) {
    return _iriUnreservedAsciiCodes.contains(charCode) || _isUcschar(charCode);
  }
}

enum _HostType { ipLiteral, ipv4Address, registeredName }

/// Helper class to decode UTF-8 bytes incrementally.
/// Needed because standard utf8.decode might throw on incomplete sequences
/// when processing chunks.
class _RuneIterator implements Iterator<int> {
  final List<int> _bytes;
  int _offset = 0;
  int _currentRune = -1;

  _RuneIterator.fromBytes(List<int> bytes) : _bytes = List.unmodifiable(bytes);

  @override
  int get current => _currentRune;

  @override
  bool moveNext() {
    if (_offset >= _bytes.length) {
      _currentRune = -1;
      return false; // No more bytes
    }

    final byte1 = _bytes[_offset];
    int expectedLength;

    // Determine expected sequence length from the first byte
    if (byte1 < 0x80) {
      // 0xxxxxxx (ASCII)
      expectedLength = 1;
    } else if ((byte1 & 0xE0) == 0xC0) {
      // 110xxxxx
      expectedLength = 2;
    } else if ((byte1 & 0xF0) == 0xE0) {
      // 1110xxxx
      expectedLength = 3;
    } else if ((byte1 & 0xF8) == 0xF0) {
      // 11110xxx
      expectedLength = 4;
    } else {
      // Invalid UTF-8 start byte
      _currentRune = -1;
      // Optional: Advance offset by 1 to skip? Or treat as failure.
      // Let's treat as failure for now.
      // _offset++; return moveNext(); // Alternative: skip and retry
      return false;
    }

    // Check if enough bytes are available for the expected sequence
    if (_offset + expectedLength > _bytes.length) {
      // Incomplete sequence at the end
      _currentRune = -1;
      return false;
    }

    // Extract the bytes for this potential sequence
    final sequenceBytes = _bytes.sublist(_offset, _offset + expectedLength);

    // Validate continuation bytes (must start with 10xxxxxx)
    if (expectedLength > 1) {
      for (var i = 1; i < expectedLength; i++) {
        if ((sequenceBytes[i] & 0xC0) != 0x80) {
          // Invalid continuation byte
          _currentRune = -1;
          // Optional: Advance offset by 1? Or treat as failure.
          return false;
        }
      }
    }

    // Attempt to decode the extracted sequence strictly
    try {
      // Use allowMalformed: false to catch invalid sequences like overlong encodings
      final decodedString = utf8.decode(sequenceBytes, allowMalformed: false);

      // Ensure exactly one rune was decoded
      if (decodedString.runes.length != 1) {
        throw const FormatException(
          'Decoded zero or multiple runes from sequence.',
        );
      }
      _currentRune = decodedString.runes.first;

      // Additional check: Reject surrogate code points U+D800 to U+DFFF as invalid in UTF-8
      if (_currentRune >= 0xD800 && _currentRune <= 0xDFFF) {
        throw FormatException('Decoded invalid surrogate code point.');
      }

      // If successful, advance the offset
      _offset += expectedLength;
      return true;
    } on Exception catch (_) {
      // Decoding failed (invalid sequence, overlong, etc.)
      _currentRune = -1;
      // Optional: Advance offset by 1? Or treat as failure.
      return false;
    }
  }
}
