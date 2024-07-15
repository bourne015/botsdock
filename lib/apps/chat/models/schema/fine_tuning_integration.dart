// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: invalid_annotation_target
part of open_a_i_schema;

// ==========================================
// CLASS: FineTuningIntegration
// ==========================================

/// A fine-tuning integration to enable for a fine-tuning job.
@freezed
class FineTuningIntegration with _$FineTuningIntegration {
  const FineTuningIntegration._();

  /// Factory constructor for FineTuningIntegration
  const factory FineTuningIntegration({
    /// The type of integration to enable. Currently, only "wandb" (Weights and Biases) is supported.
    required FineTuningIntegrationType type,

    /// The settings for your integration with Weights and Biases. This payload specifies the project that
    /// metrics will be sent to. Optionally, you can set an explicit display name for your run, add tags
    /// to your run, and set a default entity (team, username, etc) to be associated with your run.
    required FineTuningIntegrationWandb wandb,
  }) = _FineTuningIntegration;

  /// Object construction from a JSON representation
  factory FineTuningIntegration.fromJson(Map<String, dynamic> json) =>
      _$FineTuningIntegrationFromJson(json);

  /// List of all property names of schema
  static const List<String> propertyNames = ['type', 'wandb'];

  /// Perform validations on the schema property values
  String? validateSchema() {
    return null;
  }

  /// Map representation of object (not serialized)
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'wandb': wandb,
    };
  }
}

// ==========================================
// ENUM: FineTuningIntegrationType
// ==========================================

/// The type of integration to enable. Currently, only "wandb" (Weights and Biases) is supported.
enum FineTuningIntegrationType {
  @JsonValue('wandb')
  wandb,
}

// ==========================================
// CLASS: FineTuningIntegrationWandb
// ==========================================

/// The settings for your integration with Weights and Biases. This payload specifies the project that
/// metrics will be sent to. Optionally, you can set an explicit display name for your run, add tags
/// to your run, and set a default entity (team, username, etc) to be associated with your run.
@freezed
class FineTuningIntegrationWandb with _$FineTuningIntegrationWandb {
  const FineTuningIntegrationWandb._();

  /// Factory constructor for FineTuningIntegrationWandb
  const factory FineTuningIntegrationWandb({
    /// The name of the project that the new run will be created under.
    required String project,

    /// A display name to set for the run. If not set, we will use the Job ID as the name.
    @JsonKey(includeIfNull: false) String? name,

    /// The entity to use for the run. This allows you to set the team or username of the WandB user that you would
    /// like associated with the run. If not set, the default entity for the registered WandB API key is used.
    @JsonKey(includeIfNull: false) String? entity,

    /// A list of tags to be attached to the newly created run. These tags are passed through directly to WandB. Some
    /// default tags are generated by OpenAI: "openai/finetune", "openai/{base-model}", "openai/{ftjob-abcdef}".
    @JsonKey(includeIfNull: false) List<String>? tags,
  }) = _FineTuningIntegrationWandb;

  /// Object construction from a JSON representation
  factory FineTuningIntegrationWandb.fromJson(Map<String, dynamic> json) =>
      _$FineTuningIntegrationWandbFromJson(json);

  /// List of all property names of schema
  static const List<String> propertyNames = [
    'project',
    'name',
    'entity',
    'tags'
  ];

  /// Perform validations on the schema property values
  String? validateSchema() {
    return null;
  }

  /// Map representation of object (not serialized)
  Map<String, dynamic> toMap() {
    return {
      'project': project,
      'name': name,
      'entity': entity,
      'tags': tags,
    };
  }
}
