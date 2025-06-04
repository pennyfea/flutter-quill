import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../quill_delta.dart';
import '../document/document.dart';
import '../document/nodes/container.dart' as container_node;
import '../document/nodes/leaf.dart';
import '../editor/embed/embed_editor_builder.dart';
import '../editor/widgets/box.dart';
import 'config/viewer_config.dart';
import 'raw_viewer/config/raw_viewer_config.dart';
import 'raw_viewer/raw_viewer.dart';

class QuillViewer extends StatefulWidget {
  const QuillViewer({
    required this.scrollController,
    required this.text,
    this.config = const QuillViewerConfig(),
    super.key,
  });

  factory QuillViewer.basic({
    required String text,
    Key? key,
    QuillViewerConfig config = const QuillViewerConfig(),
    ScrollController? scrollController,
  }) {
    return QuillViewer(
      key: key,
      scrollController: scrollController ?? ScrollController(),
      config: config,
      text: text,
    );
  }

  final String text;
  final QuillViewerConfig config;
  final ScrollController scrollController;

  @override
  QuillViewerState createState() => QuillViewerState();
}

class QuillViewerState extends State<QuillViewer> {
  late GlobalKey<ViewerState> _viewerKey;

  @Deprecated('Use config instead')
  QuillViewerConfig get configurations => widget.config;
  QuillViewerConfig get config => widget.config;

  @override
  void initState() {
    super.initState();
    _viewerKey = config.viewerKey ?? GlobalKey<ViewerState>();
  }

  @override
  Widget build(BuildContext context) {
    Document doc;
    try {
      final delta = Delta.fromJson(jsonDecode(widget.text));
      doc = Document.fromDelta(delta);
    } catch (e) {
      // Fallback to plain text if not valid Delta
      doc = Document()..insert(0, widget.text);
    }

    final child = QuillRawViewer(
      key: _viewerKey,
      document: doc,
      config: QuillRawViewerConfig(
        customLeadingBuilder: widget.config.customLeadingBlockBuilder,
        scrollController: widget.scrollController,
        scrollable: config.scrollable,
        scrollBottomInset: config.scrollBottomInset,
        padding: config.padding,
        checkBoxReadOnly: config.checkBoxReadOnly,
        placeholder: config.placeholder,
        onLaunchUrl: config.onLaunchUrl,
        textCapitalization: config.textCapitalization,
        minHeight: config.minHeight,
        maxHeight: config.maxHeight,
        maxContentWidth: config.maxContentWidth,
        customStyles: config.customStyles,
        expands: config.expands,
        scrollPhysics: config.scrollPhysics,
        embedBuilder: _getEmbedBuilder,
        textSpanBuilder: config.textSpanBuilder,
        linkActionPickerDelegate: config.linkActionPickerDelegate,
        customLinkPrefixes: config.customLinkPrefixes,
        contentInsertionConfiguration: config.contentInsertionConfiguration,
      ),
    );

    return child;
  }

  EmbedBuilder _getEmbedBuilder(Embed node) {
    final builders = config.embedBuilders;

    if (builders != null) {
      for (final builder in builders) {
        if (builder.key == node.value.type) {
          return builder;
        }
      }
    }

    final unknownEmbedBuilder = config.unknownEmbedBuilder;
    if (unknownEmbedBuilder != null) {
      return unknownEmbedBuilder;
    }

    throw UnimplementedError(
      'Embeddable type "${node.value.type}" is not supported by supplied '
      'embed builders. You must pass your own builder function to '
      'embedBuilders property of QuillEditor or QuillField widgets or '
      'specify an unknownEmbedBuilder.',
    );
  }
}

