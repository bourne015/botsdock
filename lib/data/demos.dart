// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations_en.dart'
    show GalleryLocalizationsEn;

enum GalleryDemoCategory {
  study,
  material,
  cupertino,
  other;

  @override
  String toString() {
    return name.toUpperCase();
  }
}

class GalleryDemo {
  const GalleryDemo({
    required this.title,
    required this.category,
    required this.subtitle,
    // This parameter is required for studies.
    this.studyId,
    // Parameters below are required for non-study demos.
    this.slug,
    this.icon,
    this.configurations = const [],
  })  : assert(category == GalleryDemoCategory.study ||
            (slug != null && icon != null)),
        assert(slug != null || studyId != null);

  final String title;
  final GalleryDemoCategory category;
  final String subtitle;
  final String? studyId;
  final String? slug;
  final IconData? icon;
  final List<GalleryDemoConfiguration> configurations;

  String get describe => '${slug ?? studyId}@${category.name}';
}

class GalleryDemoConfiguration {
  const GalleryDemoConfiguration({
    required this.title,
    required this.description,
    required this.documentationUrl,
    required this.buildRoute,
  });

  final String title;
  final String description;
  final String documentationUrl;
  final WidgetBuilder buildRoute;
}

class Demos {
  static Map<String?, GalleryDemo> asSlugToDemoMap(BuildContext context) {
    final localizations = GalleryLocalizations.of(context)!;
    return LinkedHashMap<String?, GalleryDemo>.fromIterable(
      all(localizations),
      key: (dynamic demo) => demo.slug as String?,
    );
  }

  static List<GalleryDemo> all(GalleryLocalizations localizations) =>
      studies(localizations).values.toList();

  static List<String> allDescriptions() =>
      all(GalleryLocalizationsEn()).map((demo) => demo.describe).toList();

  static Map<String, GalleryDemo> studies(GalleryLocalizations localizations) {
    return <String, GalleryDemo>{
      'chat': GalleryDemo(
        title: 'Chat',
        subtitle: localizations.chatDescription,
        category: GalleryDemoCategory.study,
        studyId: 'chat',
      ),
    };
  }
}
