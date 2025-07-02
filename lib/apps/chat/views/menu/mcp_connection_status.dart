import 'package:botsdock/apps/chat/models/mcp/mcp_models.dart';
import 'package:flutter/material.dart';

class McpConnectionStatusIndicator extends StatelessWidget {
  final McpConnectionStatus status;
  final String name;

  const McpConnectionStatusIndicator(
      {super.key, required this.status, required this.name});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var statusIcon;
    switch (status) {
      case McpConnectionStatus.connected:
        statusIcon = Icon(Icons.circle, color: Colors.greenAccent, size: 10);
      case McpConnectionStatus.connecting:
        // return const SizedBox(
        //   width: 20,
        //   height: 20,
        //   child: CircularProgressIndicator(strokeWidth: 2),
        // );
        statusIcon = Icon(Icons.circle, color: Colors.yellow, size: 10);
      case McpConnectionStatus.error:
        statusIcon = Icon(Icons.circle, color: Colors.redAccent, size: 10);
      case McpConnectionStatus.disconnected:
        statusIcon = Icon(
          Icons.circle_outlined,
          color: theme.disabledColor,
          size: 10,
        );
    }
    return Stack(
      alignment: AlignmentDirectional.bottomEnd,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 40,
            height: 40,
            // padding: EdgeInsets.all(5),
            // margin: EdgeInsets.all(5),
            color: Theme.of(context).colorScheme.surfaceTint,
            child: Center(
                child: Text(name[0],
                    style: Theme.of(context).textTheme.headlineSmall)),
          ),
        ),
        statusIcon,
      ],
    );
  }
}

class McpConnectionCounter extends StatelessWidget {
  final int connectedCount;

  const McpConnectionCounter({super.key, required this.connectedCount});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: connectedCount > 0
          ? '$connectedCount MCP Server(s) Connected'
          : 'No MCP Servers Connected',
      child: Row(
        children: [
          Icon(
            connectedCount > 0 ? Icons.link : Icons.link_off,
            color: connectedCount > 0
                ? Colors.green
                : Theme.of(context).disabledColor,
            size: 20,
          ),
          if (connectedCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                '$connectedCount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: connectedCount > 0
                      ? Colors.green[800]
                      : Theme.of(context).disabledColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
