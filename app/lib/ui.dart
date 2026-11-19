/// Material, with a [Text] that shows its words in the chosen language.
/// Screens import this instead of material.dart, so `Text('Saved')` and
/// `const Text('Saved')` both come out in Kannada when it is switched on.
library;

import 'package:flutter/material.dart' as m;
import 'package:flutter/material.dart' hide Text;

import 'i18n.dart';

export 'package:flutter/material.dart' hide Text;

class Text extends StatelessWidget {
  const Text(
    String this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  }) : textSpan = null;

  const Text.rich(
    InlineSpan this.textSpan, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  }) : data = null;

  final String? data;
  final InlineSpan? textSpan;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) => textSpan != null
      ? m.Text.rich(textSpan!, style: style, textAlign: textAlign, maxLines: maxLines, overflow: overflow, softWrap: softWrap)
      : m.Text(t(data!), style: style, textAlign: textAlign, maxLines: maxLines, overflow: overflow, softWrap: softWrap);
}