/// Displays a document as a vertical list of document segments (lines
/// and blocks).
///
/// Children of [RenderViewer] must be instances of [RenderViewableBox].
class RenderViewer extends RenderViewableContainerBox
    with RelayoutWhenSystemFontsChangeMixin {
  RenderViewer({
    required this.document,
    required super.textDirection,
    required this.scrollable,
    required LayerLink startHandleLayerLink,
    required LayerLink endHandleLayerLink,
    required super.padding,
    required super.scrollBottomInset,
    ViewportOffset? offset,
    super.children,
    double? maxContentWidth,
  })  : _startHandleLayerLink = startHandleLayerLink,
        _endHandleLayerLink = endHandleLayerLink,
        _maxContentWidth = maxContentWidth,
        super(
          container: document.root,
        );

  final bool scrollable;

  Document document;
  LayerLink _startHandleLayerLink;
  LayerLink _endHandleLayerLink;

  final ValueNotifier<bool> _selectionStartInViewport =
      ValueNotifier<bool>(true);

  ValueListenable<bool> get selectionStartInViewport =>
      _selectionStartInViewport;

  ValueListenable<bool> get selectionEndInViewport => _selectionEndInViewport;
  final ValueNotifier<bool> _selectionEndInViewport = ValueNotifier<bool>(true);

  void setDocument(Document doc) {
    if (document == doc) {
      return;
    }
    document = doc;
    markNeedsLayout();
  }

  ViewportOffset? get offset => _offset;
  ViewportOffset? _offset;

  set offset(ViewportOffset? value) {
    if (_offset == value) return;
    if (attached) _offset?.removeListener(markNeedsPaint);
    _offset = value;
    if (attached) _offset?.addListener(markNeedsPaint);
    markNeedsLayout();
  }

  void setStartHandleLayerLink(LayerLink value) {
    if (_startHandleLayerLink == value) {
      return;
    }
    _startHandleLayerLink = value;
    markNeedsPaint();
  }

  void setEndHandleLayerLink(LayerLink value) {
    if (_endHandleLayerLink == value) {
      return;
    }
    _endHandleLayerLink = value;
    markNeedsPaint();
  }

  void setScrollBottomInset(double value) {
    if (scrollBottomInset == value) {
      return;
    }
    scrollBottomInset = value;
    markNeedsPaint();
  }

  double? _maxContentWidth;

  set maxContentWidth(double? value) {
    if (_maxContentWidth == value) return;
    _maxContentWidth = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    assert(() {
      if (!scrollable || !constraints.hasBoundedHeight) return true;
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('RenderEditableContainerBox must have '
            'unlimited space along its main axis when it is scrollable.'),
        ErrorDescription('RenderEditableContainerBox does not clip or'
            ' resize its children, so it must be '
            'placed in a parent that does not constrain the main '
            'axis.'),
        ErrorHint(
            'You probably want to put the RenderEditableContainerBox inside a '
            'RenderViewport with a matching main axis or disable the '
            'scrollable property.')
      ]);
    }());
    assert(() {
      if (constraints.hasBoundedWidth) return true;
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('RenderEditableContainerBox must have a bounded'
            ' constraint for its cross axis.'),
        ErrorDescription('RenderEditableContainerBox forces its children to '
            "expand to fit the RenderEditableContainerBox's container, "
            'so it must be placed in a parent that constrains the cross '
            'axis to a finite dimension.'),
      ]);
    }());

    resolvePadding();
    assert(resolvedPadding != null);

    var mainAxisExtent = resolvedPadding!.top;
    var child = firstChild;
    final innerConstraints = BoxConstraints.tightFor(
            width: math.min(
                _maxContentWidth ?? double.infinity, constraints.maxWidth))
        .deflate(resolvedPadding!);
    final leftOffset = _maxContentWidth == null
        ? 0.0
        : math.max((constraints.maxWidth - _maxContentWidth!) / 2, 0);
    while (child != null) {
      child.layout(innerConstraints, parentUsesSize: true);
      final childParentData = child.parentData as ViewableContainerParentData
        ..offset = Offset(resolvedPadding!.left + leftOffset, mainAxisExtent);
      mainAxisExtent += child.size.height;
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
    mainAxisExtent += resolvedPadding!.bottom;
    size = constraints.constrain(Size(constraints.maxWidth, mainAxisExtent));

    assert(size.isFinite);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void systemFontsDidChange() {
    super.systemFontsDidChange();
    markNeedsLayout();
  }
}

class ViewableContainerParentData
    extends ContainerBoxParentData<RenderEditableBox> {}

class RenderViewableContainerBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderEditableBox,
            ViewableContainerParentData>,
        RenderBoxContainerDefaultsMixin<RenderEditableBox,
            ViewableContainerParentData> {
  RenderViewableContainerBox({
    required container_node.QuillContainer container,
    required this.textDirection,
    required this.scrollBottomInset,
    required EdgeInsetsGeometry padding,
    List<RenderEditableBox>? children,
  })  : assert(padding.isNonNegative),
        _container = container,
        _padding = padding {
    addAll(children);
  }

  container_node.QuillContainer _container;
  TextDirection textDirection;
  EdgeInsetsGeometry _padding;
  double scrollBottomInset;
  EdgeInsets? _resolvedPadding;

  container_node.QuillContainer get container => _container;

  void setContainer(container_node.QuillContainer c) {
    if (_container == c) {
      return;
    }
    _container = c;
    markNeedsLayout();
  }

  EdgeInsetsGeometry getPadding() => _padding;

  void setPadding(EdgeInsetsGeometry value) {
    assert(value.isNonNegative);
    if (_padding == value) {
      return;
    }
    _padding = value;
    _markNeedsPaddingResolution();
  }

  EdgeInsets? get resolvedPadding => _resolvedPadding;

  void resolvePadding() {
    if (_resolvedPadding != null) {
      return;
    }
    _resolvedPadding = _padding.resolve(textDirection);
    _resolvedPadding = _resolvedPadding!.copyWith(left: _resolvedPadding!.left);

    assert(_resolvedPadding!.isNonNegative);
  }

  RenderEditableBox childAtPosition(TextPosition position) {
    assert(firstChild != null);
    final targetNode = container.queryChild(position.offset, false).node;

    var targetChild = firstChild;
    while (targetChild != null) {
      if (targetChild.container == targetNode) {
        break;
      }
      final newChild = childAfter(targetChild);
      if (newChild == null) {
        //  At start of document fails to find the position
        targetChild = childAtOffset(const Offset(0, 0));
        break;
      }
      targetChild = newChild;
    }
    if (targetChild == null) {
      throw 'targetChild should not be null';
    }
    return targetChild;
  }

  void _markNeedsPaddingResolution() {
    _resolvedPadding = null;
    markNeedsLayout();
  }

  /// Returns child of this container located at the specified local `offset`.
  ///
  /// If `offset` is above this container (offset.dy is negative) returns
  /// the first child. Likewise, if `offset` is below this container then
  /// returns the last child.
  RenderEditableBox childAtOffset(Offset offset) {
    assert(firstChild != null);
    resolvePadding();

    if (offset.dy <= _resolvedPadding!.top) {
      return firstChild!;
    }
    if (offset.dy >= size.height - _resolvedPadding!.bottom) {
      return lastChild!;
    }

    var child = firstChild;
    final dx = -offset.dx;
    var dy = _resolvedPadding!.top;
    while (child != null) {
      if (child.size.contains(offset.translate(dx, -dy))) {
        return child;
      }
      dy += child.size.height;
      child = childAfter(child);
    }

    // this case possible, when editor not scrollable,
    // but minHeight > content height and tap was under content
    return lastChild!;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is ViewableContainerParentData) {
      return;
    }

    child.parentData = ViewableContainerParentData();
  }

  @override
  void performLayout() {
    assert(constraints.hasBoundedWidth);
    resolvePadding();
    assert(_resolvedPadding != null);

    var mainAxisExtent = _resolvedPadding!.top;
    var child = firstChild;
    final innerConstraints =
        BoxConstraints.tightFor(width: constraints.maxWidth)
            .deflate(_resolvedPadding!);
    while (child != null) {
      child.layout(innerConstraints, parentUsesSize: true);
      final childParentData = (child.parentData as ViewableContainerParentData)
        ..offset = Offset(_resolvedPadding!.left, mainAxisExtent);
      mainAxisExtent += child.size.height;
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
    mainAxisExtent += _resolvedPadding!.bottom;
    size = constraints.constrain(Size(constraints.maxWidth, mainAxisExtent));

    assert(size.isFinite);
  }

  double _getIntrinsicCrossAxis(double Function(RenderBox child) childSize) {
    var extent = 0.0;
    var child = firstChild;
    while (child != null) {
      extent = math.max(extent, childSize(child));
      final childParentData = child.parentData as ViewableContainerParentData;
      child = childParentData.nextSibling;
    }
    return extent;
  }

  double _getIntrinsicMainAxis(double Function(RenderBox child) childSize) {
    var extent = 0.0;
    var child = firstChild;
    while (child != null) {
      extent += childSize(child);
      final childParentData = child.parentData as ViewableContainerParentData;
      child = childParentData.nextSibling;
    }
    return extent;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    resolvePadding();
    return _getIntrinsicCrossAxis((child) {
      final childHeight = math.max<double>(
          0, height - _resolvedPadding!.top + _resolvedPadding!.bottom);
      return child.getMinIntrinsicWidth(childHeight) +
          _resolvedPadding!.left +
          _resolvedPadding!.right;
    });
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    resolvePadding();
    return _getIntrinsicCrossAxis((child) {
      final childHeight = math.max<double>(
          0, height - _resolvedPadding!.top + _resolvedPadding!.bottom);
      return child.getMaxIntrinsicWidth(childHeight) +
          _resolvedPadding!.left +
          _resolvedPadding!.right;
    });
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    resolvePadding();
    return _getIntrinsicMainAxis((child) {
      final childWidth = math.max<double>(
          0, width - _resolvedPadding!.left + _resolvedPadding!.right);
      return child.getMinIntrinsicHeight(childWidth) +
          _resolvedPadding!.top +
          _resolvedPadding!.bottom;
    });
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    resolvePadding();
    return _getIntrinsicMainAxis((child) {
      final childWidth = math.max<double>(
          0, width - _resolvedPadding!.left + _resolvedPadding!.right);
      return child.getMaxIntrinsicHeight(childWidth) +
          _resolvedPadding!.top +
          _resolvedPadding!.bottom;
    });
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    resolvePadding();
    return defaultComputeDistanceToFirstActualBaseline(baseline)! +
        _resolvedPadding!.top;
  }
}
