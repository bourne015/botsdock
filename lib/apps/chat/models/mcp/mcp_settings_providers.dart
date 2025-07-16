import 'dart:convert';

import 'package:botsdock/apps/chat/models/mcp/mcp_server_config.dart';
import 'package:botsdock/apps/chat/utils/client/dio_client.dart';
import 'package:botsdock/apps/chat/utils/client/path.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

enum McpAction { add, edit, active, delete }

// UUID generator for creating unique server IDs
const _uuid = Uuid();

const String mcpServerListKey = 'mcpServerList';

abstract class SettingsRepository {
  // MCP Server List
  Future<List<McpServerConfig>> getMcpServerList();
  Future<void> saveMcpServerList(
      List<McpServerConfig> servers, McpAction action,
      {int? index, String? deleteID});
}

/// Implementation of SettingsRepository using SharedPreferences.
class SettingsRepositoryImpl implements SettingsRepository {
  final SharedPreferences _prefs;
  final dio = DioClient();

  SettingsRepositoryImpl(this._prefs);

  Future<List<dynamic>> fetchMCP() async {
    try {
      debugPrint("fetch mcp servers from db");
      final resp = await dio.get(ChatPath.mcps);
      final List<dynamic> list = resp['mcps'] ?? [];
      return list;
    } catch (e) {
      return [];
    }
  }

  // --- MCP Server List ---
  @override
  Future<List<McpServerConfig>> getMcpServerList() async {
    try {
      final _data = await dio.get(ChatPath.share);
      List<McpServerConfig> dblist = [];

      final serverListJson = _prefs.getString(mcpServerListKey);
      if (serverListJson == null ||
          _data["mcp_updated"] != _prefs.getInt("mcp_updated_at")) {
        final list = await fetchMCP();
        if (list.isNotEmpty) {
          dblist = list.map((item) => McpServerConfig.fromJson(item)).toList();
          await _prefs.setString(mcpServerListKey, jsonEncode(list));
        }
        _prefs.setInt("mcp_updated_at", _data["mcp_updated"]);
      }

      if (serverListJson != null && serverListJson.isNotEmpty) {
        final decodedList = jsonDecode(serverListJson) as List;
        final configList = decodedList
            .map(
              (item) => McpServerConfig.fromJson(item as Map<String, dynamic>),
            )
            .toList();
        for (int i = 0; i < dblist.length; i++)
          for (int j = 0; j < configList.length; j++) {
            if (dblist[i].id == configList[j].id) {
              dblist[i].isActive = configList[j].isActive;
            }
          }
        if (dblist.isNotEmpty) return dblist;
        return configList;
      }
      return dblist;
    } catch (e) {
      debugPrint("Error loading/parsing server list in repository: $e");
      return []; // Return empty list on error
    }
  }

  @override
  Future<void> saveMcpServerList(
      List<McpServerConfig> servers, McpAction action,
      {int? index, String? deleteID}) async {
    try {
      final serverListJson = jsonEncode(
        servers.map((s) => s.toJson()).toList(),
      );
      await _prefs.setString(mcpServerListKey, serverListJson);

      switch (action) {
        case McpAction.add:
          await dio.post(ChatPath.mcp, data: servers.last);
          break;
        case McpAction.edit:
          await dio.post(ChatPath.mcpinfo(servers[index!].id),
              data: servers[index]);
          break;
        case McpAction.active:
          break;
        case McpAction.delete:
          await dio.delete(ChatPath.mcpinfo(deleteID!));
          break;
      }
    } catch (e) {
      debugPrint("Error saving MCP server list in repository: $e");
      rethrow;
    }
  }
}

/// Application service layer for managing settings-related operations.
/// It interacts with the [SettingsRepository] for persistence and updates
/// the state providers to reflect changes in the application state.
class SettingsService {
  final SettingsRepository _repository;

  final McpServerListNotifier _mcpServerListNotifier;

  SettingsService({
    required SettingsRepository repository,
    required McpServerListNotifier mcpServerListNotifier,
  })  : _repository = repository,
        _mcpServerListNotifier = mcpServerListNotifier;

  /// Saves the current list of MCP servers to the repository.
  /// This is called internally after any modification to the server list.
  /// index: index of the new server
  Future<void> _saveCurrentMcpListState(McpAction action,
      {int? index, String? deleteID}) async {
    // Read the current list from the state
    final currentList = _mcpServerListNotifier.currentList;
    try {
      // Persist the list using the repository
      await _repository.saveMcpServerList(currentList, action,
          index: index, deleteID: deleteID);
      debugPrint(
        "SettingsService: MCP Server list saved to repository. Count: ${currentList.length}",
      );
    } catch (e) {
      debugPrint("SettingsService: Error saving MCP server list: $e");
      rethrow;
    }
  }

