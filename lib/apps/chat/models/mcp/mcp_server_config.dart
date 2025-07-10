import 'package:collection/collection.dart';

import 'package:flutter/material.dart';

enum TransportType { STDIO, StreamableHTTP }

/// Configuration for a single MCP server.
class McpServerConfig {
  final String id; // Unique ID
  final String name;
  final TransportType transportType;
  final String? command;
  final String args;
  bool isActive; // User's desired state (connect on apply)
  final Map<String, String> customEnvironment;
  final String? description;
  final int? owner_id;
  final String? owner_name;
  final bool? is_public;

  McpServerConfig({
    required this.id,
    required this.name,
    required this.transportType,
    this.command,
    required this.args,
    this.isActive = false,
    this.customEnvironment = const {},
    this.description,
    this.owner_id,
    this.owner_name,
    this.is_public,
  });

  McpServerConfig copyWith({
    String? id,
    String? name,
    TransportType? transportType,
    String? description,
    String? command,
    String? args,
    bool? isActive,
    bool? is_public,
    Map<String, String>? customEnvironment,
  }) {
    return McpServerConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      transportType: transportType ?? this.transportType,
      command: command ?? this.command,
      args: args ?? this.args,
      isActive: isActive ?? this.isActive,
      customEnvironment: customEnvironment ?? this.customEnvironment,
      description: description ?? this.description,
      owner_id: owner_id ?? this.owner_id,
      owner_name: owner_name ?? this.owner_name,
      is_public: is_public ?? this.is_public,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'command': command,
        'transport_type': transportType.name,
        'args': args,
        'isActive': isActive,
        'custom_environment': customEnvironment,
        'description': description,
        'owner_id': owner_id,
        'owner_name': owner_name,
        'is_public': is_public,
      };

  factory McpServerConfig.fromJson(Map<String, dynamic> json) {
    Map<String, String> environment = {};
    if (json['custom_environment'] is Map) {
      try {
        environment = Map<String, String>.from(
          (json['custom_environment'] as Map).map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ),
        );
      } catch (e) {
        debugPrint(
          "Error parsing customEnvironment for server ${json['id']}: $e",
        );
      }
    }

    return McpServerConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      transportType: TransportType.values.firstWhere(
        (e) => e.name == json['transport_type'],
        orElse: () => TransportType.StreamableHTTP,
      ),
      command: json['command'] as String,
      args: json['args'] as String,
      isActive: json['isActive'] as bool? ?? false,
      customEnvironment: environment,
      description: json['description'] as String?,
      owner_id: json['owner_id'] as int?,
      owner_name: json['owner_name'] as String?,
      is_public: json['is_public'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is McpServerConfig &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          transportType == other.transportType &&
          command == other.command &&
          args == other.args &&
          isActive == other.isActive &&
          description == other.description &&
          owner_id == other.owner_id &&
          owner_name == other.owner_name &&
          is_public == other.is_public &&
          const MapEquality().equals(
            customEnvironment,
            other.customEnvironment,
          );

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      transportType.hashCode ^
      command.hashCode ^
      args.hashCode ^
      isActive.hashCode ^
      const MapEquality().hash(customEnvironment);
}
