String unifiedDiff(String oldText, String newText, {required String filePath, bool color = false}) {
  final oldLines = oldText.split('\n');
  final newLines = newText.split('\n');
  final buf = StringBuffer();
  String green(String s) => color ? '\x1B[32m' + s + '\x1B[0m' : s;
  String red(String s) => color ? '\x1B[31m' + s + '\x1B[0m' : s;
  buf.writeln('--- a/' + filePath);
  buf.writeln('+++ b/' + filePath);
  int i = 0, j = 0;
  while (i < oldLines.length || j < newLines.length) {
    final a = (i < oldLines.length) ? oldLines[i] : null;
    final b = (j < newLines.length) ? newLines[j] : null;
    if (a == b) {
      buf.writeln(' ' + (a ?? ''));
      i++; j++;
    } else if (b != null && (a == null || !newLines.sublist(j + 1).contains(a))) {
      buf.writeln(green('+' + b));
      j++;
    } else if (a != null) {
      buf.writeln(red('-' + a));
      i++;
    }
  }
  return buf.toString();
}


