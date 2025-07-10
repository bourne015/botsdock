import 'package:botsdock/apps/chat/models/mcp/mcp_models.dart';
import 'package:botsdock/apps/chat/models/mcp/mcp_providers.dart';
import 'package:botsdock/apps/chat/models/mcp/mcp_server_config.dart';
import 'package:botsdock/apps/chat/models/mcp/mcp_settings_providers.dart';
import 'package:botsdock/apps/chat/models/user.dart';
import 'package:botsdock/apps/chat/views/menu/mcp_server_list_item.dart';
import 'package:botsdock/apps/chat/views/menu/mcp_server_dialog.dart';
import 'package:botsdock/l10n/gallery_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MCPConfig extends ConsumerStatefulWidget {
  final User user;
  const MCPConfig({super.key, required this.user});

  @override
  ConsumerState<MCPConfig> createState() => _MCPConfigState();
}

class _MCPConfigState extends ConsumerState<MCPConfig> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      height: 1000,
      margin: EdgeInsets.all(15),
      child: Scaffold(
        appBar: AppBar(title: Text("MCP servers")),
        body: mcpItems(context),
      ),
    );
  }

  Widget mcpItems(BuildContext context) {
    final serverList = ref.watch(mcpServerListProvider);
    final mcpState = ref.watch(mcpClientProvider);

    final serverStatuses = mcpState.serverStatuses;
    final serverErrors = mcpState.serverErrorMessages;
    final connectedCount = mcpState.connectedServerCount;
    final serverTools = mcpState.discoveredTools;

    return ListView(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              GalleryLocalizations.of(context)!.mcpServers,
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: GalleryLocalizations.of(context)!.mcpAdd,
              onPressed: () => _openServerDialog(),
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        Text(
          '$connectedCount server(s) connected.',
          style: const TextStyle(fontSize: 12.0, color: Colors.grey),
        ),
        const SizedBox(height: 12.0),
        serverList.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    "No MCP servers configured. Click '+' to add.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: serverList.length,
                itemBuilder: (context, index) {
                  final server = serverList[index];
                  final status = serverStatuses[server.id] ??
                      McpConnectionStatus.disconnected;
                  final error = serverErrors[server.id];
                  final tools = serverTools[server.id];

                  return McpServerListItem(
                    server: server,
                    status: status,
                    errorMessage: error,
                    tools: tools,
                    user: widget.user,
                    onToggleActive: _toggleServerActive,
                    onEdit: (server) => _openServerDialog(serverToEdit: server),
                    onDelete: _deleteServer,
                  );
                },
              ),
        const SizedBox(height: 12.0),
      ],
    );
  }

  void _openServerDialog({McpServerConfig? serverToEdit}) {
    showServerDialog(
      context: context,
      serverToEdit: serverToEdit,
      onAddServer: (name, type, command, args, envVars, isActive) {
        ref
            .read(settingsServiceProvider)
            .addMcpServer(name, type, command, args, envVars, widget.user.id,
                widget.user.name)
            .then((_) => _showSnackbar('Server "$name" added.'))
            .catchError((e) => _showSnackbar('Error saving server: $e'));
      },
      onUpdateServer: (updatedServer) {
        ref
            .read(settingsServiceProvider)
            .updateMcpServer(updatedServer)
            .then(
              (_) => _showSnackbar('Server "${updatedServer.name}" updated.'),
            )
            .catchError((e) => _showSnackbar('Error updating server: $e'));
      },
      onError: _showSnackbar,
    );
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _toggleServerActive(String serverId, bool isActive) {
    ref
        .read(settingsServiceProvider)
        .toggleMcpServerActive(serverId, isActive)
        .catchError(
          (e) => _showSnackbar('Error updating server active state: $e'),
        );
  }

  void _deleteServer(McpServerConfig server) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('${GalleryLocalizations.of(context)!.mcpDel}?'),
          content: Text(
            'Are you sure you want to delete the server "${server.name}"?',
          ),
          actions: <Widget>[
            TextButton(
              child: Text(GalleryLocalizations.of(context)!.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(GalleryLocalizations.of(context)!.delete),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ref
                    .read(settingsServiceProvider)
                    .deleteMcpServer(server.id)
                    .then(
                      (_) => _showSnackbar('Server "${server.name}" deleted.'),
                    )
                    .catchError(
                      (e) => _showSnackbar('Error deleting server: $e'),
                    );
              },
            ),
          ],
        );
      },
    );
  }
}
