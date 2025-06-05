import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../common/utils/element_utils/element_utils.dart';
import '../config/image_config.dart';
import '../image_menu.dart';
import 'image.dart';
import 'image_selection_manager.dart';

/// A widget that displays an image with resize handles when selected
class ResizableImageWidget extends StatefulWidget {
  const ResizableImageWidget({
    super.key,
    required this.embedContext,
    required this.config,
    required this.imageSource,
    required this.imageSize,
    required this.margin,
    required this.alignment,
  });

  final EmbedContext embedContext;
  final QuillEditorImageEmbedConfig config;
  final String imageSource;
  final ElementSize imageSize;
  final double? margin;
  final Alignment alignment;

  @override
  State<ResizableImageWidget> createState() => _ResizableImageWidgetState();
}

class _ResizableImageWidgetState extends State<ResizableImageWidget> {
  late ElementSize _currentSize;
  Offset? _dragStartPosition;
  Offset? _lastDragPosition;
  ElementSize? _dragStartSize;
  _ResizeHandle? _activeHandle;
  late String _imageId;
  late ImageSelectionManager _selectionManager;

  // Configuration for resize handles
 // static const double _handleSize = 16.0; // Increased size for easier dragging
  static const double _handleSize = 32.0; // Increased size for easier dragging
  static const Color _handleColor = Colors.white;
  static const Color _handleBorderColor = Color(0xFF007ACC);
  static const double _handleOpacity = 1.0; // Full opacity for better visibility
  static const double _minSize = 50.0;

  bool get _isSelected => _selectionManager.isSelected(_imageId);

