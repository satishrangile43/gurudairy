import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // hive_flutter use karein
import '../../models/book_model.dart';
import 'book_editor_screen.dart';

class BookListScreen extends StatefulWidget {
  final String subjectName;

  const BookListScreen({super.key, required this.subjectName});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  // Box ko late initialize karein
  late Box<BookModel> booksBox;

  @override
  void initState() {
    super.initState();
    // Safe tarike se box ko access karein
    booksBox = Hive.box<BookModel>("booksBox");
  }

  // Filtered books list
  List<BookModel> getBooks() {
    return booksBox.values.where((book) {
      return book.subject == widget.subjectName;
    }).toList();
  }

  /// ADD BOOK
  void addBook() {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Book to ${widget.subjectName}"),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: "Enter Book Name (e.g. Unit 1 Notes)",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  final book = BookModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: controller.text.trim(),
                    subject: widget.subjectName,
                    pages: [], // Initial empty list for pages
                  );

                  booksBox.put(book.id, book);
                  setState(() {});
                  Navigator.pop(context);
                }
              },
              child: const Text("Add", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  /// EDIT BOOK
  void editBook(BookModel book) {
    TextEditingController controller = TextEditingController(text: book.name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Book Name"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  book.name = controller.text.trim();
                  book.save(); // Yeh tabhi kaam karega jab Model 'HiveObject' ho
                  setState(() {});
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  /// DELETE BOOK
  void deleteBook(BookModel book) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Book"),
          content: Text(
              "Are you sure you want to delete '${book.name}'? All pages inside will be lost."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                book.delete();
                setState(() {});
                Navigator.pop(context);
              },
              child:
                  const Text("Delete", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final books = getBooks();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.subjectName),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: books.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_books,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text("No books in ${widget.subjectName}",
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: books.length,
              padding: const EdgeInsets.all(10),
              itemBuilder: (context, index) {
                final book = books[index];

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.menu_book, color: Colors.orange),
                    title: Text(book.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("Click to open pages"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BookEditorScreen(subjectName: book.name),
                        ),
                      );
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => editBook(book),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteBook(book),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: addBook,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
