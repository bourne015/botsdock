class VisionFile {
  String name;
  String url;
  List<int> bytes;

  VisionFile({
    required this.name,
    this.url = "",
    this.bytes = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'bytes': [], //drop bytes
    };
  }

  factory VisionFile.fromJson(Map<String, dynamic> json) {
    return VisionFile(
      name: json['name'],
      url: json['url'],
      bytes: List<int>.from(json['bytes']),
    );
  }
}
