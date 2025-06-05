import 'package:flutter/foundation.dart';

/// Global manager for tracking selected images
class ImageSelectionManager extends ChangeNotifier {
  static final ImageSelectionManager _instance = ImageSelectionManager._internal();
  factory ImageSelectionManager() => _instance;
  ImageSelectionManager._internal();

  String? _selectedImageId;

  String? get selectedImageId => _selectedImageId;

  void selectImage(String imageId) {
    if (_selectedImageId != imageId) {
      _selectedImageId = imageId;
      notifyListeners();
    }
  }

  void deselectAll() {
    if (_selectedImageId != null) {
      _selectedImageId = null;
      notifyListeners();
    }
  }

  bool isSelected(String imageId) {
    return _selectedImageId == imageId;
  }
}