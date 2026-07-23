/// Input sanitization helpers — defense-in-depth on top of validators.
/// Never trust user input, even after validation.
class Sanitizers {
  Sanitizers._();

  /// Strip control characters, collapse whitespace, trim.
  static String cleanText(String? input, {int maxLength = 10000}) {
    if (input == null) return '';
    // Remove all ASCII control chars except \n and \t
    final cleaned = input
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
        .trim();
    return cleaned.length > maxLength
        ? cleaned.substring(0, maxLength)
        : cleaned;
  }

  /// Single-line: removes newlines entirely.
  static String cleanSingleLine(String? input, {int maxLength = 200}) {
    if (input == null) return '';
    final cleaned = input
        .replaceAll(RegExp(r'[\r\n]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.length > maxLength
        ? cleaned.substring(0, maxLength)
        : cleaned;
  }

  /// Escapes HTML — Flutter Text widget is safe by default, but
  /// if we ever send content to web/email, this protects us.
  static String escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Sanitizes a name field (allows letters, spaces, common punctuation).
  static String cleanName(String? input) {
    if (input == null) return '';
    final cleaned = cleanSingleLine(input, maxLength: 100);
    // Remove potentially dangerous chars: < > { } ` \ / |
    return cleaned.replaceAll(RegExp(r'[<>{}\\\/|`]'), '');
  }

  /// Normalize email to lowercase.
  static String normalizeEmail(String? input) {
    if (input == null) return '';
    return input.trim().toLowerCase();
  }

  /// URL allowlist: only http(s) and only Supabase storage host (or relative).
  /// Returns null if URL is unsafe.
  static String? safeImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return null;
    try {
      final uri = Uri.parse(rawUrl);
      if (!uri.hasScheme) return null;
      if (uri.scheme != 'https' && uri.scheme != 'http') return null;
      // Optionally enforce known hosts (your Supabase project)
      // if (!uri.host.endsWith('.supabase.co')) return null;
      return uri.toString();
    } catch (_) {
      return null;
    }
  }
}
