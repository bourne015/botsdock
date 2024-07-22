import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';

import '../utils/constants.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => SettingsViewState();
}

class SettingsViewState extends State<SettingsView> with RestorationMixin {
  final RestorableInt _selectedIndex = RestorableInt(0);

  @override
  String get restorationId => 'settings';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selectedIndex, 'selected_index');
  }

  @override
  void dispose() {
    _selectedIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> selectedWidgets = [
      Center(child: modelDesc(context)),
      Center(child: Text("blank page")),
    ];

    return Scaffold(
        appBar: AppBar(
          title: Text('Notice'),
          backgroundColor: AppColors.chatPageBackground,
        ),
        backgroundColor: AppColors.chatPageBackground,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex.value,
              // leading: FloatingActionButton(
              //   onPressed: () {},
              //   child: const Icon(Icons.add),
              // ),
              labelType: NavigationRailLabelType.selected,
              backgroundColor: AppColors.chatPageBackground,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex.value = index;
                });
              },
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.currency_exchange_outlined),
                  selectedIcon: const Icon(Icons.currency_exchange_rounded),
                  label: Text("Price"),
                ),
                NavigationRailDestination(
                  disabled: true,
                  icon: const Icon(Icons.settings_applications_outlined),
                  selectedIcon: const Icon(Icons.settings_applications),
                  label: Text("Settings"),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: selectedWidgets[_selectedIndex.value],
            ),
          ],
        ));
  }

  Widget modelDesc(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(10),
        ),
        columns: [
          DataColumn(label: Text('')),
          DataColumn(
              label: Text(GalleryLocalizations.of(context)!.modelDescription)),
          DataColumn(
              label: Text(GalleryLocalizations.of(context)!.contextWindow)),
          DataColumn(label: Text(GalleryLocalizations.of(context)!.cost)),
          DataColumn(label: Text(GalleryLocalizations.of(context)!.inputFormat))
        ],
        rows: [
          DataRow(cells: [
            DataCell(Text('GPT-3.5')),
            DataCell(Text(GalleryLocalizations.of(context)!.chatGPT35Desc)),
            DataCell(Text('16,385 tokens')),
            DataCell(Text('Input: \$0.50; Output: \$1.50')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat1)),
          ]),
          DataRow(cells: [
            DataCell(Text('GPT-4')),
            DataCell(Text(GalleryLocalizations.of(context)!.chatGPT40Desc)),
            DataCell(Text('128K tokens')),
            DataCell(Text('Input: \$10.00; Output: \$30.00')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat2)),
          ]),
          DataRow(selected: true, cells: [
            DataCell(Text('GPT-4o')),
            DataCell(Text(GalleryLocalizations.of(context)!.chatGPT4oDesc)),
            DataCell(Text('128K tokens')),
            DataCell(Text('Input: \$5.00; Output: \$15.00')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat2)),
          ]),
          DataRow(selected: true, cells: [
            DataCell(Text('GPT-4o mini')),
            DataCell(Text(GalleryLocalizations.of(context)!.chatGPT4oMiniDesc)),
            DataCell(Text('128K tokens')),
            DataCell(Text('Input: \$0.15; Output: \$0.60')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat2)),
          ]),
          DataRow(cells: [
            DataCell(Text('DALL·E')),
            DataCell(Text(GalleryLocalizations.of(context)!.dallEDesc)),
            DataCell(Text('-')),
            DataCell(Text('\$0.040 / image')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat1)),
          ]),
          DataRow(cells: [
            DataCell(Text('Claude 3 Haiku')),
            DataCell(Text(GalleryLocalizations.of(context)!.claude3HaikuDesc)),
            DataCell(Text('200K tokens')),
            DataCell(Text('Input: \$0.25; Output: \$1.25')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat2)),
          ]),
          DataRow(cells: [
            DataCell(Text('Claude 3 Sonnet')),
            DataCell(Text(GalleryLocalizations.of(context)!.claude3SonnetDesc)),
            DataCell(Text('200K tokens')),
            DataCell(Text('Input: \$3.00; Output: \$15.00')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat2)),
          ]),
          DataRow(cells: [
            DataCell(Text('Claude 3 Opus')),
            DataCell(Text(GalleryLocalizations.of(context)!.claude3OpusDesc)),
            DataCell(Text('200K tokens')),
            DataCell(Text('Input: \$15.00; Output: \$75.00')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat2)),
          ]),
          DataRow(selected: true, cells: [
            DataCell(Text('Claude 3.5 Sonnet')),
            DataCell(
                Text(GalleryLocalizations.of(context)!.claude35SonnetDesc)),
            DataCell(Text('200K tokens')),
            DataCell(Text('Input: \$3.00; Output: \$15.00')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat2)),
          ]),
        ],
      ),
    );
  }
}
