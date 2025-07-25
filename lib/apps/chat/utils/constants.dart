import 'package:flutter/material.dart';

const String appTitle = 'Chat Bot';

class AppColors {
  static const Color gray = Color(0xFFD8D8D8);
  static const Color gray60 = Color(0x99D8D8D8);
  static const Color gray25 = Color(0x40D8D8D8);
  static const Color white60 = Color(0x99FFFFFF);
  static const Color primaryBackground = Color(0xFF33333D);
  static const Color inputBackground = Color(0x08FFFFFF);
  static const Color cardBackground = Color(0x03FEFEFE);
  static const Color buttonColor = Color(0xFF09AF79);
  static const Color focusColor = Color(0xCCFFFFFF);

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
  static final divider = Colors.grey[350];

  static final chatPageBackground = Colors.grey[50];
  static final inputBoxBackground = Colors.grey[200];
  static final inputTextField = Colors.blue[50];
  static final userMsgBox = Colors.grey[300]; //chatPageBackground;
  static final aiMsgBox = chatPageBackground;
  static final thinkingMsgBox = Colors.grey[200];
  static const msgText = Color.fromARGB(255, 60, 58, 58);

  static const generatingAnimation = Colors.grey;

  static const msgCodeTitleBG = Color.fromARGB(255, 75, 74, 74);
  static const msgCodeTitle = Colors.white;
  static const msgCodeBG = Color.fromARGB(255, 34, 34, 34);
}

class AppSize {
  static const double generatingAnimation = 30.0;
}

class MessageTRole {
  static const String system = "system";
  static const String user = "user";
  static const String assistant = "assistant";
  static const String tool = "tool";
  static const String model = "model";
}

enum MsgType { text, image, file }

const double DRAWERWIDTH = 260;

const String BASE_URL = "https://botsdock.com:8443";
const String SSE_CHAT_URL = "${BASE_URL}/v1/stream/chats";
const String CHAT_URL = "${BASE_URL}/v1/chat";
const String IMAGE_URL = "${BASE_URL}/v1/image";
const String USER_URL = "${BASE_URL}/v1/user";
const String BOT_URL = "${BASE_URL}/v1/bot";
String? ACCESS_TOKEN;

const String aboutText = """
基于GPT API和Cloude API封装.
Contact: phantasy018@gmail.com
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

List<String> avatarImages = [
  'assets/images/avatar/1.png',
  'assets/images/avatar/2.png',
  'assets/images/avatar/3.png',
  'assets/images/avatar/4.png',
  'assets/images/avatar/5.png',
  'assets/images/avatar/6.png',
  'assets/images/avatar/7.png',
  'assets/images/avatar/8.png',
  'assets/images/avatar/9.png',
  'assets/images/avatar/10.png',
  'assets/images/avatar/11.png',
  'assets/images/avatar/12.png',
  'assets/images/avatar/13.png',
  'assets/images/avatar/14.png',
  'assets/images/avatar/15.png',
];

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
  'assets/images/bot/bot13.png',
  'assets/images/bot/bot14.png',
  'assets/images/bot/bot15.png',
  'assets/images/bot/bot16.png',
];

String defaultBotAvatar = BotImages[3];
String defaultUserBotAvatar = BotImages[6];

const String chatAssistantID = "asst_jyeohJN5sfUlrqdMm8pwGN2a";
const int maxFileMBSize = 200;
const int maxAvatarSize = 10;

BorderRadius BORDERRADIUS10 = BorderRadius.circular(10.0);
BorderRadius BORDERRADIUS15 = BorderRadius.circular(15.0);

const double Artifact_MAX_W = 816;
const double Artifact_MAX_H = 612;
const double Artifact_MIN_W = 400;
const double Artifact_MIN_H = 300;

const double resultIcon_W = 80;
const double resultIconExpand_W = 200;
const double resultIcon_H = 50;

const double resultCard_W = 180;
const double resultCard_MIN_H = 70;
const double resultCard_H = 120;
