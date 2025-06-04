import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../common/structs/horizontal_spacing.dart';
import '../../common/structs/vertical_spacing.dart';
import '../../controller/quill_controller.dart';
import '../../delta/delta_diff.dart';
import '../../document/attribute.dart';
import '../../document/document.dart';
import '../../document/nodes/block.dart';
import '../../document/nodes/line.dart';
import '../../document/nodes/node.dart';
import '../../editor/widgets/default_styles.dart';
import '../../editor/widgets/link.dart';
import '../../editor/widgets/proxy.dart';
import '../viewer.dart';
import '../widgets/text/text_block.dart';
import '../widgets/text/text_line.dart';
import 'raw_viewer.dart';
import 'raw_viewer_render_object.dart';

class QuillRawViewerState extends ViewerState
    with
        AutomaticKeepAliveClientMixin<QuillRawViewer>,
        WidgetsBindingObserver,
        TickerProviderStateMixin<QuillRawViewer> {
  final GlobalKey _editorKey = GlobalKey();

  @override
  ScrollController get scrollController => _scrollController;
  late ScrollController _scrollController;

  // Theme
  DefaultStyles? _styles;

  final LayerLink _toolbarLayerLink = LayerLink();
  final LayerLink _startHandleLayerLink = LayerLink();
  final LayerLink _endHandleLayerLink = LayerLink();

  TextDirection get _textDirection => Directionality.of(context);

  @override
  bool get dirty => _dirty;
  bool _dirty = false;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    super.build(context);

    var doc = widget.document;
    if (doc.isEmpty() && widget.config.placeholder != null) {
      final raw = widget.config.placeholder?.replaceAll(r'"', '\\"');
      // get current block attributes applied to the first line even if it
      // is empty
      final blockAttributesWithoutContent =
          doc.root.children.firstOrNull?.toDelta().first.attributes;
      // check if it has code block attribute to add '//' to give to the users
      // the feeling of this is really a block of code
      final isCodeBlock =
          blockAttributesWithoutContent?.containsKey('code-block') ?? false;
      // we add the block attributes at the same time as the placeholder to allow the editor to display them without removing
      // the placeholder (this is really awkward when everything is empty)
      final blockAttrInsertion = blockAttributesWithoutContent == null
          ? ''
          : ',{"insert":"\\n","attributes":${jsonEncode(blockAttributesWithoutContent)}}';
      doc = Document.fromJson(
        jsonDecode(
          '[{"attributes":{"placeholder":true},"insert":"${isCodeBlock ? '// ' : ''}$raw${blockAttrInsertion.isEmpty ? '\\n' : ''}"}$blockAttrInsertion]',
        ),
      );
    }

    Widget child;
    if (widget.config.scrollable) {
      /// Since [SingleChildScrollView] does not implement
      /// `computeDistanceToActualBaseline` it prevents the editor from
      /// providing its baseline metrics. To address this issue we wrap
      /// the scroll view with [BaselineProxy] which mimics the editor's
      /// baseline.
      // This implies that the first line has no styles applied to it.
      final baselinePadding =
          EdgeInsets.only(top: _styles!.paragraph!.verticalSpacing.top);
      child = BaselineProxy(
        textStyle: _styles!.paragraph!.style,
        padding: baselinePadding,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: widget.config.scrollPhysics,
          child: CompositedTransformTarget(
            link: _toolbarLayerLink,
            child: QuillRawViewerMultiChildRenderObject(
              key: _editorKey,
              offset: _scrollController.hasClients
                  ? _scrollController.position
                  : null,
              document: doc,
              scrollable: widget.config.scrollable,
              textDirection: _textDirection,
              startHandleLayerLink: _startHandleLayerLink,
              endHandleLayerLink: _endHandleLayerLink,
              scrollBottomInset: widget.config.scrollBottomInset,
              padding: widget.config.padding,
              maxContentWidth: widget.config.maxContentWidth,
              children: _buildChildren(doc, context),
            ),
          ),
        ),
      );
    } else {
      child = CompositedTransformTarget(
        link: _toolbarLayerLink,
        child: Semantics(
          child: QuillRawViewerMultiChildRenderObject(
            key: _editorKey,
            document: doc,
            scrollable: widget.config.scrollable,
            textDirection: _textDirection,
            startHandleLayerLink: _startHandleLayerLink,
            endHandleLayerLink: _endHandleLayerLink,
            scrollBottomInset: widget.config.scrollBottomInset,
            padding: widget.config.padding,
            maxContentWidth: widget.config.maxContentWidth,
            children: _buildChildren(doc, context),
          ),
        ),
      );
    }
    final constraints = widget.config.expands
        ? const BoxConstraints.expand()
        : BoxConstraints(
            minHeight: widget.config.minHeight ?? 0.0,
            maxHeight: widget.config.maxHeight ?? double.infinity,
          );

    return QuillStyles(
      data: _styles!,
      child: Container(
        constraints: constraints,
        child: child,
      ),
    );
  }

  /// Updates the checkbox positioned at [offset] in document
  /// by changing its attribute according to [value].
  void _handleCheckboxTap(int offset, bool value) {
    // final requestKeyboardFocusOnCheckListChanged =
    //     widget.config.requestKeyboardFocusOnCheckListChanged;
    // if (!(widget.config.checkBoxReadOnly ?? widget.config.readOnly)) {
    //   _disableScrollControllerAnimateOnce = true;
    //   final currentSelection = controller.selection.copyWith();
    //   final attribute = value ? Attribute.checked : Attribute.unchecked;

    //   _markNeedsBuild();
    //   controller
    //     ..ignoreFocusOnTextChange = true
    //     ..skipRequestKeyboard = !requestKeyboardFocusOnCheckListChanged
    //     ..formatText(offset, 0, attribute)

    //     // Checkbox tapping causes controller.selection to go to offset 0
    //     // Stop toggling those two toolbar buttons
    //     ..toolbarButtonToggler = {
    //       Attribute.list.key: attribute,
    //       Attribute.header.key: Attribute.header
    //     };

    //   // Go back from offset 0 to current selection
    //   SchedulerBinding.instance.addPostFrameCallback((_) {
    //     controller
    //       ..ignoreFocusOnTextChange = false
    //       ..skipRequestKeyboard = !requestKeyboardFocusOnCheckListChanged
    //       ..updateSelection(currentSelection, ChangeSource.local);
    //   });
    // }
  }

  List<Widget> _buildChildren(Document doc, BuildContext context) {
    final result = <Widget>[];
    final indentLevelCounts = <int, int>{};
    // this need for several ordered list in document
    // we need to reset indents Map, if list finished
    // List finished when there is node without Attribute.ol in styles
    // So in this case we set clearIndents=true and send it
    // to the next EditableTextBlock
    var prevNodeOl = false;
    var clearIndents = false;

    for (final node in doc.root.children) {
      final attrs = node.style.attributes;

      if (prevNodeOl && attrs[Attribute.list.key] != Attribute.ol ||
          attrs.isEmpty) {
        clearIndents = true;
      }

      prevNodeOl = attrs[Attribute.list.key] == Attribute.ol;
      final nodeTextDirection = getDirectionOfNode(node, _textDirection);
      if (node is Line) {
        final editableTextLine =
            _getEditableTextLineFromNode(node, context, attrs);
        result.add(Directionality(
            textDirection: nodeTextDirection, child: editableTextLine));
      } else if (node is Block) {
        final editableTextBlock = EditableTextBlock(
          block: node,
          controller: QuillController.basic(),
          customLeadingBlockBuilder: widget.config.customLeadingBuilder,
          textDirection: nodeTextDirection,
          scrollBottomInset: widget.config.scrollBottomInset,
          horizontalSpacing: _getHorizontalSpacingForBlock(node, _styles),
          verticalSpacing: _getVerticalSpacingForBlock(node, _styles),
          color: Colors.transparent,
          styles: _styles,
          contentPadding: attrs.containsKey(Attribute.codeBlock.key)
              ? const EdgeInsets.all(16)
              : null,
          embedBuilder: widget.config.embedBuilder,
          textSpanBuilder: widget.config.textSpanBuilder,
          linkActionPicker: _linkActionPicker,
          onLaunchUrl: widget.config.onLaunchUrl,
          indentLevelCounts: indentLevelCounts,
          clearIndents: clearIndents,
          onCheckboxTap: _handleCheckboxTap,
          checkBoxReadOnly: false,
          customLinkPrefixes: widget.config.customLinkPrefixes,
        );
        result.add(
          Directionality(
            textDirection: nodeTextDirection,
            child: editableTextBlock,
          ),
        );

        clearIndents = false;
      } else {
        _dirty = false;
        throw StateError('Unreachable.');
      }
    }
    _dirty = false;
    return result;
  }

  EditableTextLine _getEditableTextLineFromNode(
      Line node, BuildContext context, Map<String, Attribute<dynamic>> attrs) {
    final textLine = TextLine(
      line: node,
      textDirection: _textDirection,
      embedBuilder: widget.config.embedBuilder,
      textSpanBuilder: widget.config.textSpanBuilder,
      styles: _styles!,
      controller: QuillController.basic(),
      linkActionPicker: _linkActionPicker,
      onLaunchUrl: widget.config.onLaunchUrl,
      customLinkPrefixes: widget.config.customLinkPrefixes,
    );
    final editableTextLine = EditableTextLine(
        node,
        null,
        textLine,
        _getHorizontalSpacingForLine(node, _styles),
        _getVerticalSpacingForLine(node, _styles),
        _textDirection,
        Colors.transparent,
        MediaQuery.devicePixelRatioOf(context),
        _styles!.inlineCode!,
        _getDecoration(node, _styles, attrs));
    return editableTextLine;
  }

  HorizontalSpacing _getHorizontalSpacingForLine(
    Line line,
    DefaultStyles? defaultStyles,
  ) {
    final attrs = line.style.attributes;
    if (attrs.containsKey(Attribute.header.key)) {
      int level;
      if (attrs[Attribute.header.key]!.value is double) {
        level = attrs[Attribute.header.key]!.value.toInt();
      } else {
        level = attrs[Attribute.header.key]!.value;
      }
      switch (level) {
        case 1:
          return defaultStyles!.h1!.horizontalSpacing;
        case 2:
          return defaultStyles!.h2!.horizontalSpacing;
        case 3:
          return defaultStyles!.h3!.horizontalSpacing;
        case 4:
          return defaultStyles!.h4!.horizontalSpacing;
        case 5:
          return defaultStyles!.h5!.horizontalSpacing;
        case 6:
          return defaultStyles!.h6!.horizontalSpacing;
        default:
          throw ArgumentError('Invalid level $level');
      }
    }

    return defaultStyles!.paragraph!.horizontalSpacing;
  }

  VerticalSpacing _getVerticalSpacingForLine(
    Line line,
    DefaultStyles? defaultStyles,
  ) {
    final attrs = line.style.attributes;
    if (attrs.containsKey(Attribute.header.key)) {
      int level;
      if (attrs[Attribute.header.key]!.value is double) {
        level = attrs[Attribute.header.key]!.value.toInt();
      } else {
        level = attrs[Attribute.header.key]!.value;
      }
      switch (level) {
        case 1:
          return defaultStyles!.h1!.verticalSpacing;
        case 2:
          return defaultStyles!.h2!.verticalSpacing;
        case 3:
          return defaultStyles!.h3!.verticalSpacing;
        case 4:
          return defaultStyles!.h4!.verticalSpacing;
        case 5:
          return defaultStyles!.h5!.verticalSpacing;
        case 6:
          return defaultStyles!.h6!.verticalSpacing;
        default:
          throw ArgumentError('Invalid level $level');
      }
    }

    return defaultStyles!.paragraph!.verticalSpacing;
  }

  HorizontalSpacing _getHorizontalSpacingForBlock(
      Block node, DefaultStyles? defaultStyles) {
    final attrs = node.style.attributes;
    if (attrs.containsKey(Attribute.blockQuote.key)) {
      return defaultStyles!.quote!.horizontalSpacing;
    } else if (attrs.containsKey(Attribute.codeBlock.key)) {
      return defaultStyles!.code!.horizontalSpacing;
    } else if (attrs.containsKey(Attribute.indent.key)) {
      return defaultStyles!.indent!.horizontalSpacing;
    } else if (attrs.containsKey(Attribute.list.key)) {
      return defaultStyles!.lists!.horizontalSpacing;
    } else if (attrs.containsKey(Attribute.align.key)) {
      return defaultStyles!.align!.horizontalSpacing;
    }
    return HorizontalSpacing.zero;
  }

  VerticalSpacing _getVerticalSpacingForBlock(
      Block node, DefaultStyles? defaultStyles) {
    final attrs = node.style.attributes;
    if (attrs.containsKey(Attribute.blockQuote.key)) {
      return defaultStyles!.quote!.verticalSpacing;
    } else if (attrs.containsKey(Attribute.codeBlock.key)) {
      return defaultStyles!.code!.verticalSpacing;
    } else if (attrs.containsKey(Attribute.indent.key)) {
      return defaultStyles!.indent!.verticalSpacing;
    } else if (attrs.containsKey(Attribute.list.key)) {
      return defaultStyles!.lists!.verticalSpacing;
    } else if (attrs.containsKey(Attribute.align.key)) {
      return defaultStyles!.align!.verticalSpacing;
    }
    return VerticalSpacing.zero;
  }

  BoxDecoration? _getDecoration(Node node, DefaultStyles? defaultStyles,
      Map<String, Attribute<dynamic>> attrs) {
    if (attrs.containsKey(Attribute.header.key)) {
      final level = attrs[Attribute.header.key]!.value;
      switch (level) {
        case 1:
          return defaultStyles!.h1!.decoration;
        case 2:
          return defaultStyles!.h2!.decoration;
        case 3:
          return defaultStyles!.h3!.decoration;
        case 4:
          return defaultStyles!.h4!.decoration;
        case 5:
          return defaultStyles!.h5!.decoration;
        case 6:
          return defaultStyles!.h6!.decoration;
        default:
          throw ArgumentError('Invalid level $level');
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = widget.config.scrollController;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parentStyles = QuillStyles.getStyles(context, true);
    final defaultStyles = DefaultStyles.getInstance(context);
    _styles = (parentStyles != null)
        ? defaultStyles.merge(parentStyles)
        : defaultStyles;

    if (widget.config.customStyles != null) {
      _styles = _styles!.merge(widget.config.customStyles!);
    }
  }

  @override
  void didUpdateWidget(QuillRawViewer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.config.scrollController != _scrollController) {
      _scrollController = widget.config.scrollController;
    }

    // in case customStyles changed in new widget
    if (widget.config.customStyles != null) {
      _styles = _styles!.merge(widget.config.customStyles!);
    }
  }

  Future<LinkMenuAction> _linkActionPicker(Node linkNode) async {
    final link = linkNode.style.attributes[Attribute.link.key]!.value!;
    return widget.config.linkActionPickerDelegate(context, link, linkNode);
  }

  /// The renderer for this widget's editor descendant.
  ///
  /// This property is typically used to notify the renderer of input gestures.
  @override
  RenderViewer get renderEditor =>
      _editorKey.currentContext!.findRenderObject() as RenderViewer;

  @override
  bool get wantKeepAlive => false;
}
