import '../models/editor_context.dart';

class EditorUtils {
  static EditorContext buildEditorContext({
    List<String>? openFiles,
    String? activeFile,
    String? selection,
  }) {
    return EditorContext(
      openFiles: openFiles ?? const [],
      activeFile: activeFile,
      selection: selection,
    );
  }
}


