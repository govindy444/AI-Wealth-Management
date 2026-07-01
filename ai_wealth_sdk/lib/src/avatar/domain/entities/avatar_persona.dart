import 'package:equatable/equatable.dart';

class AvatarPersona extends Equatable {
  const AvatarPersona({
    required this.id,
    required this.name,
    required this.title,
    required this.accentColorHex,
    required this.languages,
    required this.defaultLanguage,
  });

  final String id;
  final String name;
  final String title;

  final String accentColorHex;

  final List<String> languages;
  final String defaultLanguage;

  bool supports(String language) => languages.contains(language);

  @override
  List<Object?> get props =>
      [id, name, title, accentColorHex, languages, defaultLanguage];
}
