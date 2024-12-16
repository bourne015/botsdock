// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';
import 'package:botsdock/constants.dart';
import 'package:botsdock/data/demos.dart';
import 'package:botsdock/data/gallery_options.dart';
import 'package:botsdock/data/adaptive.dart';
import 'package:botsdock/apps/chat/routes.dart' as chat_routes;

import 'apps/chat/utils/constants.dart';

const _horizontalPadding = 32.0;
const _horizontalDesktopPadding = 81.0;
const _carouselHeightMin = 240.0;
const _carouselItemDesktopMargin = 0.0; //8.0;
const _carouselItemMobileMargin = 4.0;
const _carouselItemWidth = 296.0;

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = GalleryLocalizations.of(context)!;
    final studyDemos = Demos.studies(localizations);
    final carouselCards = <Widget>[
      _CarouselCard(
        demo: studyDemos['chat'],
        textColor: Color(0xFF005D57),
        asset: const AssetImage(
          'assets/images/chat/chat_card.png',
        ),
        assetColor: const Color(0xFFD1F2E6),
        assetDark: AssetImage('assets/images/chat/chat_card_dark.png'),
        assetDarkColor: const Color(0xFF253538),
        studyRoute: chat_routes.homeRoute,
      ),
    ];

    return Scaffold(
      body: Column(
        children: [
          Flexible(
              child: ListView(
            // Makes integration tests possible.
            key: const ValueKey('HomeListView'),
            primary: true,
            padding: const EdgeInsetsDirectional.only(
              top: firstHeaderDesktopTopPadding,
            ),
            children: [
              _DesktopHomeItem(child: _GalleryHeader()),
              _ListApps(apps: carouselCards),
            ],
          )),
          Align(
            alignment: Alignment.bottomCenter,
            child: Text("welcome"),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _GalleryHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Header(
      color: Theme.of(context).colorScheme.primaryContainer,
      text: GalleryLocalizations.of(context)!.homeHeaderGallery,
    );
  }
}

class Header extends StatelessWidget {
  const Header({super.key, required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: EdgeInsets.only(
          top: isDisplayDesktop(context) ? 63 : 15,
          bottom: isDisplayDesktop(context) ? 21 : 11,
        ),
        child: SelectableText(
          text,
          style: Theme.of(context).textTheme.headlineMedium!.apply(
                color: color,
                fontSizeDelta:
                    isDisplayDesktop(context) ? desktopDisplay1FontDelta : 0,
              ),
        ),
      ),
    );
  }
}

class _DesktopHomeItem extends StatelessWidget {
  const _DesktopHomeItem({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        constraints: const BoxConstraints(maxWidth: maxHomeItemWidth),
        padding: EdgeInsets.symmetric(
          horizontal:
              isDisplayDesktop(context) ? _horizontalDesktopPadding : 30,
        ),
        child: child,
      ),
    );
  }
}

class _ListApps extends StatelessWidget {
  const _ListApps({required this.apps});

  final List<Widget> apps;

  @override
  Widget build(BuildContext context) {
    final isDesktop = isDisplayDesktop(context);
    return Align(
        alignment: Alignment.center,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop
                ? _horizontalDesktopPadding - _carouselItemDesktopMargin + 50
                : _horizontalPadding - _carouselItemMobileMargin,
          ),
          constraints: isDesktop
              ? BoxConstraints(
                  maxHeight: _carouselHeight(0.7, context),
                )
              : BoxConstraints(
                  maxWidth: _carouselItemWidth + 80,
                  maxHeight: _carouselHeight(2.7, context),
                ),
          child: CarouselView(
              // shape: RoundedRectangleBorder(
              //   borderRadius: BorderRadius.circular(10),
              // ),
              shrinkExtent: _carouselHeight(0.7, context),
              itemExtent: isDesktop ? _carouselItemWidth : _carouselHeightMin,
              enableSplash: false,
              scrollDirection: isDesktop ? Axis.horizontal : Axis.vertical,
              children: this.apps),
        ));
  }
}

class _CarouselCard extends StatelessWidget {
  const _CarouselCard({
    required this.demo,
    this.asset,
    this.assetDark,
    this.assetColor,
    this.assetDarkColor,
    this.textColor,
    required this.studyRoute,
  });

  final GalleryDemo? demo;
  final ImageProvider? asset;
  final ImageProvider? assetDark;
  final Color? assetColor;
  final Color? assetDarkColor;
  final Color? textColor;
  final String studyRoute;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final asset = isDark ? assetDark : this.asset;
    final assetColor = isDark ? assetDarkColor : this.assetColor;
    final textColor =
        isDark ? Colors.white.withValues(alpha: 0.87) : this.textColor;
    final isDesktop = isDisplayDesktop(context);

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop
              ? _carouselItemDesktopMargin
              : _carouselItemMobileMargin),
      margin: const EdgeInsets.only(top: 16, bottom: 16, right: 16),
      height: _carouselHeight(0.7, context),
      width: _carouselItemWidth,
      child: Material(
        // Makes integration tests possible.
        key: ValueKey(demo!.describe),
        color: assetColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BORDERRADIUS10),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (asset != null)
              FadeInImage(
                image: asset,
                placeholder: MemoryImage(kTransparentImage),
                fit: BoxFit.cover,
                height: _carouselHeightMin,
                fadeInDuration: entranceAnimationDuration,
              ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    demo!.title,
                    style: textTheme.bodySmall!.apply(color: textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    demo!.subtitle,
                    style: textTheme.labelSmall!.apply(color: textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context)
                        .popUntil((route) => route.settings.name == '/');
                    Navigator.of(context).restorablePushNamed(studyRoute);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

double _carouselHeight(double scaleFactor, BuildContext context) => math.max(
    _carouselHeightMin *
        GalleryOptions.of(context).textScaleFactor(context) *
        scaleFactor,
    _carouselHeightMin);