  @override
  void initState() {
    super.initState();
    _currentSize = widget.imageSize;

    _selectionManager = ImageSelectionManager();
    // Create unique ID for this image instance
    _imageId = '${widget.imageSource}_${widget.embedContext.node.documentOffset}';

    // Listen to selection changes
    _selectionManager.addListener(_onSelectionChanged);
    
    // Listen to controller selection changes to deselect when text is selected
    widget.embedContext.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _selectionManager.removeListener(_onSelectionChanged);
    widget.embedContext.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onSelectionChanged() {
    setState(() {
      // Widget will rebuild and check if it's selected
    });
  }

  void _onControllerChanged() {
    // If the text selection changes and this image is selected, deselect it
    if (_isSelected && widget.embedContext.controller.selection.isValid) {
      final selection = widget.embedContext.controller.selection;
      final imageOffset = widget.embedContext.node.documentOffset;
      
      // If the text selection doesn't include this image, deselect it
      if (selection.end < imageOffset || selection.start > imageOffset) {
        _selectionManager.deselectAll();
      }
    }
  }

  void _handleTap() {
    if (widget.embedContext.readOnly) {
      // In read-only mode, show the image menu directly
      _showImageMenu();
      return;
    }

    _selectionManager.selectImage(_imageId);    
  }

  void _handleDeselect() {
    _selectionManager.deselectAll();    
  }

  void _showImageMenu() {
    final imageWidget = getImageWidgetByImageSource(
      context: context,
      widget.imageSource,
      imageProviderBuilder: widget.config.imageProviderBuilder,
      imageErrorWidgetBuilder: widget.config.imageErrorWidgetBuilder,
      alignment: widget.alignment,
      height: _currentSize.height,
      width: _currentSize.width,
    );

    final onImageClicked = widget.config.onImageClicked;
    if (onImageClicked != null) {
      onImageClicked(widget.imageSource);
      return;
    }

    showDialog(
      context: context,
      builder: (_) => ImageOptionsMenu(
        controller: widget.embedContext.controller,
        config: widget.config,
        imageSource: widget.imageSource,
        imageSize: _currentSize,
        readOnly: widget.embedContext.readOnly,
        imageProvider: imageWidget.image,
      ),
    );
  }

  void _handlePanStart(DragStartDetails details, _ResizeHandle handle) {
    print('Pan start on handle: $handle at ${details.globalPosition}');
    _dragStartPosition = details.globalPosition;
    _lastDragPosition = details.globalPosition;
    _dragStartSize = _currentSize;
    _activeHandle = handle;
    
    // Prevent parent gestures from interfering
    details.kind; // Access to ensure gesture recognition
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_dragStartPosition == null || _dragStartSize == null || _activeHandle == null) {
      print('Pan update ignored: missing data');
      return;
    }

    final deltaY = details.globalPosition.dy - _lastDragPosition!.dy;
    final delta;
    // A bit of a hack - for some reason when you finish a drag and let go of
    // the mouse button the final globalPosition report is way, way off from
    // all the other ones vertically. This causes the image to be almost doubled
    // in height at the end of the resize operation.
    // The hack is to keep track of what the last drag position was and if the current
    // one is way off from it then use the last drag position instead. This should
    // keep the final global position update from messing up the height of the image.
    if (deltaY.abs() < 100) {
      delta = details.globalPosition - _dragStartPosition!;
      _lastDragPosition = details.globalPosition;
    } else {
      delta = _lastDragPosition! - _dragStartPosition!;
    }
    print('Pan update: delta=$delta, handle=${_activeHandle}');
    final newSize = _calculateNewSize(delta, _activeHandle!, _dragStartSize!);

    // Enforce minimum size constraints
    final constrainedSize = ElementSize(
      newSize.width?.clamp(_minSize, double.infinity),
      newSize.height?.clamp(_minSize, double.infinity),
    );

    if (constrainedSize.width != _currentSize.width ||
        constrainedSize.height != _currentSize.height) {
      print('Updating size to: ${constrainedSize.width} x ${constrainedSize.height}');
      setState(() {
        _currentSize = constrainedSize;
      });
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    print('Pan end');
    _dragStartPosition = null;
    _dragStartSize = null;
    _activeHandle = null;

    // Update the document with new size
    _updateImageSize();
  }

  void _updateImageSize() {
    if (_currentSize.width == null && _currentSize.height == null) return;

    // Find the embed node in the document
    final offset = widget.embedContext.node.documentOffset;

    // Build the style string with new dimensions for CSS compatibility
    final styleMap = <String, String>{};
    if (_currentSize.width != null) {
      styleMap['width'] = '${_currentSize.width!}px';
    }
    if (_currentSize.height != null) {
      styleMap['height'] = '${_currentSize.height!}px';
    }

    // Update using the style attribute (which is the standard way in Quill)
    if (styleMap.isNotEmpty) {
      final existingStyle = widget.embedContext.node.style.attributes['style']?.value?.toString() ?? '';
      
      // Parse existing styles and merge with new dimensions
      final existingStyleMap = <String, String>{};
      if (existingStyle.isNotEmpty) {
        final stylePairs = existingStyle.split(';');
        for (final pair in stylePairs) {
          final colonIndex = pair.indexOf(':');
          if (colonIndex > 0) {
            final key = pair.substring(0, colonIndex).trim();
            final value = pair.substring(colonIndex + 1).trim();
            existingStyleMap[key] = value;
          }
        }
      }
      
      // Merge new size values
      existingStyleMap.addAll(styleMap);
      
      final newStyleString = existingStyleMap.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join('; ');

      // Create new style attribute
      final styleAttr = Attribute('style', AttributeScope.embeds, newStyleString);
      widget.embedContext.controller.formatText(
        offset,
        1,
        styleAttr,
        shouldNotifyListeners: true,
      );
    }
  }

  ElementSize _calculateNewSize(Offset delta, _ResizeHandle handle, ElementSize startSize) {
    double deltaX = delta.dx;
    double deltaY = delta.dy;

    // Adjust delta based on which handle is being dragged
    switch (handle) {
      case _ResizeHandle.topLeft:
        deltaX = -deltaX;
        deltaY = -deltaY;
        break;
      case _ResizeHandle.topRight:
        deltaY = -deltaY;
        break;
      case _ResizeHandle.bottomLeft:
        deltaX = -deltaX;
        break;
      case _ResizeHandle.bottomRight:
        // No adjustment needed
        break;
    }

    // Calculate new dimensions
    final currentWidth = startSize.width ?? 300.0;
    final currentHeight = startSize.height ?? 200.0;
    
    double newWidth = currentWidth + deltaX;
    double newHeight = currentHeight + deltaY;

    return ElementSize(newWidth, newHeight);
  }

  Widget _buildResizeHandle(_ResizeHandle handle, Alignment alignment, MouseCursor cursor) {
    const handleSize = _handleSize;
    const hitAreaSize = handleSize + 16; // Larger hit area for easier dragging
    const offset = handleSize / 2;

    return Positioned(
      left: alignment.x > 0 ? null : -offset,
      right: alignment.x > 0 ? -offset : null,
      top: alignment.y > 0 ? null : -offset,
      bottom: alignment.y > 0 ? -offset : null,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque, // Ensure the handle receives all touch events
          onPanStart: (details) => _handlePanStart(details, handle),
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          // Prevent the parent gesture detector from interfering
          onTap: () {
            print('Handle tapped: $handle');
          }, // Handle tap to consume tap events
          child: Container(
            width: hitAreaSize,
            height: hitAreaSize,
            color: Colors.transparent, // Transparent larger hit area
            child: Center(
              child: Container(
                width: handleSize,
                height: handleSize,
                decoration: BoxDecoration(
                  color: _activeHandle == handle 
                      ? const Color(0xFF007ACC).withOpacity(0.8) // Highlight active handle
                      : _handleColor.withOpacity(_handleOpacity),
                  border: Border.all(
                    color: _activeHandle == handle 
                        ? const Color(0xFF005A9E) // Darker border when active
                        : _handleBorderColor,
                    width: _activeHandle == handle ? 3.0 : 2.0, // Thicker border when active
                  ),
                  borderRadius: BorderRadius.circular(handleSize / 2), // Circular handles
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: _activeHandle == handle ? 6 : 4, // Larger shadow when active
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                // Add a visual indicator that this is draggable
                child: Center(
                  child: Icon(
                    _getHandleIcon(handle),
                    size: 10,
                    color: const Color(0xFF007ACC),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getHandleIcon(_ResizeHandle handle) {
    switch (handle) {
      case _ResizeHandle.topLeft:
        return Icons.north_west;
      case _ResizeHandle.topRight:
        return Icons.north_east;
      case _ResizeHandle.bottomRight:
        return Icons.south_east;
      case _ResizeHandle.bottomLeft:
        return Icons.south_west;
    }
  }

  Widget _buildImage() {
    return getImageWidgetByImageSource(
      context: context,
      widget.imageSource,
      imageProviderBuilder: widget.config.imageProviderBuilder,
      imageErrorWidgetBuilder: widget.config.imageErrorWidgetBuilder,
      alignment: widget.alignment,
      height: _currentSize.height,
      width: _currentSize.width,
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = _buildImage();

    return Focus(
      onKeyEvent: (node, event) {
        if (_isSelected && 
            (event.logicalKey == LogicalKeyboardKey.delete ||
             event.logicalKey == LogicalKeyboardKey.backspace)) {
          // Delete the image
          final offset = widget.embedContext.node.documentOffset;
          widget.embedContext.controller.replaceText(
            offset,
            1,
            '',
            TextSelection.collapsed(offset: offset),
          );
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild, // Let child widgets handle gestures first
        onTap: _handleTap,
        onDoubleTap: _showImageMenu,
        child: Container(
          width: _currentSize.width,
          height: _currentSize.height,
          decoration: _isSelected && !widget.embedContext.readOnly
              ? BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF007ACC),
                    width: 2.0,
                    style: BorderStyle.solid,
                  ),
                )
              : null,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main image
              imageWidget,

              // Resize handles (only shown when selected and not read-only)
              if (_isSelected && !widget.embedContext.readOnly) ...[
                // Top-left handle
                _buildResizeHandle(
                  _ResizeHandle.topLeft,
                  Alignment.topLeft,
                  SystemMouseCursors.resizeUpLeft,
                ),
                // Top-right handle
                _buildResizeHandle(
                  _ResizeHandle.topRight,
                  Alignment.topRight,
                  SystemMouseCursors.resizeUpRight,
                ),
                // Bottom-right handle
                _buildResizeHandle(
                  _ResizeHandle.bottomRight,
                  Alignment.bottomRight,
                  SystemMouseCursors.resizeDownRight,
                ),
                // Bottom-left handle
                _buildResizeHandle(
                  _ResizeHandle.bottomLeft,
                  Alignment.bottomLeft,
                  SystemMouseCursors.resizeDownLeft,
                ),

                // Size display
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007ACC).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${_currentSize.width?.round() ?? 0} × ${_currentSize.height?.round() ?? 0}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Enum representing the different resize handles
enum _ResizeHandle {
  topLeft,
  topRight,
  bottomRight,
  bottomLeft,
}