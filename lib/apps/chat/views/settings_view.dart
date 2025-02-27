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
          borderRadius: BORDERRADIUS10,
        ),
        columns: [
          DataColumn(label: Text('')),
          DataColumn(
              label: Text(GalleryLocalizations.of(context)!.contextWindow)),
          DataColumn(label: Text(GalleryLocalizations.of(context)!.price)),
          DataColumn(label: Text(GalleryLocalizations.of(context)!.inputFormat))
        ],
        rows: [
          DataRow(cells: [
            DataCell(Text('GPT-4o mini')),
            DataCell(Text('128K tokens')),
            DataCell(Text('input:   \$0.15\noutput: \$0.60')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat2)),
          ]),
          DataRow(selected: true, cells: [
            DataCell(Text('GPT-4o')),
            DataCell(Text('128K tokens')),
            DataCell(Text('input:   \$2.50\noutput: \$10.00')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat2)),
          ]),
          DataRow(cells: [
            DataCell(Text('o1 mini')),
            DataCell(Text('128K tokens')),
            DataCell(Text('input:   \$1.10\noutput: \$4.40')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat1)),
          ]),
          DataRow(cells: [
            DataCell(Text('DALL·E')),
            DataCell(Text('-')),
            DataCell(Text('\$0.040 / image')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat1)),
          ]),
          DataRow(cells: [
            DataCell(Text('Claude 3.5 Haiku')),
            DataCell(Text('200K tokens')),
            DataCell(Text('input:   \$0.80\noutput: \$4.00')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat2)),
          ]),
          DataRow(cells: [
            DataCell(Text('Claude 3.5 Sonnet')),
            DataCell(Text('200K tokens')),
            DataCell(Text('input:   \$3.00\noutput: \$15.00')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat2)),
          ]),
          DataRow(selected: true, cells: [
            DataCell(Text('Claude 3.7 Sonnet')),
            DataCell(Text('200K tokens')),
            DataCell(Text('input:  \$3.00\noutput: \$15.00')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat2)),
          ]),
          DataRow(cells: [
            DataCell(Text('Claude 3 Opus')),
            DataCell(Text('200K tokens')),
            DataCell(Text('input:   \$15.00\noutput: \$75.00')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat2)),
          ]),
          DataRow(cells: [
            DataCell(Text('Gemini 1.5 Pro')),
            DataCell(Text('2M tokens')),
            DataCell(Text('input:   \$0.15\noutput: \$0.60')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat2)),
          ]),
          DataRow(selected: true, cells: [
            DataCell(Text('Gemini 2.0 Flash')),
            DataCell(Text('1M tokens')),
            DataCell(Text('input:   \$0.10\noutput: \$0.40')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat2)),
          ]),
          DataRow(cells: [
            DataCell(Text('DeepSeek V3')),
            DataCell(Text('64K tokens')),
            DataCell(Text('input:   \$0.27\noutput: \$1.10')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat2)),
          ]),
          DataRow(selected: true, cells: [
            DataCell(Text('DeepSeek R1')),
            DataCell(Text('64K tokens')),
            DataCell(Text('input:   \$0.55\noutput: \$2.19')),
            DataCell(Text(GalleryLocalizations.of(context)!.inputFormat2)),
          ]),
        ],
      ),
    );
  }
}
