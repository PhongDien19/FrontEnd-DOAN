import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:linkify/linkify.dart';
import 'package:url_launcher/url_launcher.dart';

/// Hiển thị text có link có thể nhấn được.
/// - Tự động thêm scheme `https://` nếu URL thiếu.
/// - Dùng `launchUrl(externalApplication)` để mở trình duyệt ngoài.
/// - Có try/catch + log chi tiết để debug qua `adb logcat`.
class ClickableUrlText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const ClickableUrlText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  State<ClickableUrlText> createState() => _ClickableUrlTextState();
}

class _ClickableUrlTextState extends State<ClickableUrlText> {
  late List<LinkifyElement> _linkified;

  @override
  void initState() {
    super.initState();
    _parseText();
  }

  @override
  void didUpdateWidget(covariant ClickableUrlText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _parseText();
    }
  }

  void _parseText() {
    _linkified = linkify(
      widget.text,
      options: const LinkifyOptions(removeWww: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle =
        widget.style ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle();

    final linkStyle = defaultStyle.copyWith(
      color: const Color(0xFF2563EB),
      decoration: TextDecoration.underline,
      decorationColor: const Color(0xFF2563EB),
    );

    if (_linkified.isEmpty) {
      return Text(
        widget.text,
        style: defaultStyle,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      );
    }

    final spans = <InlineSpan>[];
    for (final element in _linkified) {
      if (element is LinkableElement) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: _ClickableLink(
              url: element.url,
              text: element.text,
              style: linkStyle,
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: element.text, style: defaultStyle));
      }
    }

    return RichText(
      text: TextSpan(children: spans),
      textDirection: TextDirection.ltr,
      softWrap: true,
      maxLines: widget.maxLines,
      overflow: widget.overflow ?? TextOverflow.visible,
    );
  }
}

/// Mở URL ra trình duyệt ngoài.
/// Tự thêm `https://` nếu thiếu scheme.
Future<bool> openExternalUrl(String rawUrl) async {
  String effectiveUrl = rawUrl.trim();
  if (!effectiveUrl.startsWith('http://') &&
      !effectiveUrl.startsWith('https://')) {
    effectiveUrl = 'https://$effectiveUrl';
  }

  final uri = Uri.tryParse(effectiveUrl);
  if (uri == null) {
    debugPrint('[ClickableUrl] Invalid URI: $rawUrl');
    return false;
  }

  try {
    final canLaunch = await canLaunchUrl(uri);
    debugPrint('[ClickableUrl] canLaunch=$canLaunch url=$effectiveUrl');
    if (!canLaunch) {
      // Thử fallback không truyền mode
      return await launchUrl(uri);
    }
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on PlatformException catch (e) {
    debugPrint('[ClickableUrl] PlatformException code=${e.code} '
        'msg=${e.message} url=$effectiveUrl');
    return false;
  } catch (e, st) {
    debugPrint('[ClickableUrl] Error launching URL: $effectiveUrl\n$e\n$st');
    return false;
  }
}

class _ClickableLink extends StatefulWidget {
  final String url;
  final String text;
  final TextStyle? style;

  const _ClickableLink({
    required this.url,
    required this.text,
    this.style,
  });

  @override
  State<_ClickableLink> createState() => _ClickableLinkState();
}

class _ClickableLinkState extends State<_ClickableLink> {
  bool _isPressed = false;

  Future<void> _onTap() async {
    debugPrint('[ClickableUrl] TAP on "${widget.text}" -> ${widget.url}');
    final ok = await openExternalUrl(widget.url);
    debugPrint('[ClickableUrl] launch result=$ok');
  }

  @override
  Widget build(BuildContext context) {
    // Dùng Material + InkWell để có ripple + tăng hit-test area,
    // đồng thời tránh bị widget khác (Stack/Positioned) nuốt sự kiện chạm.
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: _onTap,
        onTapDown: (_) {
          if (mounted) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (mounted) setState(() => _isPressed = false);
        },
        onTapCancel: () {
          if (mounted) setState(() => _isPressed = false);
        },
        // Tăng vùng nhấn để tránh khó bấm trên màn hình thật
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Text(
            widget.text,
            style: widget.style?.copyWith(
              color: _isPressed
                  ? const Color(0xFF1D4ED8)
                  : const Color(0xFF2563EB),
            ),
          ),
        ),
      ),
    );
  }
}