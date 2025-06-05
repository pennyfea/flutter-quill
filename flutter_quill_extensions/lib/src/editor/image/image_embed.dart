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
    
    // Use the new resizable image widget with drag and drop capability
    final resizableImageWidget = ResizableImageWidget(
      embedContext: embedContext,
      config: config,
      imageSource: imageSource,
      imageSize: imageSize,
      margin: margin,
       alignment: alignment,
    );

    // Wrap with drag and drop functionality
    final draggableImageWidget = _DraggableImageWrapper(
      embedContext: embedContext,
      imageSource: imageSource,
      child: resizableImageWidget,
    );

    return Builder(
      builder: (context) {
        if (margin != null) {
          return Padding(
            padding: EdgeInsets.all(margin),
            child: draggableImageWidget,
          );
        }
        return draggableImageWidget;
      },
    );
  }
}

/// Wrapper widget that adds drag and drop functionality to images
class _DraggableImageWrapper extends StatefulWidget {
  const _DraggableImageWrapper({
    required this.embedContext,
    required this.imageSource,
    required this.child,
  });

  final EmbedContext embedContext;
  final String imageSource;
  final Widget child;

  @override
  State<_DraggableImageWrapper> createState() => _DraggableImageWrapperState();
}

class _DraggableImageWrapperState extends State<_DraggableImageWrapper> {
  bool _isDragging = false;
  
  void _handleImageDragStart(String imageSource) {
    setState(() {
      _isDragging = true;
    });
  }
  
  void _handleImageDragEnd() {
    setState(() {
      _isDragging = false;
    });
  }
  
  void _moveImageToPosition(int newOffset) {
    final controller = widget.embedContext.controller;
    final currentOffset = widget.embedContext.node.documentOffset;
    
    // Don't move if it's the same position
    if (newOffset == currentOffset) {
      return;
    }
    
    // Get the current image embed with all its attributes
    final currentNode = widget.embedContext.node;
    final imageEmbed = BlockEmbed.image(widget.imageSource);
    
    // Copy style attributes from the current node
    final attributes = currentNode.style.attributes;
    
    // Remove from current position
    controller.replaceText(
      currentOffset,
      1,
      '',
      TextSelection.collapsed(offset: currentOffset),
    );
    
    // Adjust target offset if we removed text before it
    final adjustedOffset = newOffset > currentOffset ? newOffset - 1 : newOffset;
    
    // Insert at new position with preserved attributes
    controller.document.insert(adjustedOffset, imageEmbed);
    
    // Apply the original attributes to the new position
    if (attributes.isNotEmpty) {
      for (final attr in attributes.values) {
        controller.formatText(
          adjustedOffset,
          1,
          attr,
          shouldNotifyListeners: false,
        );
      }
    }
    
    // Update selection to the new image position
    controller.updateSelection(
      TextSelection.collapsed(offset: adjustedOffset + 1),
      ChangeSource.local,
    );
    
    // Notify listeners after all operations
    controller.notifyListeners();
  }
  
  void _moveImageFromOffset(int sourceOffset, int targetOffset) {
    final controller = widget.embedContext.controller;
    
    // Don't move if it's the same position
    if (sourceOffset == targetOffset) {
      return;
    }
    
    // Get the delta at the source position to extract the image data
    final delta = controller.document.toDelta();
    final ops = delta.toList();
    
    var currentOffset = 0;
    Map<String, dynamic>? imageData;
    Map<String, dynamic>? imageAttributes;
    
    // Find the image operation at the source offset
    for (final op in ops) {
      if (op.isInsert) {
        if (currentOffset == sourceOffset && op.data is Map<String, dynamic>) {
          final data = op.data as Map<String, dynamic>;
          if (data.containsKey('image')) {
            imageData = Map<String, dynamic>.from(data);
            imageAttributes = op.attributes;
            break;
          }
        }
        currentOffset += op.length!;
      }
    }
    
    if (imageData != null) {
      // Remove from source position
      controller.replaceText(
        sourceOffset,
        1,
        '',
        TextSelection.collapsed(offset: sourceOffset),
      );
      
      // Adjust target offset if we removed text before it
      final adjustedOffset = targetOffset > sourceOffset ? targetOffset - 1 : targetOffset;
      
      // Create the image embed
      final imageEmbed = BlockEmbed.image(imageData['image']);
      
      // Insert at new position
      controller.document.insert(adjustedOffset, imageEmbed);
      
      // Apply attributes if they exist
      if (imageAttributes != null && imageAttributes.isNotEmpty) {
        for (final entry in imageAttributes.entries) {
          final attr = Attribute(entry.key, AttributeScope.embeds, entry.value);
          controller.formatText(
            adjustedOffset,
            1,
            attr,
            shouldNotifyListeners: false,
          );
        }
      }
      
      // Update selection to the new image position
      controller.updateSelection(
        TextSelection.collapsed(offset: adjustedOffset + 1),
        ChangeSource.local,
      );
      
      // Notify listeners after all operations
      controller.notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<Map<String, dynamic>>(
      data: {
        'imageSource': widget.imageSource,
        'currentOffset': widget.embedContext.node.documentOffset,
      },
      feedback: Opacity(
        opacity: 0.7,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF007ACC), width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: widget.child,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: widget.child,
      ),
      onDragStarted: () => _handleImageDragStart(widget.imageSource),
      onDragEnd: (details) {
        _handleImageDragEnd();
        // When drag ends, move the image to the current cursor position
        final controller = widget.embedContext.controller;
        final cursorPosition = controller.selection.baseOffset;
        final currentOffset = widget.embedContext.node.documentOffset;
        
        // Move the image to where the cursor is positioned
        if (cursorPosition != currentOffset && cursorPosition >= 0) {
          _moveImageFromOffset(currentOffset, cursorPosition);
        }
      },
      child: widget.child,
    );
  }
}
