import 'dart:convert';

class ImageUrlContent {
  String type;
  ImageURL imageURL;
  ImageUrlContent({this.type = "image_url", required this.imageURL});

  Map<String, dynamic> toJson() => {
        'type': type,
        'image_url': imageURL.toJson(),
      };

  factory ImageUrlContent.fromJson(Map<String, dynamic> json) {
    return ImageUrlContent(
      type: json["type"],
      imageURL: ImageURL.fromJson(json['image_url']),
    );
  }
}

class ImageURL {
  String url;
  String detail;

  ImageURL({required this.url, this.detail = 'auto'});
  factory ImageURL.fromJson(Map<String, dynamic> json) {
    return ImageURL(
      url: json['url'],
      detail: json['detail'] ?? 'auto',
    );
  }
  Map<String, dynamic> toJson() => {'url': url, 'detail': detail};
}

class ImageFileContent {
  String type = 'image_file';
  ImageFile imageFile;
  ImageFileContent({this.type = "image_file", required this.imageFile});

  Map<String, dynamic> toJson() => {
        'type': type,
        'image_file': imageFile.toJson(),
      };

  factory ImageFileContent.fromJson(Map<String, dynamic> json) {
    return ImageFileContent(
      type: json['image_file']['file_id'],
      imageFile: json['image_file'].fromJson(),
    );
  }
}

class ImageFile {
  String file_id;
  String detail;

  ImageFile({required this.file_id, required this.detail});

  factory ImageFile.fromJson(Map<String, dynamic> json) {
    return ImageFile(
      file_id: json['file_id'],
      detail: json['detail'],
    );
  }

  Map<String, dynamic> toJson() => {'file_id': file_id, 'detail': detail};
}

class ToolCall {
  final String id;
  final String type;
  final FunctionObject function;

  ToolCall({required this.id, required this.type, required this.function});

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    return ToolCall(
      id: json['id'],
      type: json['type'],
      function: FunctionObject.fromJson(json['function']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'function': function.toJson(),
    };
  }
}

class FunctionObject {
  String name;
  String? description;
  Map<String, dynamic>? parameters;

  FunctionObject({required this.name, this.description, this.parameters});

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null) 'description': description,
        if (parameters != null) 'parameters': parameters,
      };

  static FunctionObject fromJson(Map<String, dynamic> json) => FunctionObject(
        name: json['name'],
        description: json['description'],
        parameters:
            json['parameters'] != null ? jsonDecode(json['parameters']) : null,
      );
}
