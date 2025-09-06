/// Centralized link builder for shareable/canonical URLs.
/// Adjust `kCanonicalWebBaseUrl` if the hosted domain changes.
const String kCanonicalWebBaseUrl = 'https://vaadly-project.web.app';

class AppLinks {
  /// Returns the shareable Building Portal URL.
  /// By default uses the canonical hosted web origin so links are unique and stable.
  /// When `canonical` is false, falls back to the current runtime origin (useful during local dev).
  static String buildingPortal(String code, {bool canonical = true}) {
    final origin = canonical ? kCanonicalWebBaseUrl : Uri.base.origin;
    // App currently uses hash routing (/#/...) for deep links on web
    return '$origin/#/building/$code';
  }

  /// Returns the Committee/Management Portal URL for a building code.
  /// Uses the canonical web origin by default to ensure shareable stability.
  static String managePortal(String code, {bool canonical = true}) {
    final origin = canonical ? kCanonicalWebBaseUrl : Uri.base.origin;
    return '$origin/#/manage/$code';
  }
}
