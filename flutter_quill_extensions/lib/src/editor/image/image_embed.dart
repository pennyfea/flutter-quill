import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../common/utils/element_utils/element_utils.dart';
import 'config/image_config.dart';
import 'image_menu.dart';
import 'widgets/image.dart';
import 'widgets/resizable_image_widget.dart';

class QuillEditorImageEmbedBuilder extends EmbedBuilder {
  QuillEditorImageEmbedBuilder({
    required this.config,
  });
  final QuillEditorImageEmbedConfig config;

  @override
  String get key => BlockEmbed.imageType;

  @override
  bool get expanded => false;

  @override
  Widget build(
    BuildContext context,
    EmbedContext embedContext,
  ) {
    final imageSource = standardizeImageUrl(embedContext.node.value.data);
    final ((imageSize), margin, alignment) = getElementAttributes(
      embedContext.node,
      context,
    );
    
    // Use the new resizable image widget
    final resizableImageWidget = ResizableImageWidget(
      embedContext: embedContext,
      config: config,
      imageSource: imageSource,
      imageSize: imageSize,
      margin: margin,
       alignment: alignment,
    );

    return Builder(
      builder: (context) {
        if (margin != null) {
          return Padding(
            padding: EdgeInsets.all(margin),
            child: resizableImageWidget,
          );
        }
        return resizableImageWidget;
      },
    );
  }
}
