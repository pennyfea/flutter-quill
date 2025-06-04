/// @docImport '../../rules/insert.dart' show AutoFormatMultipleLinksRule;
library;

import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart' show experimental;

import '../../document/nodes/node.dart';
import '../../editor/embed/embed_editor_builder.dart';
import '../../editor/raw_editor/builders/leading_block_builder.dart';
import '../../editor/widgets/default_styles.dart';
import '../../editor/widgets/link.dart' hide linkPrefixes;
import '../raw_viewer/config/raw_viewer_config.dart';
import '../raw_viewer/raw_viewer.dart';
import '../widgets/text/utils/text_block_utils.dart';

// IMPORTANT For project authors: The QuillEditorConfig.copyWith()
// should be manually updated each time we add or remove a property

/// The configuration of the editor widget.
@immutable
class QuillViewerConfig {
  const QuillViewerConfig({
    this.scrollable = true,
    this.padding = EdgeInsets.zero,
    this.autoFocus = false,
    this.expands = false,
    this.placeholder,
    this.checkBoxReadOnly,
    this.disableClipboard = false,
    this.textSelectionThemeData,
    this.showCursor,
    this.paintCursorAboveText,
    this.enableInteractiveSelection = true,
    this.enableSelectionToolbar = true,
    this.scrollBottomInset = 0,
    this.minHeight,
    this.maxHeight,
    this.maxContentWidth,
    this.customStyles,
    this.textCapitalization = TextCapitalization.sentences,
    this.keyboardAppearance,
    this.scrollPhysics,
    this.onLaunchUrl,
    this.onTapDown,
    this.onTapUp,
    this.onSingleLongTapStart,
    this.onSingleLongTapMoveUpdate,
    this.onSingleLongTapEnd,
    @experimental this.onKeyPressed,
    this.enableAlwaysIndentOnTab = false,
    this.embedBuilders,
    this.textSpanBuilder = defaultSpanBuilder,
    this.unknownEmbedBuilder,
    this.linkActionPickerDelegate = defaultLinkActionPickerDelegate,
    this.floatingCursorDisabled = false,
    this.textSelectionControls,
    this.customShortcuts,
    this.customActions,
    this.detectWordBoundary = true,
    this.onTapOutsideEnabled = true,
    this.onTapOutside,
    this.customLinkPrefixes = const <String>[],
    this.contentInsertionConfiguration,
    this.contextMenuBuilder,
    this.viewerKey,
    this.requestKeyboardFocusOnCheckListChanged = false,
    this.textInputAction = TextInputAction.newline,
    this.enableScribble = false,
    this.onScribbleActivated,
    this.scribbleAreaInsets,
    this.readOnlyMouseCursor = SystemMouseCursors.text,
    this.onPerformAction,
    @experimental this.customLeadingBlockBuilder,
  });

  @experimental
  final LeadingBlockNodeBuilder? customLeadingBlockBuilder;

  /// The text placeholder in the quill editor
  final String? placeholder;

  /// A handler for keys that are pressed when the editor is focused.
  ///
  /// This feature is supported on **desktop devices** and **mobile devices with a
  /// hardware keyboard connected.** It is not supported by virtual on-screen
  /// keyboards of touch devices.
  @experimental
  final KeyEventResult? Function(KeyEvent event, Node? node)? onKeyPressed;

  /// Override [readOnly] for checkbox.
  ///
  /// When this is set to `false`, the checkbox can be checked
  /// or unchecked while [readOnly] is set to `true`.
  /// When this is set to `null`, the [readOnly] value is used.
  ///
  /// Defaults to `null`.
  final bool? checkBoxReadOnly;

  /// Disable Clipboard features
  ///
  /// when this is set to `true` clipboard can not be used
  /// this disables the clipboard notification for requesting permissions
  ///
  /// Defaults to `false`.
  final bool disableClipboard;

