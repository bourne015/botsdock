// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'gallery_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class GalleryLocalizationsEn extends GalleryLocalizations {
  GalleryLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AI ASSISTANT';

  @override
  String get homeHeaderGallery => 'Assistants';

  @override
  String get chatDescription => 'Base on GPT, Claude, Gemini, DeepSeek';

  @override
  String get settingsAttribution => 'To the time to life';

  @override
  String get newChat => 'New Chat';

  @override
  String githubRepo(Object repoName) {
    return '$repoName GitHub repository';
  }

  @override
  String aboutDialogDescription(Object repoLink) {
    return 'To see the source code for this app, please visit the $repoLink.';
  }

  @override
  String get chatGPT35Desc => 'fast, inexpensive model for simple tasks';

  @override
  String get chatGPT40Desc => 'solve difficult problems with greater accuracy';

  @override
  String get chatGPT4oDesc => 'Versatile, high-intelligence flagship model';

  @override
  String get chatGPTo1Desc => 'Designed to solve hard problems across domains';

  @override
  String get chatGPTo3mDesc => 'Designed to excel at science, math, and coding tasks.';

  @override
  String get chatGPT4oMiniDesc => 'affordable and intelligent small model for fast, lightweight tasks';

  @override
  String get dallEDesc => 'A model that can generate images given a natural language prompt';

  @override
  String get claude3HaikuDesc => 'Fastest and most compact model for near-instant responsiveness';

  @override
  String get claude3SonnetDesc => 'Balance of intelligence and speed';

  @override
  String get claude3OpusDesc => 'Powerful model for complex tasks';

  @override
  String get claude35SonnetDesc => 'previous most intelligent claude model';

  @override
  String get claude37SonnetDesc => 'Most intelligent claude model';

  @override
  String get geminiDesc => 'New generation features, speed, and multimodal generation, suitable for a variety of tasks';

  @override
  String get gemini15proDesc => 'Complex reasoning tasks that require higher intelligence';

  @override
  String get deepseekDesc => 'Open source model from China, deepseek chat v3';

  @override
  String get deepseekR1Desc => 'deepseek reasoner r1';

  @override
  String get botsCentre => 'Explore';

  @override
  String get login => 'Login';

  @override
  String get custmizeGPT => 'custmize GPT';

  @override
  String get setting => 'Settings';

  @override
  String get about => 'About';

  @override
  String get logout => 'Logout';

  @override
  String get adminstrator => 'Adminstrator';

  @override
  String get modelDescription => 'Description';

  @override
  String get contextWindow => 'Context window';

  @override
  String get price => 'Price';

  @override
  String get inputFormat => 'Input Format';

  @override
  String get inputFormat1 => 'Text';

  @override
  String get inputFormat2 => 'Image';

  @override
  String get selectModelTooltip => 'select model';

  @override
  String get openDrawerTooltip => 'open sidebar';

  @override
  String get closeDrawerTooltip => 'close sidebar';

  @override
  String get botCentreTitle => 'Bot Centre';

  @override
  String get botCentreMe => 'Me';

  @override
  String get botCentreCreate => 'create';

  @override
  String get exploreMore => 'More';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get remove => 'Remove';

  @override
  String get botCreateTitle => 'customize bot';

  @override
  String get tools => 'Tools';

  @override
  String get fileSearch => 'File search';

  @override
  String get fileSearchTitle => 'Attach files to file search';

  @override
  String get codeInterpreterTitle => 'Attach files to code interpreter';

  @override
  String get codeInterpreter => 'Code interpreter';

  @override
  String get functions => 'Functions';

  @override
  String get fileSearchTip => 'File search enables the assistant with knowledge from files that you or your users upload.\nOnce a file is uploaded, the assistant automatically decides when to retrieve content based on user requests.';

  @override
  String get codeInterpreterTip => 'Code Interpreter enables the assistant to write and run code.\nThis tool can process files with diverse data and formatting, and generate files such as graphs.';

  @override
  String get functionsTip => 'Function calling lets you describe custom functions of your app or external APIs to the assistant.\nThis allows the assistant to intelligently call those functions by outputting a JSON object containing relevant arguments.';

  @override
  String get functionsDialog => 'Add function';

  @override
  String get functionsDialogTip => 'The model will intelligently decide to call functions based on the input it receives from the user.';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get mcpServers => 'MCP Servers';

  @override
  String get mcpNote => 'Desktop platform only';

  @override
  String get mcpAdd => 'Add New Server';

  @override
  String get mcpEdit => 'Edit Server';

  @override
  String get mcpDel => 'Delete Server';

  @override
  String get mcpName => 'Server Name';

  @override
  String get mcpDesc => 'Server Description';

  @override
  String get mcpCmd => 'Server Command';

  @override
  String get mcpArgs => 'Server Arguments';

  @override
  String get mcpConn => 'Connect Automatically';

  @override
  String get mcpConnNote => 'Applies when settings change';

  @override
  String get mcpVisibility => 'MCP Server visibility';

  @override
  String get mcpVisibilityNote => 'Is visible to other users';

  @override
  String get mcpEnv => 'Custom Environment Variables';
}
