// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'gallery_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class GalleryLocalizationsZh extends GalleryLocalizations {
  GalleryLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'AI助手';

  @override
  String get homeHeaderGallery => 'Assistants';

  @override
  String get chatDescription => 'Base on GPT, Claude, Gemini, DeepSeek';

  @override
  String get settingsAttribution => 'To Give Life To Time';

  @override
  String get newChat => '新会话';

  @override
  String githubRepo(Object repoName) {
    return '$repoName GitHub 代码库';
  }

  @override
  String aboutDialogDescription(Object repoLink) {
    return '要查看此应用的源代码，请访问 $repoLink。';
  }

  @override
  String get chatGPT35Desc => '快速且廉价的解决简易任务的模型';

  @override
  String get chatGPT40Desc => '用更高的准确度解决复杂问题';

  @override
  String get chatGPT4oDesc => '多功能、高智能的旗舰模型';

  @override
  String get chatGPTo1Desc => 'o1推理模型旨在解决跨领域的难题';

  @override
  String get chatGPTo3mDesc => '擅长科学、数学和编码任务';

  @override
  String get chatGPT4oMiniDesc => '适用于快速、轻量级的任务';

  @override
  String get dallEDesc => '根据自然语言提示生成图像的模型';

  @override
  String get claude3HaikuDesc => '最快且最紧凑的模型，近乎即时的响应';

  @override
  String get claude3SonnetDesc => '在智能与输出速度之间完美平衡';

  @override
  String get claude3OpusDesc => '应对高度复杂任务的强大模型';

  @override
  String get claude35SonnetDesc => '上一代最具智慧的Claude模型';

  @override
  String get claude37SonnetDesc => '最具智慧的Claude模型';

  @override
  String get geminiDesc => '新一代功能、速度和多模态生成，适用于各种各样的任务';

  @override
  String get gemini15proDesc => '需要更高智能的复杂推理任务';

  @override
  String get deepseekDesc => '国内开源模型: deepseek chat v3';

  @override
  String get deepseekR1Desc => '国内开源模型: deepseek reasoner r1';

  @override
  String get botsCentre => '探索GPT';

  @override
  String get login => '登录';

  @override
  String get custmizeGPT => '个性化GPT';

  @override
  String get setting => '设置';

  @override
  String get about => '关于';

  @override
  String get logout => '登出';

  @override
  String get adminstrator => '管理';

  @override
  String get modelDescription => '描述';

  @override
  String get contextWindow => '上下文窗口';

  @override
  String get price => '价格';

  @override
  String get inputFormat => '输入格式';

  @override
  String get inputFormat1 => '文本';

  @override
  String get inputFormat2 => '图像';

  @override
  String get selectModelTooltip => '选择模型';

  @override
  String get openDrawerTooltip => '展开';

  @override
  String get closeDrawerTooltip => '收起';

  @override
  String get botCentreTitle => '智能体中心';

  @override
  String get botCentreMe => '我的';

  @override
  String get botCentreCreate => '创建';

  @override
  String get exploreMore => '探索更多';

  @override
  String get add => '添加';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get remove => '移除';

  @override
  String get botCreateTitle => '个性化配置智能体';

  @override
  String get tools => '工具';

  @override
  String get fileSearch => '文件检索';

  @override
  String get fileSearchTitle => '添加文件用于文件检索';

  @override
  String get codeInterpreterTitle => '添加文件到代码解释器';

  @override
  String get codeInterpreter => '代码解释器';

  @override
  String get functions => '函数调用';

  @override
  String get fileSearchTip =>
      '文件搜索使助手能够从您上传的文件中获得知识。\n上传文件后，助理会根据用户请求自动决定何时检索内容';

  @override
  String get codeInterpreterTip =>
      '代码解释器使助手能够编写和运行代码。\n该工具可以处理具有不同数据和格式的文件，并生成图形等文件';

  @override
  String get functionsTip =>
      '函数调用允许您向助手描述应用程序或外部API的自定义函数。\n助手将通过输出包含相关参数的JSON对象来智能地调用这些函数';

  @override
  String get functionsDialog => '添加函数';

  @override
  String get functionsDialogTip => '模型将根据从用户收到的输入智能地决定调用函数';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get mcpServers => 'MCP服务';

  @override
  String get mcpNote => '仅支持桌面端平台';

  @override
  String get mcpAdd => '添加MCP';

  @override
  String get mcpEdit => '编辑MCP';

  @override
  String get mcpDel => '删除MCP';

  @override
  String get mcpName => '名字';

  @override
  String get mcpDesc => '描述';

  @override
  String get mcpCmd => '指令';

  @override
  String get mcpArgs => '参数';

  @override
  String get mcpConn => '自动连接';

  @override
  String get mcpConnNote => '当修改设置时自动应用';

  @override
  String get mcpVisibility => 'MCP服务可见性';

  @override
  String get mcpVisibilityNote => '该服务是否对其他用户可见';

  @override
  String get mcpEnv => '自定义环境变量';
}