  /// Whether this editor should create a scrollable container for its content.
  ///
  /// When set to `true` the editor's height can be controlled by [minHeight],
  /// [maxHeight] and [expands] properties.
  ///
  /// When set to `false` the editor always expands to fit the entire content
  /// of the document and should normally be placed as a child of another
  /// scrollable widget, otherwise the content may be clipped.
  /// by default it will by true
  final bool scrollable;
  final double scrollBottomInset;

  /// Enables always indenting when the TAB key is pressed.
  ///
  /// When set to true, pressing the TAB key will always insert an indentation
  /// regardless of the context. If set to false, the TAB key will only indent
  /// when the cursor is at the beginning of a list item. In other cases, it will
  /// insert a tab character.
  ///
  /// Defaults to false. Must not be null.
  final bool enableAlwaysIndentOnTab;

  /// Additional space around the content of this editor.
  /// by default will be [EdgeInsets.zero]
  final EdgeInsetsGeometry padding;

  /// Whether this editor should focus itself if nothing else is already
  /// focused.
  ///
  /// If true, the keyboard will open as soon as this editor obtains focus.
  /// Otherwise, the keyboard is only shown after the user taps the editor.
  ///
  /// Defaults to `false`. Cannot be `null`.
  final bool autoFocus;

  /// Whether the [onTapOutside] should be triggered or not.
  ///
  /// Defaults to `true`.
  ///
  /// See also: [onTapOutside] and [QuillRawViewerConfig.onTapOutsideEnabled].
  final bool onTapOutsideEnabled;

  /// By default on non-mobile platforms, the editor will unfocus.
  ///
  /// On mobile platforms, it will only unfocus if the input kind in [PointerDownEvent.kind]
  /// is [ui.PointerDeviceKind.unknown].
  ///
  /// By passing a non-null value, you will override the default behavior.
  ///
  /// See also: [onTapOutsideEnabled] and [QuillRawViewerConfig.onTapOutside].
  final Function(PointerDownEvent event, FocusNode focusNode)? onTapOutside;

  /// Whether to show cursor.
  ///
  /// The cursor refers to the blinking caret when the editor is focused.
  final bool? showCursor;
  final bool? paintCursorAboveText;

  /// The [readOnlyMouseCursor] is used for Windows, macOS when [readOnly] is [true]
  final MouseCursor readOnlyMouseCursor;

  /// Whether to enable user interface affordances for changing the
  /// text selection.
  ///
  /// For example, setting this to true will enable features such as
  /// long-pressing the editor to select text and show the
  /// cut/copy/paste menu, and tapping to move the text cursor.
  ///
  /// When this is false, the text selection cannot be adjusted by
  /// the user, text cannot be copied, and the user cannot paste into
  /// the text field from the clipboard.
  ///
  /// To disable just the selection toolbar, set enableSelectionToolbar
  /// to false.
  final bool enableInteractiveSelection;

  /// Whether to show the cut/copy/paste menu when selecting text.
  final bool enableSelectionToolbar;

  /// The minimum height to be occupied by this editor.
  ///
  /// This only has effect if [scrollable] is set to `true` and [expands] is
  /// set to `false`.
  final double? minHeight;

  /// The maximum height to be occupied by this editor.
  ///
  /// This only has effect if [scrollable] is set to `true` and [expands] is
  /// set to `false`.
  final double? maxHeight;

  /// The maximum width to be occupied by the content of this editor.
  ///
  /// If this is not null and and this editor's width is larger than this value
  /// then the contents will be constrained to the provided maximum width and
  /// horizontally centered. This is mostly useful on devices with wide screens.
  final double? maxContentWidth;

  /// Allows to override [DefaultStyles].
  final DefaultStyles? customStyles;

  /// Whether this editor's height will be sized to fill its parent.
  ///
  /// This only has effect if [scrollable] is set to `true`.
  ///
  /// If expands is set to true and wrapped in a parent widget like [Expanded]
  /// or [SizedBox], the editor will expand to fill the parent.
  ///
  /// [maxHeight] and [minHeight] must both be `null` when this is set to
  /// `true`.
  ///
  /// Defaults to `false`.
  final bool expands;

