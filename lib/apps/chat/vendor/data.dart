class GPTModel {
  static const String gptv35 = "gpt-3.5-turbo-1106";
  static const String gptv40 = "gpt-4-turbo";
  static const String gptv4o = "gpt-4o";
  static const String gptv4omini = "gpt-4o-mini";
  // static const String gptv40Vision = "gpt-4-vision-preview";
  static const String gptvo1 = "o1";
  static const String gptvo1mini = "o1-mini";
  static const String gptvo3mini = "o3-mini";
  static const String gptv40Dall = "dall-e-3";

  static const List<String> all = [
    gptv35,
    gptv40,
    gptv4o,
    gptv4omini,
    gptvo1,
    gptvo1mini,
    gptvo3mini,
    //gptv40Dall,
  ];
  Map<String, String> toJson() {
    return {
      gptv35: '3.5',
      gptv40: '4.0',
      gptv4o: '4o',
      gptv4omini: '4m',
      gptvo1: "o1",
      gptvo1mini: "o1m",
      gptvo3mini: "o3m",
    };
  }
}

class ClaudeModel {
  static const String haiku = "claude-3-haiku-20240307";
  static const String sonnet = "claude-3-sonnet-20240229";
  static const String opus = "claude-3-opus-20240229";
  static const String sonnet_35 = "claude-3-5-sonnet-20241022";
  static const String haiku_35 = "claude-3-5-haiku-20241022";
  static const String sonnet_37 = "claude-3-7-sonnet-20250219";

  static const List<String> all = [
    haiku,
    sonnet,
    opus,
    sonnet_35,
    haiku_35,
    sonnet_37,
  ];
  Map<String, String> toJson() {
    return {
      haiku: 'haiku',
      sonnet: 'sonnet',
      opus: 'opus',
      sonnet_35: "sonnet_35",
      haiku_35: 'haiku_35',
      sonnet_37: "sonnet_37"
    };
  }
}

class DeepSeekModel {
  static const String dc = "deepseek-chat";
  static const String dc_r = "deepseek-reasoner";

  static const List<String> all = [dc, dc_r];

  Map<String, String> toJson() {
    return {
      dc: 'v3',
      dc_r: 'r1',
    };
  }
}

class GeminiModel {
  static const String flash_20 = "gemini-2.0-flash-001";
  static const String pro_15 = "gemini-1.5-pro";

  static const List<String> all = [flash_20, pro_15];

  Map<String, String> toJson() {
    return {
      flash_20: '2.0',
      pro_15: '1.5',
    };
  }
}

const DefaultModelVersion = GPTModel.gptv4omini;
const DefaultClaudeModel = ClaudeModel.sonnet_37;
const DefaultDeepSeekModel = DeepSeekModel.dc_r;
const DefaultGeminiModel = GeminiModel.flash_20;
const ModelForTitleGen = GeminiModel.flash_20;
List<String> textmodels = [
  ...GPTModel.all,
  ...ClaudeModel.all,
  ...DeepSeekModel.all,
  ...GeminiModel.all,
];
Map<String, String> allModels = {
  ...GPTModel().toJson(),
  ...ClaudeModel().toJson(),
  ...DeepSeekModel().toJson(),
  ...GeminiModel().toJson(),
  "dall-e-3": "D·E"
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
