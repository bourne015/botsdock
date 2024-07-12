import 'package:flutter/material.dart';

const String appTitle = 'Chat Bot';

class AppColors {
  static const appBarText = Colors.black;
  static final appBarBackground = Colors.grey[50];
  static final initPageBackgroundText = Colors.grey[350];
  static const theme = Colors.blueGrey;
  static const chatPageTitle = Colors.white;
  static const chatPageTitleToken = Colors.white;
  static final modelSelectorBackground = Colors.grey[200];
  static const modelSelected = Colors.white;
  static const subTitle = Colors.grey;

  static final drawerBackground = Colors.grey[100];
  static final drawerTabSelected = Colors.grey[350];
  static final drawerDivider = Colors.grey[350];

  static final chatPageBackground = Colors.grey[50];
  static final inputBoxBackground = Colors.grey[200];
  static final inputTextField = Colors.blue[50];
  static final userMsgBox = chatPageBackground;
  static final aiMsgBox = chatPageBackground;
  static const msgText = Color.fromARGB(255, 60, 58, 58);

  static const generatingAnimation = Colors.grey;

  static const msgCodeTitleBG = Color.fromARGB(255, 75, 74, 74);
  static const msgCodeTitle = Colors.white;
  static const msgCodeBG = Color.fromARGB(255, 34, 34, 34);
}

class AppSize {
  static const double generatingAnimation = 30.0;
}

class MessageRole {
  static const String system = "system";
  static const String user = "user";
  static const String assistant = "assistant";
}

class GPTModel {
  static const String gptv35 = "gpt-3.5-turbo-1106";
  static const String gptv40 = "gpt-4-turbo";
  static const String gptv4o = "gpt-4o";
  static const String gptv40Vision = "gpt-4-vision-preview";
  static const String gptv40Dall = "dall-e-3";
}

class ClaudeModel {
  static const String haiku = "claude-3-haiku-20240307";
  static const String sonnet = "claude-3-sonnet-20240229";
  static const String opus = "claude-3-opus-20240229";
  static const String sonnet_35 = "claude-3-5-sonnet-20240620";
}

const DefaultModelVersion = GPTModel.gptv4o;
const DefaultClaudeModel = ClaudeModel.sonnet_35;

enum MsgType { text, image, file }

const supportedImages = [
  'png',
  'jpg',
  'jpeg',
  'gif',
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

const supportedFilesAll = [
  ...supportedImages,
  ...supportedFiles,
];

const double drawerWidth = 260;

const String sseChatUrl = "http://127.0.0.1:8001/v1/stream/chat";
const String chatUrl = "http://127.0.0.1:8001/v1/chat";
const String imageUrl = "http://127.0.0.1:8001/v1/image";
const String userUrl = "http://127.0.0.1:8001/v1/user";

const String aboutText = """
基于GPT API和Cloude API封装.
任何问题或建议请联系: phantasy018@gmail.com
""";

const String function_sample1 = """
{
  "name": "get_weather",
  "description": "Determine weather in my location",
  "parameters": {
    "type": "object",
    "properties": {
      "location": {
        "type": "string",
        "description": "The city and state e.g. San Francisco, CA"
      },
      "unit": {
        "type": "string",
        "enum": ["c", "f"]
      }
    },
    "required": [
      "location"
    ]
  }
}
""";

List<String> BotImages = [
  'assets/images/bot/bot1.png',
  'assets/images/bot/bot2.png',
  'assets/images/bot/bot3.png',
  'assets/images/bot/bot4.png',
  'assets/images/bot/bot5.png',
  'assets/images/bot/bot6.png',
  'assets/images/bot/bot7.png',
  'assets/images/bot/bot8.png',
  'assets/images/bot/bot9.png',
  'assets/images/bot/bot10.png',
  'assets/images/bot/bot11.png',
  'assets/images/bot/bot12.png',
];

const String chatAssistantID = "asst_jyeohJN5sfUlrqdMm8pwGN2a";

const String appVersion = "0.4.7";
