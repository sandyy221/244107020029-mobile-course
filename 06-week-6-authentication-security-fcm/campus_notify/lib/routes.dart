class AppRoutes {
  static const String login = '/login';
  static const String home = '/';
  static const String pengumumanDetail = '/pengumuman/:id';
  
  static String pengumumanDetailWithId(String id) => '/pengumuman/$id';
}