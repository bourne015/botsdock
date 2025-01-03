class GPTModel {
  static const String gptv35 = "gpt-3.5-turbo-1106";
  static const String gptv40 = "gpt-4-turbo";
  static const String gptv4o = "gpt-4o";
  static const String gptv4omini = "gpt-4o-mini";
  // static const String gptv40Vision = "gpt-4-vision-preview";
  static const String gptv40Dall = "dall-e-3";

  Map<String, String> toJson() {
    return {
      gptv35: '3.5',
      gptv40: '4.0',
      gptv4o: '4o',
      gptv4omini: '4m',
    };
  }
}

class ClaudeModel {
  static const String haiku = "claude-3-haiku-20240307";
  static const String sonnet = "claude-3-sonnet-20240229";
  static const String opus = "claude-3-opus-20240229";
  static const String sonnet_35 = "claude-3-5-sonnet-20241022";
  static const String haiku_35 = "claude-3-5-haiku-20241022";

  Map<String, String> toJson() {
    return {
      haiku: 'haiku',
      sonnet: 'sonnet',
      opus: 'opus',
      sonnet_35: "sonnet_35",
      haiku_35: 'haiku_35',
    };
  }
}

class DeepSeekModel {
  static const String dc = "deepseek-chat";

  Map<String, String> toJson() {
    return {
      dc: 'v3',
    };
  }
}

const DefaultModelVersion = GPTModel.gptv4omini;
const DefaultClaudeModel = ClaudeModel.sonnet_35;
const DefaultDeepSeekModel = DeepSeekModel.dc;
const ModelForTitleGen = GPTModel.gptv4omini;
List<String> textmodels = [
  ...GPTModel().toJson().keys.toList(),
  ...ClaudeModel().toJson().keys.toList(),
  ...DeepSeekModel().toJson().keys.toList(),
];
Map<String, String> allModels = {
  ...GPTModel().toJson(),
  ...ClaudeModel().toJson(),
  ...DeepSeekModel().toJson(),
  "dall-e-3": "D·E"
};

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