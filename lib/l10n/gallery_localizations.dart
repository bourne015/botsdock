import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'gallery_localizations_en.dart' deferred as gallery_localizations_en;
import 'gallery_localizations_zh.dart' deferred as gallery_localizations_zh;

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of GalleryLocalizations
/// returned by `GalleryLocalizations.of(context)`.
///
/// Applications need to include `GalleryLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/gallery_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: GalleryLocalizations.localizationsDelegates,
///   supportedLocales: GalleryLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the GalleryLocalizations.supportedLocales
/// property.
abstract class GalleryLocalizations {
  GalleryLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static GalleryLocalizations? of(BuildContext context) {
    return Localizations.of<GalleryLocalizations>(context, GalleryLocalizations);
  }

  static const LocalizationsDelegate<GalleryLocalizations> delegate = _GalleryLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// app title
  ///
  /// In en, this message translates to:
  /// **'AI ASSISTANT'**
  String get appTitle;

  /// Header title on home screen for Gallery section.
  ///
  /// In en, this message translates to:
  /// **'Assistants'**
  String get homeHeaderGallery;

  /// Study description for Chat.
  ///
  /// In en, this message translates to:
  /// **'Base on GPT, Claude, Gemini, DeepSeek'**
  String get chatDescription;

  /// test
  ///
  /// In en, this message translates to:
  /// **'To the time to life'**
  String get settingsAttribution;

  /// new chat
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get newChat;

  /// Represents a link to a GitHub repository.
  ///
  /// In en, this message translates to:
  /// **'{repoName} GitHub repository'**
  String githubRepo(Object repoName);

  /// A description about how to view the source code for this app.
  ///
  /// In en, this message translates to:
  /// **'To see the source code for this app, please visit the {repoLink}.'**
  String aboutDialogDescription(Object repoLink);

  /// chatGPT35Desc
  ///
  /// In en, this message translates to:
  /// **'fast, inexpensive model for simple tasks'**
  String get chatGPT35Desc;

  /// chatGPT40Desc
  ///
  /// In en, this message translates to:
  /// **'solve difficult problems with greater accuracy'**
  String get chatGPT40Desc;

  /// chatGPT4oDesc
  ///
  /// In en, this message translates to:
  /// **'Versatile, high-intelligence flagship model'**
  String get chatGPT4oDesc;

  /// chatGPTo1Desc
  ///
  /// In en, this message translates to:
  /// **'Designed to solve hard problems across domains'**
  String get chatGPTo1Desc;

  /// chatGPTo3mDesc
  ///
  /// In en, this message translates to:
  /// **'Designed to excel at science, math, and coding tasks.'**
  String get chatGPTo3mDesc;

  /// chatGPT4oMiniDesc
  ///
  /// In en, this message translates to:
  /// **'affordable and intelligent small model for fast, lightweight tasks'**
  String get chatGPT4oMiniDesc;

  /// dallEDesc
  ///
  /// In en, this message translates to:
  /// **'A model that can generate images given a natural language prompt'**
  String get dallEDesc;

  /// claude3HaikuDesc
  ///
  /// In en, this message translates to:
  /// **'Fastest and most compact model for near-instant responsiveness'**
  String get claude3HaikuDesc;

  /// claude3SonnetDesc
  ///
  /// In en, this message translates to:
  /// **'Balance of intelligence and speed'**
  String get claude3SonnetDesc;

  /// claude3OpusDesc
  ///
  /// In en, this message translates to:
  /// **'Powerful model for complex tasks'**
  String get claude3OpusDesc;

  /// claude35SonnetDesc
  ///
  /// In en, this message translates to:
  /// **'previous most intelligent claude model'**
  String get claude35SonnetDesc;

  /// claude37SonnetDesc
  ///
  /// In en, this message translates to:
  /// **'Most intelligent claude model'**
  String get claude37SonnetDesc;

  /// geminiDesc
  ///
  /// In en, this message translates to:
  /// **'New generation features, speed, and multimodal generation, suitable for a variety of tasks'**
  String get geminiDesc;

  /// gemini15proDesc
  ///
  /// In en, this message translates to:
  /// **'Complex reasoning tasks that require higher intelligence'**
  String get gemini15proDesc;

  /// deepseek chat
  ///
  /// In en, this message translates to:
  /// **'Open source model from China, deepseek chat v3'**
  String get deepseekDesc;

  /// deepseek reasoner
  ///
  /// In en, this message translates to:
  /// **'deepseek reasoner r1'**
  String get deepseekR1Desc;

