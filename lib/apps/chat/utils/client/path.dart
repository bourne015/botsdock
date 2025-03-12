class ChatPath {
  static const String base = "https://botsdock.com:8443";
  static const String completion = "/v1/stream/chats";
  static const String image = "/v1/image";

  static String allChats(int userId) => "/v1/user/${userId}/chats";
  static String chatDelete(int userId, int chat_id) =>
      "/v1/user/${userId}/chats/${chat_id}";
  static String userInfo(int userId) => "/v1/user/$userId/info";
  static String userUpdate(int userId) => "/v1/user/$userId";
  static String creds(int userId) => "/v1/user/$userId/oss_credentials";

  static String saveChat(int userId) => "/v1/user/$userId/chat";
  static String chatStream(int userId) => "${completion}?user_id=${userId}";

  static String chat(int userId) => "/v1/chat?user_id=${userId}";

  static String imageGen(int userId) => "${image}?user_id=${userId}";
}
