import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class Bots with ChangeNotifier {
  List<Bot> _bots = [];
  List<Bot> get bots => _bots;
  final dio = Dio();

  Future<void> fetchBots() async {
    final response = await dio.post('https://fantao.life:8001/v1/bot/bots');
    if (response.statusCode == 200) {
      List<dynamic> data = response.data;
      _bots = data.map((item) => Bot.fromJson(item)).toList();
      notifyListeners();
    } else {
      throw Exception('Failed to load bots');
    }
  }

  void addBot(Bot bot) {
    _bots.add(bot);
    notifyListeners();
  }

  void deleteBot(int id) {
    _bots.removeWhere((element) => element.id == id);
    notifyListeners();
  }
}

class Bot {
  int id;
  String name;
  String? avatar;
  String? description;

  String? assistant_id;
  String? prompts;
  int? author_id;
  String? author_name;
  String? model;
  bool? file_search;
  Map? vector_store_ids;
  bool? code_interpreter;
  Map? code_interpreter_files;
  Map? functions;
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
    this.prompts,
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
      prompts: json['prompts'],
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
}
