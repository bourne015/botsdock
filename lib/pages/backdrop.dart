// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gallery/data/gallery_options.dart';
import 'package:gallery/layout/adaptive.dart';
import 'package:gallery/pages/home.dart';

class Backdrop extends StatefulWidget {
  const Backdrop({
    super.key,
    required this.isDesktop,
    this.settingsPage,
    this.homePage,
  });

  final bool isDesktop;
  final Widget? settingsPage;
  final Widget? homePage;

  @override
  State<Backdrop> createState() => _BackdropState();
}

class _BackdropState extends State<Backdrop> with TickerProviderStateMixin {
  late AnimationController _iconController;
  late ValueNotifier<bool> _isSettingsOpenNotifier;
  late Widget _homePage;

  @override
  void initState() {
    super.initState();

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _isSettingsOpenNotifier = ValueNotifier(false);
    _homePage = widget.homePage ?? const HomePage();
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  Widget _buildStack(BuildContext context, BoxConstraints constraints) {
    final isDesktop = isDisplayDesktop(context);

    final Widget homePage = ValueListenableBuilder<bool>(
      valueListenable: _isSettingsOpenNotifier,
      builder: (context, isSettingsOpen, child) {
        return ExcludeSemantics(
          excluding: isSettingsOpen,
          child: FocusTraversalGroup(child: _homePage),
        );
      },
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: GalleryOptions.of(context).resolvedSystemUiOverlayStyle(),
      child: Stack(
        children: [
          if (!isDesktop) ...[
            Positioned(
              child: homePage,
            ),
          ],
          if (isDesktop) ...[
            Semantics(sortKey: const OrdinalSortKey(2), child: homePage),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: _buildStack,
    );
  }
}