  /// botsCentre
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get botsCentre;

  /// Login
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// custmizeGPT
  ///
  /// In en, this message translates to:
  /// **'custmize GPT'**
  String get custmizeGPT;

  /// Model setting
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get setting;

  /// About
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Logout
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// adminstrator
  ///
  /// In en, this message translates to:
  /// **'Adminstrator'**
  String get adminstrator;

  /// Model Description
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get modelDescription;

  /// Model Context window
  ///
  /// In en, this message translates to:
  /// **'Context window'**
  String get contextWindow;

  /// Model price
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// Model input format
  ///
  /// In en, this message translates to:
  /// **'Input Format'**
  String get inputFormat;

  /// Text input format
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get inputFormat1;

  /// Image format
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get inputFormat2;

  /// select model tooltip
  ///
  /// In en, this message translates to:
  /// **'select model'**
  String get selectModelTooltip;

  /// close sidebar tooltip
  ///
  /// In en, this message translates to:
  /// **'open sidebar'**
  String get openDrawerTooltip;

  /// open sidebar tooltip
  ///
  /// In en, this message translates to:
  /// **'close sidebar'**
  String get closeDrawerTooltip;

  /// bot centre title
  ///
  /// In en, this message translates to:
  /// **'Bot Centre'**
  String get botCentreTitle;

  /// bot centre me
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get botCentreMe;

  /// create bot
  ///
  /// In en, this message translates to:
  /// **'create'**
  String get botCentreCreate;

  /// bot centre explore more
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get exploreMore;

  /// botEdit
  ///
  /// In en, this message translates to:
  /// **'edit'**
  String get botEdit;

  /// delete
  ///
  /// In en, this message translates to:
  /// **'delete'**
  String get botDelete;

  /// bot Create Title
  ///
  /// In en, this message translates to:
  /// **'customize bot'**
  String get botCreateTitle;

  /// tools
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// file Search
  ///
  /// In en, this message translates to:
  /// **'File search'**
  String get fileSearch;

  /// file Search dialog title
  ///
  /// In en, this message translates to:
  /// **'Attach files to file search'**
  String get fileSearchTitle;

  /// code interpreter dialog title
  ///
  /// In en, this message translates to:
  /// **'Attach files to code interpreter'**
  String get codeInterpreterTitle;

  /// code interpreter
  ///
  /// In en, this message translates to:
  /// **'Code interpreter'**
  String get codeInterpreter;

  /// Functions
  ///
  /// In en, this message translates to:
  /// **'Functions'**
  String get functions;

  /// fileSearch tooltip
  ///
  /// In en, this message translates to:
  /// **'File search enables the assistant with knowledge from files that you or your users upload.\nOnce a file is uploaded, the assistant automatically decides when to retrieve content based on user requests.'**
  String get fileSearchTip;

  /// codeInterpreter tooltip
  ///
  /// In en, this message translates to:
  /// **'Code Interpreter enables the assistant to write and run code.\nThis tool can process files with diverse data and formatting, and generate files such as graphs.'**
  String get codeInterpreterTip;

  /// functionsTip tooltip
  ///
  /// In en, this message translates to:
  /// **'Function calling lets you describe custom functions of your app or external APIs to the assistant.\nThis allows the assistant to intelligently call those functions by outputting a JSON object containing relevant arguments.'**
  String get functionsTip;

  /// functions Dialog title
  ///
  /// In en, this message translates to:
  /// **'Add function'**
  String get functionsDialog;

  /// functions Dialog tip
  ///
  /// In en, this message translates to:
  /// **'The model will intelligently decide to call functions based on the input it receives from the user.'**
  String get functionsDialogTip;

  /// save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;
}

class _GalleryLocalizationsDelegate extends LocalizationsDelegate<GalleryLocalizations> {
  const _GalleryLocalizationsDelegate();

  @override
  Future<GalleryLocalizations> load(Locale locale) {
    return lookupGalleryLocalizations(locale);
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_GalleryLocalizationsDelegate old) => false;
}

Future<GalleryLocalizations> lookupGalleryLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return gallery_localizations_en.loadLibrary().then((dynamic _) => gallery_localizations_en.GalleryLocalizationsEn());
    case 'zh': return gallery_localizations_zh.loadLibrary().then((dynamic _) => gallery_localizations_zh.GalleryLocalizationsZh());
  }

  throw FlutterError(
    'GalleryLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
