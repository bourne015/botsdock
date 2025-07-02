import 'package:botsdock/apps/chat/models/mcp/mcp_models.dart';
import 'package:botsdock/apps/chat/models/mcp/mcp_server_config.dart';
import 'package:botsdock/apps/chat/models/user.dart';
import 'package:botsdock/apps/chat/utils/constants.dart';
import 'package:botsdock/l10n/gallery_localizations.dart';
import 'package:flutter/material.dart';

import 'mcp_connection_status.dart';

class McpServerListItem extends StatelessWidget {
  final McpServerConfig server;
  final McpConnectionStatus status;
  final String? errorMessage;
  final List<McpToolDefinition>? tools;
  final User? user;
  final Function(String, bool) onToggleActive;
  final Function(McpServerConfig) onEdit;
  final Function(McpServerConfig) onDelete;

  const McpServerListItem({
    super.key,
    required this.server,
    required this.status,
    this.user,
    this.errorMessage,
    this.tools,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool userWantsActive = server.isActive;
    final int customEnvCount = server.customEnvironment.length;

    return Card(
      elevation: userWantsActive ? 2 : 1,
      color: Theme.of(context).colorScheme.secondaryContainer,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: InkWell(
        onLongPress: () {
          if (user != null && user!.id == server.owner_id) onEdit(server);
        },
        borderRadius: BORDERRADIUS10,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: Tooltip(
              message: status.name,
              child: McpConnectionStatusIndicator(
                  status: status, name: server.name),
            ),
            trailing: Transform.scale(
              scale: 0.7,
              child: Switch(
                value: userWantsActive,
                onChanged: (bool value) => onToggleActive(server.id, value),
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              server.name,
              style: TextStyle(
                fontWeight:
                    userWantsActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${server.description}'.trim(),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (customEnvCount > 0)
                  Text(
                    '$customEnvCount custom env var(s)',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.blueGrey,
                    ),
                  ),
              ],
            ),
          ),
          // Error and Action Row
          Padding(
            padding: const EdgeInsets.only(left: 65.0, right: 30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                toolsButton(context),
                if (server.isActive) NoteMessage(context),
                SizedBox(width: 20),
                if (user != null && user!.id == server.owner_id)
                  actions(context)
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget toolsButton(BuildContext context) {
    var title = '';
    if (!server.isActive)
      title = "Disabled";
    else if (tools != null)
      title = "${tools?.length} tools enabled";
    else if (errorMessage != null) title = "Connection failed:";
    return Transform.scale(
      scale: 0.9,
      child: TextButton.icon(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          padding: WidgetStateProperty.all(EdgeInsets.zero),
        ),
        label: Text(title, style: Theme.of(context).textTheme.bodyMedium),
        onPressed: () {
          if (tools != null) toolsList(context);
        },
        icon: tools != null ? Icon(Icons.expand_more) : null,
        iconAlignment: IconAlignment.end,
      ),
    );
  }

  Widget NoteMessage(BuildContext context) {
    return Expanded(
      child: errorMessage != null
          ? Tooltip(
              waitDuration: Duration(milliseconds: 500),
              message: errorMessage!,
              child: Text(
                '$errorMessage',
                style: Theme.of(context).textTheme.labelSmall,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            )
          : tools != null
              ? Text(
                  tools!.map((tool) => tool.name).join(', '),
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                )
              : const SizedBox(height: 14),
    );
  }

  void toolsList(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("工具列表"),
          content: Container(
            padding: EdgeInsets.only(top: 10),
            width: 400,
            height: 500,
            child: ListView.builder(
              itemCount: tools!.length,
              itemBuilder: (context, index) {
                return Card(
                  child: InkWell(
                    onLongPress: () {},
                    borderRadius: BORDERRADIUS10,
                    child: ListTile(
                      leading: Text('${index + 1}'),
                      title: Text(tools![index].name),
                      subtitle: Text(
                        tools![index].description ?? "",
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget actions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          tooltip: GalleryLocalizations.of(context)!.edit,
          onPressed: () => onEdit(server),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            size: 18,
            color: Theme.of(context).colorScheme.error,
          ),
          tooltip: GalleryLocalizations.of(context)!.delete,
          onPressed: () => onDelete(server),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}
