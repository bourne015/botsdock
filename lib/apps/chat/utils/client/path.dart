class ChatPath {
  static const String base = "https://botsdock.com:8443";
  static const String completion = "/v1/stream/chats";
  static const String image = "/v1/image";
  static const String user = "/v1/user";
  static const String allUsers = "/v1/users";
  static const String login = "/v1/user/login";
  static const String token = "/v1/user/me";
  static const String share = "/v1/shares";

  static String allChats(int userId) => "/v1/user/${userId}/chats";
  static String chatDelete(int userId, int chat_id) =>
      "/v1/user/${userId}/chat/${chat_id}";
  static String userInfo(int userId) => "/v1/user/$userId/info";
  static String userUpdate(int userId) => "/v1/user/$userId";
  static String usersecurity(int userId) => "/v1/user/$userId/security";
  static String creds(int userId) => "/v1/user/$userId/oss_credentials";
  static String charge(int userId) => "/v1/user/charge/$userId";

  static String saveChat(int userId) => "/v1/user/$userId/chat";
  static String chatStream(int userId) => "${completion}?user_id=${userId}";

  static String chat(int userId) => "/v1/chat?user_id=${userId}";

  static String imageGen(int userId) => "${image}?user_id=${userId}";

  //assistant
  static String asstMessages(String assistantId, String threadId) =>
      "/v1/assistant/vs/${assistantId}/threads/${threadId}/messages";

  static const String bot = "/v1/bot";
  static const String bots = "/v1/bot/bots";
  static String botid(int botId) => "/v1/bot/${botId}";

  static const String mcp = "/v1/mcp";
  static const String mcps = "/v1/mcps";
  static String mcpinfo(String mcpId) => "/v1/mcp/${mcpId}";
}
