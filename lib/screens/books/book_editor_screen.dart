import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:printing/printing.dart';
import 'dart:io';

class BookEditorScreen extends StatefulWidget {
  final String subjectName;
  const BookEditorScreen({super.key, required this.subjectName});

  @override
  State<BookEditorScreen> createState() => _BookEditorScreenState();
}

class _BookEditorScreenState extends State<BookEditorScreen> {
  // List of controllers for each page
  final List<QuillController> _pages = [];
  int _currentPageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // Start with one empty page
    _pages.add(QuillController.basic());
  }

  @override
  void dispose() {
    // Memory leak se bachne ke liye saare controllers dispose karein
    for (var controller in _pages) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  // --- Print Current Page ---
  Future<void> printCurrentPage() async {
    final pdf = pw.Document();
    // Plain text nikalne ke liye
    final text = _pages[_currentPageIndex].document.toPlainText();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Text(text, style: const pw.TextStyle(fontSize: 12)),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${widget.subjectName}_Page_${_currentPageIndex + 1}',
    );
  }

  void jumpToPage(int index) {
    if (index >= 0 && index < _pages.length) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void addPage() {
    setState(() {
      _pages.add(QuillController.basic());
    });
    // Naye page par move karein
    Future.delayed(const Duration(milliseconds: 100), () {
      jumpToPage(_pages.length - 1);
    });
  }

  void removePage() {
    if (_pages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kam se kam ek page hona chahiye!")),
      );
      return;
    }

    setState(() {
      final indexToRemove = _currentPageIndex;
      // Pehle screen change karein phir dispose
      if (_currentPageIndex == _pages.length - 1) {
        _currentPageIndex--;
      }

      _pages[indexToRemove].dispose();
      _pages.removeAt(indexToRemove);
    });
  }

  Future<void> exportBookPDF() async {
    final pdf = pw.Document();
    for (var controller in _pages) {
      final text = controller.document.toPlainText();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Text(text),
          ),
        ),
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/${widget.subjectName}_book.pdf");
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showJumpDialog,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  "${widget.subjectName} (${_currentPageIndex + 1}/${_pages.length})",
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
              icon: const Icon(Icons.print), onPressed: printCurrentPage),
          IconButton(icon: const Icon(Icons.add), onPressed: addPage),
          IconButton(icon: const Icon(Icons.delete), onPressed: removePage),
          IconButton(
              icon: const Icon(Icons.picture_as_pdf), onPressed: exportBookPDF),
        ],
      ),
      body: Column(
        children: [
          // Toolbar: Always tied to the current page's controller
          QuillSimpleToolbar(
            controller: _pages[_currentPageIndex],
            config: QuillSimpleToolbarConfig(
              multiRowsDisplay: false, // UI saaf rakhne ke liye
              showFontSize: true,
              showBoldButton: true,
              showItalicButton: true,
              showColorButton: true,
              embedButtons: FlutterQuillEmbeds.toolbarButtons(),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Center(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            spreadRadius: 1)
                      ],
                    ),
                    child: QuillEditor.basic(
                      controller: _pages[index],
                      config: QuillEditorConfig(
                        placeholder:
                            "Page ${index + 1} par likhna shuru karein...",
                        expands: true,
                        autoFocus: false,
                        embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showJumpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Go to Page"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _pages.length,
            itemBuilder: (context, index) => ListTile(
              leading: CircleAvatar(
                backgroundColor: _currentPageIndex == index
                    ? Colors.orange
                    : Colors.grey[300],
                child: Text("${index + 1}",
                    style: TextStyle(
                        color: _currentPageIndex == index
                            ? Colors.white
                            : Colors.black)),
              ),
              title: Text("Page ${index + 1}"),
              onTap: () {
                Navigator.pop(context);
                jumpToPage(index);
              },
            ),
          ),
        ),
      ),
    );
  }
}
