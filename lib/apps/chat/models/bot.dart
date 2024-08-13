import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/global.dart';

class Bots with ChangeNotifier {
  List<Bot> _bots = [];
  List<Bot> get bots => _bots;
  List<Bot> _bots_public = [];
  List<Bot> get bots_public => _bots_public;
  final dio = Dio();

  Future<void> fetchBots(int? user_id) async {
    final responseSh = await dio.get('${BASE_URL}/v1/shares');
    if (Global.botsCheck(responseSh.data["bot_updated"])) {
      if (_bots.isEmpty) {
        debugPrint("restore from local");
        restoreBots(bots);
        if (_bots_public.isEmpty) classify(user_id: user_id);
        return;
      }
      if (_bots.isNotEmpty) {
        debugPrint("no need restore data");
        if (_bots_public.isEmpty) classify(user_id: user_id);
        return;
      }
    }
    debugPrint("need update from db");
    final response = await dio.post('${BASE_URL}/v1/bot/bots');
    if (response.statusCode == 200) {
      List<dynamic> data = response.data["bots"];
      _bots = data.map((item) => Bot.fromJson(item)).toList();
      notifyListeners();
      cacheBots(response.data["date"]);
      classify(user_id: user_id);
    } else {
      throw Exception('Failed to load bots');
    }
  }

  void sortBots() {
    _bots.sort((a, b) => a.id.compareTo(b.id));
  }

  void sortBots1() {
    _bots_public.sort((a, b) => a.id.compareTo(b.id));
  }

  void addBot(Map<String, dynamic> data) {
    _bots.add(Bot.fromJson(data));
    notifyListeners();
  }

  void updateBot(Map<String, dynamic> data, id) {
    int index = _bots.indexWhere((_bot) => _bot.id == id);
    _bots[index] = Bot.fromJson(data);
  }

  void classify({int? user_id}) {
    _bots_public.clear();
    for (Bot bot in _bots) {
      if (bot.public == null || bot.public == true) {
        _bots_public.add(bot);
      } else if (user_id != null && user_id == bot.author_id) {
        _bots_public.add(bot);
      }
    }
  }

  void deleteBot(int id) {
    _bots.removeWhere((element) => element.id == id);
    notifyListeners();
  }

  void cacheBots(update_date) {
    Global.saveBots(_bots, update_date);
  }

  void restoreBots(bots) {
    Global.restoreBots(bots);
  }
}

class Bot {
  int id;
  String name;
  String? avatar;
  String? description;

  String? assistant_id;
  String? instructions;
  int? author_id;
  String? author_name;
  String? model;
  bool? file_search;
  Map? vector_store_ids;
  bool? code_interpreter;
  Map? code_interpreter_files;
  Map<String, dynamic>? functions;
  double? temperature;

  int? likes;
  bool? public;
  int? created_at;
  int? updated_at;
  Bot({
    required this.id,
    required this.name,
    this.avatar,
    this.assistant_id,
    this.description,
    this.instructions,
    this.author_id,
    this.author_name,
    this.model,
    this.file_search,
    this.vector_store_ids,
    this.code_interpreter,
    this.code_interpreter_files,
    this.functions,
    this.temperature,
    this.likes,
    this.public,
    this.created_at,
    this.updated_at,
  });

  factory Bot.fromJson(Map<String, dynamic> json) {
    return Bot(
      id: json['id'] as int,
      name: json['name'],
      avatar: json['avatar'],
      description: json['description'],
      assistant_id: json['assistant_id'],
      instructions: json['instructions'],
      author_id: json['author_id'],
      author_name: json['author_name'],
      model: json['model'],
      file_search: json['file_search'],
      vector_store_ids: json['vector_store_ids'],
      code_interpreter: json['code_interpreter'],
      code_interpreter_files: json['code_interpreter_files'],
      functions: json['functions'],
      temperature: json['temperature'],
      likes: json['likes'],
      public: json['public'],
      created_at: json['created_at'],
      updated_at: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "avatar": avatar,
      "description": description,
      "assistant_id": assistant_id,
      "instructions": instructions,
      "author_id": author_id,
      "author_name": author_name,
      "model": model,
      "public": public,
      "file_search": file_search,
      "code_interpreter": code_interpreter,
      "vector_store_ids": vector_store_ids,
      "code_interpreter_files": code_interpreter_files,
      "functions": functions,
      "temperature": temperature,
      "likes": likes,
      "created_at": created_at,
      "updated_at": updated_at,
    };
  }
}
