import 'package:flutter/material.dart';

enum Organization {
  openai,
  anthropic,
  deepseek,
  google,
}

class OrgInfo {
  final String name;
  final String logo;
  final Color? color;

  const OrgInfo(this.name, this.logo, this.color);
}

OrgInfo getOrgInfo(Organization org) {
  switch (org) {
    case Organization.openai:
      return OrgInfo('openai', 'assets/images/openai.png', Colors.teal);
    case Organization.anthropic:
      return OrgInfo(
          'anthropic', 'assets/images/anthropic.png', Colors.amber[800]);
    case Organization.google:
      return OrgInfo('google', 'assets/images/google.png', null);
    case Organization.deepseek:
      return OrgInfo('deepseek', 'assets/images/deepseek.png', Colors.blue);
  }
}

class AIModel {
  final String id; //model name
  final String name; //display name
  final String abbrev;
  final Organization organization;
  // final bool isDefault; //default model in its org
  final bool visibleInUI;
  final String modelType; //modalities
  final double score; // Global average data from https://livebench.ai/
  final Map<String, double> price;

  const AIModel({
    required this.id,
    required this.name,
    required this.abbrev,
    required this.organization,
    // this.isDefault = false,
    this.visibleInUI = true,
    this.modelType = "多模态",
    this.score = 0,
    this.price = const {"input": 0, "output": 0},
  });
}

class Models {
  // OpenAI models
  static const AIModel gpt35 = AIModel(
    id: "gpt-3.5-turbo-1106",
    name: "GPT 3.5",
    abbrev: "3.5",
    organization: Organization.openai,
    visibleInUI: false,
    price: {"input": 0.50, "output": 1.50},
    modelType: "仅文本",
  );
  static const AIModel gpt40 = AIModel(
    id: "gpt-4-turbo",
    name: "GPT 4.0 turbo",
    abbrev: "4.0",
    organization: Organization.openai,
    visibleInUI: false,
    price: {"input": 10.0, "output": 30.0},
  );
  static const AIModel gpt41 = AIModel(
    id: "gpt-4.1",
    name: "GPT 4.1",
    abbrev: "4.1",
    organization: Organization.openai,
    price: {"input": 2.00, "output": 8.00},
    score: 58.41,
  );
  static const AIModel gpt41Mini = AIModel(
    id: "gpt-4.1-mini",
    name: "GPT 4.1 mini",
    abbrev: "41m",
    organization: Organization.openai,
    // isDefault: true,
    price: {"input": 0.4, "output": 1.6},
    score: 55.55,
  );
  static const AIModel gpt4o = AIModel(
    id: "gpt-4o",
    name: "GPT 4o",
    abbrev: "4o",
    organization: Organization.openai,
    price: {"input": 2.5, "output": 10.0},
    score: 49.21,
  );
  static const AIModel gpt4oMini = AIModel(
    id: "gpt-4o-mini",
    name: "GPT 4o mini",
    abbrev: "4m",
    organization: Organization.openai,
    price: {"input": 0.15, "output": 0.60},
    score: 37.63,
  );
  static const AIModel o1 = AIModel(
    id: "o1",
    name: "o1",
    abbrev: "o1",
    organization: Organization.openai,
    visibleInUI: false,
    price: {"input": 15.0, "output": 60.0},
    score: 72.18,
  );
  static const AIModel o1Mini = AIModel(
    id: "o1-mini",
    name: "o1 mini",
    abbrev: "o1m",
    organization: Organization.openai,
    visibleInUI: false,
    modelType: "仅文本",
    price: {"input": 1.10, "output": 4.40},
    score: 53.43,
  );
  static const AIModel o3Mini = AIModel(
    id: "o3-mini",
    name: "o3 mini",
    abbrev: "o3m",
    organization: Organization.openai,
    modelType: "仅文本",
    price: {"input": 1.10, "output": 4.40},
    score: 71.37,
  );
  static const AIModel o4Mini = AIModel(
    id: "o4-mini",
    name: "o4 mini",
    abbrev: "o4m",
    organization: Organization.openai,
    price: {"input": 1.10, "output": 4.40},
    score: 78.13,
  );
  static const AIModel dalle3 = AIModel(
    id: "dall-e-3",
    name: "DALL·E 3",
    abbrev: "D·E",
    organization: Organization.openai,
    price: {"input": 0, "output": 0.04},
    modelType: "文生图",
  );

  // Anthropic models
  static const AIModel claudeHaiku = AIModel(
    id: "claude-3-haiku-20240307",
    name: "Claude3 - haiku",
    abbrev: "h",
    organization: Organization.anthropic,
    visibleInUI: false,
  );
  static const AIModel claudeSonnet = AIModel(
    id: "claude-3-sonnet-20240229",
    name: "Claude3 - sonnet",
    abbrev: "s",
    organization: Organization.anthropic,
    visibleInUI: false,
  );
  static const AIModel claudeOpus = AIModel(
    id: "claude-3-opus-20240229",
    name: "Claude3 - opus",
    abbrev: "o",
    organization: Organization.anthropic,
    visibleInUI: false,
  );
  static const AIModel claudeSonnet35 = AIModel(
    id: "claude-3-5-sonnet-20241022",
    name: "Claude3.5 - sonnet",
    abbrev: "s",
    organization: Organization.anthropic,
    price: {"input": 3.0, "output": 15.0},
    score: 50.81,
  );
  static const AIModel claudeHaiku35 = AIModel(
    id: "claude-3-5-haiku-20241022",
    name: "Claude3.5 - haiku",
    abbrev: "h",
    organization: Organization.anthropic,
    price: {"input": 0.8, "output": 4.0},
    score: 38.49,
  );
  static const AIModel claudeSonnet37 = AIModel(
    id: "claude-3-7-sonnet-20250219",
    name: "Claude3.7 - sonnet",
    abbrev: "s",
    organization: Organization.anthropic,
    // isDefault: true,
    price: {"input": 3.0, "output": 15.0},
    score: 70.57,
  );

