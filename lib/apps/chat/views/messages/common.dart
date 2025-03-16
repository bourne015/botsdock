import 'package:botsdock/apps/chat/utils/constants.dart';
import 'package:botsdock/apps/chat/utils/markdown_extentions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:markdown/markdown.dart' as md;

Widget contentMarkdown(BuildContext context, String msg, {double? pSize}) {
  try {
    return SelectionArea(
        // key: UniqueKey(),
        child: MarkdownBody(
      // key: UniqueKey(),
      data: msg, //markdownTest,
      // selectable: true,
      shrinkWrap: true,
      //extensionSet: MarkdownExtensionSet.githubFlavored.value,
      onTapLink: (text, href, title) => launchUrl(Uri.parse(href!)),
      extensionSet: md.ExtensionSet(
        [
          ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
          ...[LatexBlockSyntax()],
        ],
        <md.InlineSyntax>[
          md.EmojiSyntax(),
          ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
          ...[LatexInlineSyntax()],
        ],
      ),
      // styleSheetTheme: MarkdownStyleSheetBaseTheme.platform,
      styleSheet: MarkdownStyleSheet(
        //h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        //h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        // p: TextStyle(
        //   fontSize: pSize ?? 16.0,
        //   // color: AppColors.msgText,
        // ),
        code: const TextStyle(
          inherit: false,
          // color: AppColors.msgText,
          fontWeight: FontWeight.bold,
        ),
        codeblockPadding: const EdgeInsets.all(10),
        codeblockDecoration: BoxDecoration(
          borderRadius: BORDERRADIUS10,
          // color: Colors.grey,
        ),
      ),
      builders: {
        'code': CodeBlockBuilder(context),
        'latex': LatexElementBuilder(
            // textStyle: const TextStyle(
            //   fontWeight: FontWeight.w100,
            // ),
            // textScaleFactor: 1.2,
            ),
      },
    ));
  } catch (e, stackTrace) {
    print("markdown error: $e");
    print("markdown error1: $stackTrace");
    return Text("error mark");
  }
}
