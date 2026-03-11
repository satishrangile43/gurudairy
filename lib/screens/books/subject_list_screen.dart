import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/book_model.dart';
import 'book_editor_screen.dart';

class SubjectListScreen extends StatefulWidget {
  const SubjectListScreen({super.key});

  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  late Box<BookModel> booksBox;
  late Box subjectsBox;

  List<String> subjects = [];

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    booksBox = Hive.box<BookModel>("books");
    subjectsBox = Hive.box("attendance_store");

    _loadSubjects();
  }

  void _loadSubjects() {
    final stored =
        subjectsBox.get("subjects", defaultValue: ["Mathematics", "Science"]);
    subjects = List<String>.from(stored);
    setState(() {});
  }

  void _saveSubjects() {
    subjectsBox.put("subjects", subjects);
  }

  // --- SUBJECT LOGIC ---
  void _addSubject() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        subjects.add(_controller.text.trim());
      });

      _saveSubjects();

      _controller.clear();
      Navigator.pop(context);
    }
  }

  void _deleteSubject(int index) {
    setState(() {
      subjects.removeAt(index);
    });

    _saveSubjects();
  }

  // --- BOOK LOGIC ---

  void _renameBook(BookModel book) {
    TextEditingController renameController =
        TextEditingController(text: book.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename Book"),
        content: TextField(
          controller: renameController,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (renameController.text.isNotEmpty) {
                setState(() {
                  book.name = renameController.text.trim();
                  book.save();
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteBook(BookModel book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Book?"),
        content: Text(
            "Kya aap '${book.name}' ko delete karna chahte hain? Iske saare pages ud jayenge."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("No")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                book.delete();
              });
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addBookToSubject(String subjectName) {
    TextEditingController bookController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Book to $subjectName"),
        content: TextField(
          controller: bookController,
          autofocus: true,
          decoration:
              const InputDecoration(hintText: "Book Name (e.g. Unit 1)"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (bookController.text.isNotEmpty) {
                final book = BookModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: bookController.text.trim(),
                  subject: subjectName,
                  pages: [],
                );

                booksBox.put(book.id, book);

                setState(() {});
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("My Subjects & Books"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: subjects.isEmpty
          ? const Center(child: Text("No subjects added yet."))
          : ListView.builder(
              itemCount: subjects.length,
              padding: const EdgeInsets.all(10),
              itemBuilder: (context, index) {
                String subjectName = subjects[index];

                final List<BookModel> filteredBooks = booksBox.values
                    .where((book) => book.subject == subjectName)
                    .toList();

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: ExpansionTile(
                    leading: const Icon(Icons.folder,
                        color: Colors.orange, size: 30),
                    title: Text(
                      subjectName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Text("${filteredBooks.length} Books available"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_sweep, color: Colors.grey),
                      onPressed: () => _deleteSubject(index),
                    ),
                    children: [
                      const Divider(height: 1),
                      ...filteredBooks.map((book) => ListTile(
                            leading: const Icon(Icons.menu_book,
                                color: Colors.blue, size: 20),
                            title: Text(book.name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.green, size: 20),
                                  onPressed: () => _renameBook(book),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red, size: 20),
                                  onPressed: () => _confirmDeleteBook(book),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BookEditorScreen(subjectName: book.name),
                                ),
                              );
                            },
                          )),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: TextButton.icon(
                          onPressed: () => _addBookToSubject(subjectName),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text("Add New Book"),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _controller.clear();

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Add New Subject"),
              content: TextField(
                controller: _controller,
                decoration:
                    const InputDecoration(hintText: "Enter Subject Name"),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: _addSubject, child: const Text("Add")),
              ],
            ),
          );
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.folder_copy, color: Colors.white),
      ),
    );
  }
}
