class EditorContext {
  final List<String> openFiles;
  final String? activeFile;
  final String? selection;

  EditorContext({
    required this.openFiles,
    this.activeFile,
    this.selection,
  });

  Map<String, dynamic> toJson() => {
        'open_files': openFiles,
        if (activeFile != null) 'active_file': activeFile,
        if (selection != null) 'selection': selection,
      };
}