  /// Configures how the platform keyboard will select an uppercase or
  /// lowercase keyboard.
  ///
  /// Only supports text keyboards, other keyboard types will ignore this
  /// configuration. Capitalization is locale-aware.
  ///
  /// Defaults to [TextCapitalization.sentences]. Must not be `null`.
  final TextCapitalization textCapitalization;

  /// The appearance of the keyboard.
  ///
  /// This setting is only honored on iOS devices.
  ///
  /// Defaults to Material/Cupertino App Brightness.
  ///
  /// The keyboard appearance will set using the following:
  ///
  /// ```dart
  /// widget.config.keyboardAppearance ??
  /// CupertinoTheme.maybeBrightnessOf(context) ??
  /// Theme.of(context).brightness
  /// ```
  ///
  /// See also: https://github.com/flutter/flutter/blob/06b9f7ba0bef2b5b44a643c73f4295a096de1202/packages/flutter/lib/src/services/text_input.dart#L621-L626
  /// and [QuillRawViewerConfig.keyboardAppearance]
  final Brightness? keyboardAppearance;

  /// The [ScrollPhysics] to use when vertically scrolling the input.
  ///
  /// This only has effect if [scrollable] is set to `true`.
  ///
  /// If not specified, it will behave according to the current platform.
  ///
  /// See [Scrollable.physics].
  final ScrollPhysics? scrollPhysics;

  /// Callback to invoke when user wants to launch a URL.
  final ValueChanged<String>? onLaunchUrl;

  // Returns whether gesture is handled
  final bool Function(
      TapDownDetails details, TextPosition Function(Offset offset))? onTapDown;

  // Returns whether gesture is handled
  final bool Function(
      TapUpDetails details, TextPosition Function(Offset offset))? onTapUp;

  // Returns whether gesture is handled
  final bool Function(
          LongPressStartDetails details, TextPosition Function(Offset offset))?
      onSingleLongTapStart;

  // Returns whether gesture is handled
  final bool Function(LongPressMoveUpdateDetails details,
      TextPosition Function(Offset offset))? onSingleLongTapMoveUpdate;

  // Returns whether gesture is handled
  final bool Function(
          LongPressEndDetails details, TextPosition Function(Offset offset))?
      onSingleLongTapEnd;

  final Iterable<EmbedBuilder>? embedBuilders;
  final EmbedBuilder? unknownEmbedBuilder;

  final TextSpanBuilder textSpanBuilder;

  /// Delegate function responsible for showing menu with link actions on
  /// mobile platforms (iOS, Android).
  ///
  /// The menu is triggered in editing mode ([readOnly] is set to `false`)
  /// when the user long-presses a link-styled text segment.
  ///
  /// FlutterQuill provides default implementation which can be overridden by
  /// this field to customize the user experience.
  ///
  /// By default on iOS the menu is displayed with [showCupertinoModalPopup]
  /// which constructs an instance of [CupertinoActionSheet]. For Android,
  /// the menu is displayed with [showModalBottomSheet] and a list of
  /// Material [ListTile]s.
  final LinkActionPickerDelegate linkActionPickerDelegate;

  final bool floatingCursorDisabled;

  /// allows to create a custom textSelectionControls,
  /// if this is null a default textSelectionControls based on the app's theme
  /// will be used
  final TextSelectionControls? textSelectionControls;

  /// Contains user-defined shortcuts map.
  ///
  /// [https://docs.flutter.dev/development/ui/advanced/actions-and-shortcuts#shortcuts]
  final Map<ShortcutActivator, Intent>? customShortcuts;

  /// Contains user-defined actions.
  ///
  /// [https://docs.flutter.dev/development/ui/advanced/actions-and-shortcuts#actions]
  final Map<Type, Action<Intent>>? customActions;

  final bool detectWordBoundary;

