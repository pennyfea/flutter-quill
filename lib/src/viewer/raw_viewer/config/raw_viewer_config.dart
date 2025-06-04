import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../../../editor/embed/embed_editor_builder.dart';
import '../../../editor/raw_editor/builders/leading_block_builder.dart';
import '../../../editor/widgets/default_styles.dart';
import '../../../editor/widgets/link.dart';
import '../../widgets/text/utils/text_block_utils.dart';

@immutable
class QuillRawViewerConfig {
  const QuillRawViewerConfig({
    required this.scrollController,
    required this.scrollBottomInset,
    required this.embedBuilder,
    required this.textSpanBuilder,
    this.customStyles,
    this.scrollable = true,
    this.padding = EdgeInsets.zero,
    this.checkBoxReadOnly,
    this.placeholder,
    this.onLaunchUrl,
    this.textCapitalization = TextCapitalization.none,
    this.maxHeight,
    this.minHeight,
    this.maxContentWidth,
    this.expands = false,
    this.scrollPhysics,
    this.linkActionPickerDelegate = defaultLinkActionPickerDelegate,
    this.customLinkPrefixes = const <String>[],
    this.contentInsertionConfiguration,
    @experimental this.customLeadingBuilder,
  });

  final ScrollController scrollController;
  final bool scrollable;
  final double scrollBottomInset;
  @experimental
  final LeadingBlockNodeBuilder? customLeadingBuilder;

  /// Additional space around the editor contents.
  final EdgeInsetsGeometry padding;

  /// Override readOnly for checkbox.
  ///
  /// When this is set to false, the checkbox can be checked
  /// or unchecked while readOnly is set to true.
  /// When this is set to null, the readOnly value is used.
  ///
  /// Defaults to null.
  final bool? checkBoxReadOnly;

  final String? placeholder;

  /// Callback which is triggered when the user wants to open a URL from
  /// a link in the document.
  final ValueChanged<String>? onLaunchUrl;

  /// Configures how the platform keyboard will select an uppercase or
  /// lowercase keyboard.
  ///
  /// Only supports text keyboards, other keyboard types will ignore this
  /// configuration. Capitalization is locale-aware.
  ///
  /// Defaults to [TextCapitalization.none]. Must not be null.
  ///
  /// See also:
  ///
  ///  * [TextCapitalization], for a description of each capitalization behavior
  final TextCapitalization textCapitalization;

  /// The maximum height this editor can have.
  ///
  /// If this is null then there is no limit to the editor's height and it will
  /// expand to fill its parent.
  final double? maxHeight;

  /// The minimum height this editor can have.
  final double? minHeight;

  /// The maximum width to be occupied by the content of this editor.
  ///
  /// If this is not null and and this editor's width is larger than this value
  /// then the contents will be constrained to the provided maximum width and
  /// horizontally centered. This is mostly useful on devices with wide screens.
  final double? maxContentWidth;

  /// Allows to override [DefaultStyles].
  final DefaultStyles? customStyles;

  /// Whether this widget's height will be sized to fill its parent.
  ///
  /// If set to true and wrapped in a parent widget like [Expanded] or
  ///
  /// Defaults to false.
  final bool expands;

  /// The [ScrollPhysics] to use when vertically scrolling the input.
  ///
  /// If not specified, it will behave according to the current platform.
  ///
  /// See [Scrollable.physics].
  final ScrollPhysics? scrollPhysics;

  /// Builder function for embeddable objects.
  final EmbedsBuilder embedBuilder;
  final LinkActionPickerDelegate linkActionPickerDelegate;
  final List<String> customLinkPrefixes;

  /// Used to build the [InlineSpan]s containing text content.
  final TextSpanBuilder textSpanBuilder;

  /// Configuration of handler for media content inserted via the system input
  /// method.
  ///
  /// See [https://api.flutter.dev/flutter/widgets/EditableText/contentInsertionConfiguration.html]
  final ContentInsertionConfiguration? contentInsertionConfiguration;
}
