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
         queryParameters: queryParameters?.map((k, v) {
           return MapEntry(unorm.nfkc(k), v is String ? unorm.nfkc(v) : v);
         }),
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
         queryParameters?.map((k, v) {
           return MapEntry(unorm.nfkc(k), v is String ? unorm.nfkc(v) : v);
         }),
       );

  /// Creates a new https IRI from its components.
  Iri.https(
    String host, [
    String path = '',
    Map<String, dynamic>? queryParameters,
  ]) : _uri = Uri.https(
         unorm.nfkc(host),
         unorm.nfkc(path),
         queryParameters?.map((k, v) {
           return MapEntry(unorm.nfkc(k), v is String ? unorm.nfkc(v) : v);
         }),
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

  /// The scheme of this IRI.
  String get scheme => _uri.scheme;

  /// The Unicode-aware host of this IRI.
  ///
  /// If the host was Punycode-encoded (e.g., from a [Uri]), it is decoded back
  /// to its Unicode representation.
  String get host {
    final decoded = Uri.decodeComponent(_uri.host);
    return domainToUnicode(decoded);
  }

  /// The Unicode-aware path of this IRI.
  String get path {
    final decoded = Uri.decodeComponent(_uri.path);
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
  String get query => Uri.decodeComponent(_uri.query);

  /// The Unicode-aware fragment of this IRI.
  String get fragment => Uri.decodeComponent(_uri.fragment);

  /// The Unicode-aware user information of this IRI.
  String get userInfo => Uri.decodeComponent(_uri.userInfo);

  /// The port of this IRI.
  int get port => _uri.port;

  /// The URI query parameters as a map.
  Map<String, String> get queryParameters => _uri.queryParameters;

  /// The URI path segments as an iterable.
  List<String> get pathSegments => _uri.pathSegments;

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
        queryParameters: queryParameters?.map((k, v) {
          return MapEntry(unorm.nfkc(k), v is String ? unorm.nfkc(v) : v);
        }),
        fragment: fragment != null ? unorm.nfkc(fragment) : null,
      ),
    );
  }

  /// Converts this IRI to a standard [Uri].
  ///
  /// Any non-ASCII characters in the hostname are converted to Punycode
  /// according to RFC 3492. Other components are percent-encoded using UTF-8.
  Uri toUri() {
    if (scheme == 'mailto') {
      final decodedPath = Uri.decodeComponent(_uri.path);
      try {
        final punyEmail = emailToAscii(decodedPath, validate: false);
        return _uri.replace(path: punyEmail);
      } on FormatException {
        return _uri;
      }
    }

    final decodedHost = Uri.decodeComponent(_uri.host);
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
  String toUriString() => _uri.toString();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Iri && toUri() == other.toUri());

  @override
  int get hashCode => toUri().hashCode;
}