  /// Link prefixes that are addations to [linkPrefixes], which are used
  /// on link launch [LinkMenuAction.launch] to check whether a link is valid.
  ///
  /// If a link is not valid and link launch is requested,
  /// the editor will append `https://` as prefix to the link.
  ///
  /// This is used to tapping links within the editor, and not the toolbar or
  /// [AutoFormatMultipleLinksRule].
  final List<String> customLinkPrefixes;

  // Allows for creating a custom context menu
  final QuillEditorContextMenuBuilder? contextMenuBuilder;

  /// Configuration of handler for media content inserted via the system input
  /// method.
  ///
  /// See [https://api.flutter.dev/flutter/widgets/EditableText/contentInsertionConfiguration.html]
  final ContentInsertionConfiguration? contentInsertionConfiguration;

  /// Using the editorKey for get getLocalRectForCaret
  /// editorKey.currentState?.renderEditor.getLocalRectForCaret
  final GlobalKey<ViewerState>? viewerKey;

  /// By default we will use
  /// ```
  /// TextSelectionTheme.of(context)
  /// ```
  /// to change it please pass a different value
  final TextSelectionThemeData? textSelectionThemeData;

  /// When there is a change the check list values
  /// should we request keyboard focus??
  final bool requestKeyboardFocusOnCheckListChanged;

  /// Default to [TextInputAction.newline]
  final TextInputAction textInputAction;

  /// Enable Scribble? Currently Apple Pencil only, defaults to false.
  final bool enableScribble;

  /// Called when Scribble is activated.
  final void Function()? onScribbleActivated;

  /// Optional insets for the scribble area.
  final EdgeInsets? scribbleAreaInsets;

  /// Called when a text input action is performed.
  final void Function(TextInputAction action)? onPerformAction;

  // IMPORTANT For project authors: The copyWith()
  // should be manually updated each time we add or remove a property