  // DeepSeek models
  static const AIModel deepseekChat = AIModel(
    id: "deepseek-chat",
    name: "DeepSeek V3",
    abbrev: "v3",
    organization: Organization.deepseek,
    price: {"input": 0.27, "output": 1.10},
    score: 57.48,
  );
  static const AIModel deepseekReasoner = AIModel(
    id: "deepseek-reasoner",
    name: "DeepSeek R1",
    abbrev: "r1",
    organization: Organization.deepseek,
    // isDefault: true,
    price: {"input": 0.55, "output": 2.19},
    score: 67.47,
  );

  // Google models
  static const AIModel geminiPro15 = AIModel(
    id: "gemini-1.5-pro",
    name: "Gemini 1.5 Pro",
    abbrev: "15p",
    organization: Organization.google,
    score: 47.77,
  );
  static const AIModel geminiFlash20Lite = AIModel(
    id: "gemini-2.0-flash-lite",
    name: "Gemini 2.0 Flash lite",
    abbrev: "20fl",
    organization: Organization.google,
    visibleInUI: false,
  );
  static const AIModel geminiFlash20 = AIModel(
    id: "gemini-2.0-flash",
    name: "Gemini 2.0 Flash",
    abbrev: "20f",
    organization: Organization.google,
    score: 54.89,
  );
  static const AIModel geminiPro25 = AIModel(
    id: "gemini-2.5-pro-exp-03-25",
    name: "Gemini 2.5 Pro",
    abbrev: "25p",
    organization: Organization.google,
    // isDefault: true,
    score: 77.43,
  );

  // All models list
  static const List<AIModel> all = [
    // OpenAI
    gpt35, gpt40,
    o4Mini, gpt41, gpt41Mini, gpt4o, gpt4oMini, o1, o1Mini, o3Mini,
    dalle3,
    // Claude
    claudeHaiku, claudeSonnet, claudeOpus, claudeSonnet35, claudeHaiku35,
    claudeSonnet37,
    // DeepSeek
    deepseekChat, deepseekReasoner,
    // Gemini
    geminiPro15, geminiFlash20Lite, geminiFlash20, geminiPro25
  ];

  //get default model of an organization
  // static AIModel getDefaultModel(Organization org) {
  //   return all.firstWhere(
  //       (m) => m.visibleInUI && m.organization == org && m.isDefault,
  //       orElse: () =>
  //           all.firstWhere((m) => m.visibleInUI && m.organization == org));
  // }

  //get all models of an organization
  static List<AIModel> getOrganizationModels(Organization organization) {
    return all
        .where(
            (model) => model.organization == organization && model.visibleInUI)
        .toList();
  }

  static Map<String, String> getNameMap() {
    return {for (var model in all) model.id: model.name};
  }

  static List<String> getTextModelIds() {
    return all
        .where((model) => model.visibleInUI)
        .map((model) => model.id)
        .toList();
  }

  static Organization? getOrgByModelId(String modelId) {
    for (var model in all) {
      if (model.id == modelId) return model.organization;
    }
    return null;
  }

  static AIModel? getModelById(String modelId) {
    for (var model in all) {
      if (model.id == modelId) return model;
    }
    return null;
  }

  static bool checkORG(String modelId, Organization org) {
    return all.any((m) => m.id == modelId && m.organization == org);
  }
}

AIModel DefaultModelVersion = Models.gpt41Mini;
final ModelForTitleGen = Models.geminiFlash20Lite;
Map<Organization, AIModel> currentModels = {
  Organization.openai: DefaultModelVersion,
  Organization.anthropic: Models.claudeSonnet37,
  Organization.google: Models.geminiPro25,
  Organization.deepseek: Models.deepseekReasoner,
};

const claudeSupportedFiles = ['pdf'];
const geminiSupportedFiles = [
  "pdf",
  "js",
  "py",
  "txt",
  "html",
  "css",
  "md",
  "csv",
  "xml",
  "rtf",
];

const supportedImages = [
  'png',
  'jpg',
  'jpeg',
  'gif',
  'webp',
];

const supportedFiles = [
  'c',
  'cs',
  'cpp',
  'doc',
  'docx',
  'html',
  'java',
  'json',
  'md',
  'pdf',
  'php',
  'pptx',
  'py',
  'rb',
  'tex',
  'txt',
  'css',
  'js',
  'sh'
];
const supportedFiles_cp = [
  'c',
  'cs',
  'cpp',
  'doc',
  'docx',
  'html',
  'java',
  'json',
  'md',
  'pdf',
  'php',
  'pptx',
  'py',
  'rb',
  'tex',
  'txt',
  'css',
  'js',
  'sh',
  'ts',
  'csv',
  'tar',
  'xlsx',
  'xml',
  'zip'
];

const supportedFilesAll = [
  ...supportedImages,
  ...supportedFiles,
  ...supportedFiles_cp
];