  /// Adds a new MCP server configuration to the state and persists the change.
  Future<void> addMcpServer(
    String name,
    TransportType transportType,
    String command,
    String args,
    Map<String, String> customEnv,
    int user_id,
    String? user_name,
  ) async {
    // Create a new server config with a unique ID
    final newServer = McpServerConfig(
      id: _uuid.v4(), // Generate unique ID
      name: name,
      transportType: transportType,
      command: command,
      args: args,
      isActive: false, // New servers default to inactive
      customEnvironment: customEnv,
    );
    final currentList = _mcpServerListNotifier.currentList;
    // Update the state with the new list
    _mcpServerListNotifier.currentList = [...currentList, newServer];
    // Persist the updated list
    await _saveCurrentMcpListState(McpAction.add, index: -1);
    debugPrint("SettingsService: Added MCP Server '${newServer.name}'.");
  }

  /// Updates an existing MCP server configuration in the state and persists.
  Future<void> updateMcpServer(McpServerConfig updatedServer) async {
    final currentList = _mcpServerListNotifier.currentList;
    // Find the index of the server to update
    final index = currentList.indexWhere((s) => s.id == updatedServer.id);
    if (index != -1) {
      // Create a mutable copy, update the item, and update the state
      final newList = List<McpServerConfig>.from(currentList);
      newList[index] = updatedServer;
      _mcpServerListNotifier.currentList = newList;
      // Persist the updated list
      await _saveCurrentMcpListState(McpAction.edit, index: index);
      debugPrint(
        "SettingsService: Updated MCP Server '${updatedServer.name}'.",
      );
    } else {
      // Log an error if the server ID wasn't found (shouldn't normally happen)
      debugPrint(
        "SettingsService: Error - Tried to update non-existent server ID '${updatedServer.id}'.",
      );
    }
  }

  /// Deletes an MCP server configuration from the state and persists.
  Future<void> deleteMcpServer(String serverId) async {
    final currentList = _mcpServerListNotifier.currentList;
    final serverName = currentList
        .firstWhere(
          (s) => s.id == serverId,
          orElse: () => McpServerConfig(
            id: serverId,
            name: 'Unknown',
            command: '',
            args: '',
            transportType: TransportType.StreamableHTTP,
          ),
        )
        .name;
    // Create a new list excluding the server with the matching ID
    final newList = currentList.where((s) => s.id != serverId).toList();
    // Check if the list actually changed (i.e., the server was found and removed)
    if (newList.length < currentList.length) {
      _mcpServerListNotifier.currentList = newList;
      // Persist the updated list
      await _saveCurrentMcpListState(McpAction.delete, deleteID: serverId);
      debugPrint(
        "SettingsService: Deleted MCP Server '$serverName' ($serverId).",
      );
    } else {
      // Log an error if the server ID wasn't found
      debugPrint(
        "SettingsService: Error - Tried to delete non-existent server ID '$serverId'.",
      );
    }
  }

  /// Toggles the `isActive` flag for a specific MCP server in the state and persists.
  /// This change will be picked up by the `McpClientNotifier` to initiate connection/disconnection.
  Future<void> toggleMcpServerActive(String serverId, bool isActive) async {
    final currentList = _mcpServerListNotifier.currentList;
    final index = currentList.indexWhere((s) => s.id == serverId);
    if (index != -1) {
      // Create a mutable copy, update the isActive flag, and update the state
      final newList = List<McpServerConfig>.from(currentList);
      final serverName = newList[index].name;
      newList[index] = newList[index].copyWith(
        isActive: isActive,
      ); // Use copyWith
      _mcpServerListNotifier.currentList = newList;
      // Persist the updated list
      await _saveCurrentMcpListState(McpAction.active, index: index);
      debugPrint(
        "SettingsService: Toggled server '$serverName' ($serverId) isActive to: $isActive",
      );
      // Note: McpClientNotifier will automatically react to this state change
    } else {
      debugPrint(
        "SettingsService: Error - Tried to toggle non-existent server ID '$serverId'.",
      );
    }
  }
}

class McpServerListNotifier extends StateNotifier<List<McpServerConfig>> {
  final SettingsRepository _repository;

  McpServerListNotifier(this._repository) : super([]) {
    _loadInitialList();
  }

  List<McpServerConfig> get currentList => state;
  set currentList(List<McpServerConfig> list) {
    state = list;
  }

  Future<void> _loadInitialList() async {
    final list = await _repository.getMcpServerList();
    state = list;
  }

  Future<void> refresh() async {
    final list = await _repository.getMcpServerList();
    state = list;
  }
}

/// Provider for the SharedPreferences instance.
/// Needs to be overridden in main.dart.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    "SharedPreferences instance must be provided via ProviderScope overrides in main.dart",
  );
});

/// Provider for the Settings Repository implementation.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsRepositoryImpl(prefs);
});

/// Holds the list of configured MCP servers. This is the source of truth for UI and MCP connection sync.
// final mcpServerListProvider = StateProvider<List<McpServerConfig>>((ref) => []);
final mcpServerListProvider =
    StateNotifierProvider<McpServerListNotifier, List<McpServerConfig>>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return McpServerListNotifier(repository);
});

/// Provider for the SettingsService instance.
final settingsServiceProvider = Provider<SettingsService>((ref) {
  // Get dependencies from other providers
  final repository = ref.watch(settingsRepositoryProvider);
  final mcpServerListNotifier = ref.watch(mcpServerListProvider.notifier);

  // Create service with injected dependencies
  return SettingsService(
    repository: repository,
    mcpServerListNotifier: mcpServerListNotifier,
  );
});
