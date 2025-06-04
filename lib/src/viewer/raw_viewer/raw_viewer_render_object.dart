import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ViewportOffset;

import '../../document/document.dart';
import '../viewer.dart';

class QuillRawViewerMultiChildRenderObject
    extends MultiChildRenderObjectWidget {
  const QuillRawViewerMultiChildRenderObject({
    required super.children,
    required this.document,
    required this.textDirection,
    required this.scrollable,
    required this.startHandleLayerLink,
    required this.endHandleLayerLink,
    required this.scrollBottomInset,
    super.key,
    this.padding = EdgeInsets.zero,
    this.maxContentWidth,
    this.offset,
  });

  final ViewportOffset? offset;
  final Document document;
  final TextDirection textDirection;
  final bool scrollable;
  final LayerLink startHandleLayerLink;
  final LayerLink endHandleLayerLink;
  final double scrollBottomInset;
  final EdgeInsetsGeometry padding;
  final double? maxContentWidth;

  @override
  RenderViewer createRenderObject(BuildContext context) {
    return RenderViewer(
      offset: offset,
      document: document,
      textDirection: textDirection,
      scrollable: scrollable,
      startHandleLayerLink: startHandleLayerLink,
      endHandleLayerLink: endHandleLayerLink,
      padding: padding,
      maxContentWidth: maxContentWidth,
      scrollBottomInset: scrollBottomInset,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderViewer renderObject,
  ) {
    renderObject
      ..offset = offset
      ..document = document
      ..setContainer(document.root)
      ..textDirection = textDirection
      ..setStartHandleLayerLink(startHandleLayerLink)
      ..setEndHandleLayerLink(endHandleLayerLink)
      ..setScrollBottomInset(scrollBottomInset)
      ..setPadding(padding)
      ..maxContentWidth = maxContentWidth;
  }
}
