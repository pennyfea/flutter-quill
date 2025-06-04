import 'package:flutter/widgets.dart';

import '../viewer.dart';
import 'config/raw_viewer_config.dart';
import 'raw_viewer_state.dart';
import '../../document/document.dart';

class QuillRawViewer extends StatefulWidget {
  QuillRawViewer({
    required this.config,
    required this.document,
    super.key,
  })  : assert(config.maxHeight == null || config.maxHeight! > 0,
            'maxHeight cannot be null'),
        assert(config.minHeight == null || config.minHeight! >= 0,
            'minHeight cannot be null'),
        assert(
            config.maxHeight == null ||
                config.minHeight == null ||
                config.maxHeight! >= config.minHeight!,
            'maxHeight cannot be null');

  final QuillRawViewerConfig config;
  final Document document;

  @override
  State<StatefulWidget> createState() => QuillRawViewerState();
}

/// Signature for a widget builder that builds a context menu for the given
/// [QuillRawViewerState].
///
/// See also:
///
///  * [EditableTextContextMenuBuilder], which performs the same role for
///    [EditableText]
typedef QuillEditorContextMenuBuilder = Widget Function(
  BuildContext context,
  QuillRawViewerState rawEditorState,
);

@immutable
class QuillEditorGlyphHeights {
  const QuillEditorGlyphHeights(
    this.startGlyphHeight,
    this.endGlyphHeight,
  );

  final double startGlyphHeight;
  final double endGlyphHeight;
}

/// Base interface for the editor state which defines contract used by
/// various mixins.
abstract class ViewerState extends State<QuillRawViewer> {
  ScrollController get scrollController;

  RenderViewer get renderEditor;

  /// Returns true if the editor has been marked as needing to be rebuilt.
  bool get dirty;
}