  QuillViewerConfig copyWith({
    LeadingBlockNodeBuilder? customLeadingBlockBuilder,
    String? placeholder,
    bool? checkBoxReadOnly,
    bool? disableClipboard,
    bool? scrollable,
    double? scrollBottomInset,
    bool? enableAlwaysIndentOnTab,
    EdgeInsetsGeometry? padding,
    bool? autoFocus,
    bool? onTapOutsideEnabled,
    Function(PointerDownEvent event, FocusNode focusNode)? onTapOutside,
    KeyEventResult? Function(KeyEvent event, Node? node)? onKeyPressed,
    bool? showCursor,
    bool? paintCursorAboveText,
    MouseCursor? readOnlyMouseCursor,
    bool? enableInteractiveSelection,
    bool? enableSelectionToolbar,
    double? minHeight,
    double? maxHeight,
    double? maxContentWidth,
    DefaultStyles? customStyles,
    bool? expands,
    TextCapitalization? textCapitalization,
    Brightness? keyboardAppearance,
    ScrollPhysics? scrollPhysics,
    ValueChanged<String>? onLaunchUrl,
    bool Function(TapDownDetails details, TextPosition Function(Offset offset))?
        onTapDown,
    bool Function(TapUpDetails details, TextPosition Function(Offset offset))?
        onTapUp,
    Iterable<EmbedBuilder>? embedBuilders,
    TextSpanBuilder? textSpanBuilder,
    EmbedBuilder? unknownEmbedBuilder,
    LinkActionPickerDelegate? linkActionPickerDelegate,
    bool? floatingCursorDisabled,
    TextSelectionControls? textSelectionControls,
    Map<ShortcutActivator, Intent>? customShortcuts,
    Map<Type, Action<Intent>>? customActions,
    bool? detectWordBoundary,
    List<String>? customLinkPrefixes,
    QuillEditorContextMenuBuilder? contextMenuBuilder,
    ContentInsertionConfiguration? contentInsertionConfiguration,
    GlobalKey<ViewerState>? editorKey,
    TextSelectionThemeData? textSelectionThemeData,
    bool? requestKeyboardFocusOnCheckListChanged,
    TextInputAction? textInputAction,
    bool? enableScribble,
    void Function()? onScribbleActivated,
    EdgeInsets? scribbleAreaInsets,
    void Function(TextInputAction action)? onPerformAction,
  }) {
    return QuillViewerConfig(
      customLeadingBlockBuilder:
          customLeadingBlockBuilder ?? this.customLeadingBlockBuilder,
      placeholder: placeholder ?? this.placeholder,
      checkBoxReadOnly: checkBoxReadOnly ?? this.checkBoxReadOnly,
      disableClipboard: disableClipboard ?? this.disableClipboard,
      scrollable: scrollable ?? this.scrollable,
      onKeyPressed: onKeyPressed ?? this.onKeyPressed,
      scrollBottomInset: scrollBottomInset ?? this.scrollBottomInset,
      enableAlwaysIndentOnTab:
          enableAlwaysIndentOnTab ?? this.enableAlwaysIndentOnTab,
      padding: padding ?? this.padding,
      autoFocus: autoFocus ?? this.autoFocus,
      onTapOutsideEnabled: onTapOutsideEnabled ?? this.onTapOutsideEnabled,
      onTapOutside: onTapOutside ?? this.onTapOutside,
      showCursor: showCursor ?? this.showCursor,
      paintCursorAboveText: paintCursorAboveText ?? this.paintCursorAboveText,
      readOnlyMouseCursor: readOnlyMouseCursor ?? this.readOnlyMouseCursor,
      enableInteractiveSelection:
          enableInteractiveSelection ?? this.enableInteractiveSelection,
      enableSelectionToolbar:
          enableSelectionToolbar ?? this.enableSelectionToolbar,
      minHeight: minHeight ?? this.minHeight,
      maxHeight: maxHeight ?? this.maxHeight,
      maxContentWidth: maxContentWidth ?? this.maxContentWidth,
      customStyles: customStyles ?? this.customStyles,
      expands: expands ?? this.expands,
      textCapitalization: textCapitalization ?? this.textCapitalization,
      keyboardAppearance: keyboardAppearance ?? this.keyboardAppearance,
      scrollPhysics: scrollPhysics ?? this.scrollPhysics,
      onLaunchUrl: onLaunchUrl ?? this.onLaunchUrl,
      onTapUp: onTapUp ?? this.onTapUp,
      onTapDown: onTapDown ?? this.onTapDown,
      embedBuilders: embedBuilders ?? this.embedBuilders,
      textSpanBuilder: textSpanBuilder ?? this.textSpanBuilder,
      unknownEmbedBuilder: unknownEmbedBuilder ?? this.unknownEmbedBuilder,
      linkActionPickerDelegate:
          linkActionPickerDelegate ?? this.linkActionPickerDelegate,
      floatingCursorDisabled:
          floatingCursorDisabled ?? this.floatingCursorDisabled,
      textSelectionControls:
          textSelectionControls ?? this.textSelectionControls,
      customShortcuts: customShortcuts ?? this.customShortcuts,
      customActions: customActions ?? this.customActions,
      detectWordBoundary: detectWordBoundary ?? this.detectWordBoundary,
      customLinkPrefixes: customLinkPrefixes ?? this.customLinkPrefixes,
      contextMenuBuilder: contextMenuBuilder ?? this.contextMenuBuilder,
      contentInsertionConfiguration:
          contentInsertionConfiguration ?? this.contentInsertionConfiguration,
      viewerKey: editorKey ?? this.viewerKey,
      textSelectionThemeData:
          textSelectionThemeData ?? this.textSelectionThemeData,
      requestKeyboardFocusOnCheckListChanged:
          requestKeyboardFocusOnCheckListChanged ??
              this.requestKeyboardFocusOnCheckListChanged,
      textInputAction: textInputAction ?? this.textInputAction,
      enableScribble: enableScribble ?? this.enableScribble,
      onScribbleActivated: onScribbleActivated ?? this.onScribbleActivated,
      scribbleAreaInsets: scribbleAreaInsets ?? this.scribbleAreaInsets,
      onPerformAction: onPerformAction ?? this.onPerformAction,
    );
  }
}
