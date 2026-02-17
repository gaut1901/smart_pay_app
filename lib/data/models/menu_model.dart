class MenuModel {
  final String menuName;
  final String menuCaption;
  final String url;
  final String icon;
  final String root;
  final List<MenuModel> children;

  MenuModel({
    required this.menuName,
    required this.menuCaption,
    required this.url,
    required this.icon,
    required this.root,
    this.children = const [],
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    return MenuModel(
      menuName: json['menuname']?.toString() ?? '',
      menuCaption: json['menucaption']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      root: json['root']?.toString() ?? '',
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => MenuModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}
