/// Converts raw tafsir HTML from the API into clean plain text.
///
/// The API returns markup (`<p>`, `<h2>`, ...) and sometimes malformed
/// remnants (`h2>`, stray `<`/`>`). Displaying the raw string leaks tags
/// into the UI, so every entry is sanitized once at parse time.
class TafsirTextSanitizer {
  const TafsirTextSanitizer._();

  static final RegExp _blockClosers = RegExp(
    r'<\s*/\s*(p|h[1-6]|div|li|ul|ol|blockquote|tr|table|section)\b[^>]*>',
    caseSensitive: false,
  );
  static final RegExp _lineBreaks = RegExp(
    r'<\s*br\s*/?\s*>',
    caseSensitive: false,
  );
  static final RegExp _listItems = RegExp(
    r'<\s*li\b[^>]*>',
    caseSensitive: false,
  );
  static final RegExp _anyTag = RegExp(r'<[^>]*>');
  // Bare remnants without `<`, e.g. a malformed `h2>`. Single-letter tags are
  // excluded: a standalone " b> " could be real prose, unlike " h2> ".
  static final RegExp _bareTagRemnants = RegExp(
    r'(^|[\s(])(p|h[1-6]|div|span|br|li|ul|ol|blockquote|strong|em)>',
    caseSensitive: false,
  );
  // A closing fragment without `<`, e.g. `/h2>`, never occurs in prose.
  static final RegExp _slashedTagRemnants = RegExp(
    r'/(p|h[1-6]|div|span|br|li|ul|ol|blockquote|strong|em|b|i|u|a)>',
    caseSensitive: false,
  );
  static final RegExp _leftoverBrackets = RegExp(r'[<>]');
  static final RegExp _blankLines = RegExp(r'\n{3,}');
  static final RegExp _horizontalSpace = RegExp(r'[ \t\xA0]+');
  static final RegExp _decimalEntity = RegExp(r'&#(\d+);');
  static final RegExp _hexEntity = RegExp(r'&#x([0-9a-fA-F]+);');

  static const Map<String, String> _namedEntities = {
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&apos;': "'",
    '&#39;': "'",
    '&nbsp;': ' ',
    '&rsquo;': '\u2019',
    '&lsquo;': '\u2018',
    '&rdquo;': '\u201D',
    '&ldquo;': '\u201C',
    '&ndash;': '\u2013',
    '&mdash;': '\u2014',
  };

  static String clean(String raw) {
    var text = raw;
    // Structure first: block ends become paragraph breaks.
    text = text.replaceAll(_blockClosers, '\n\n');
    text = text.replaceAll(_lineBreaks, '\n');
    text = text.replaceAll(_listItems, '\n• ');
    // Then drop every well-formed tag.
    text = text.replaceAll(_anyTag, '');
    // Then drop malformed remnants such as a bare `h2>` or `/p>`.
    text = text.replaceAllMapped(
      _bareTagRemnants,
      (m) => '${m.group(1)}\n\n',
    );
    text = text.replaceAll(_slashedTagRemnants, '\n\n');
    // Decode entities after tag removal so `&lt;` etc. become text.
    text = _decodeEntities(text);
    // Any `<`/`>` left at this point is markup debris, not prose.
    text = text.replaceAll(_leftoverBrackets, '');
    // Normalize whitespace per line, keep paragraph breaks. A line ending
    // with `/` is a leftover fragment (e.g. a cut-off `</`), not prose.
    final lines = text.split('\n').map((line) {
      var cleaned = line.replaceAll(_horizontalSpace, ' ').trim();
      cleaned = cleaned.replaceAll(RegExp(r'/+$'), '').trim();
      return cleaned;
    });
    text = lines.join('\n').replaceAll(_blankLines, '\n\n').trim();
    return text;
  }

  static String _decodeEntities(String text) {
    var result = text;
    _namedEntities.forEach((entity, char) {
      result = result.replaceAll(entity, char);
    });
    result = result.replaceAllMapped(_decimalEntity, (m) {
      final code = int.tryParse(m.group(1)!);
      return code == null ? m.group(0)! : String.fromCharCode(code);
    });
    result = result.replaceAllMapped(_hexEntity, (m) {
      final code = int.tryParse(m.group(1)!, radix: 16);
      return code == null ? m.group(0)! : String.fromCharCode(code);
    });
    return result;
  }
}
