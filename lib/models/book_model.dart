import 'package:hive/hive.dart';

part 'book_model.g.dart';

@HiveType(typeId: 2)
class BookModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String subject;

  @HiveField(3)
  List pages;

  BookModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.pages,
  });
}
