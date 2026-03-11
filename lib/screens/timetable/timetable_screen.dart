import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:excel/excel.dart' as ex;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  List<Map<String, String>> timetableRows = [];
  final List<String> columns = [
    "Time",
    "Mon",
    "Tue",
    "Wed",
    "Thu",
    "Fri",
    "Sat"
  ];

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    var box = await Hive.openBox('timetable_store');
    List? savedData = box.get('my_timetable');
    if (savedData != null) {
      setState(() {
        timetableRows = List<Map<String, String>>.from(
          savedData.map((e) => Map<String, String>.from(e)),
        );
      });
    }
  }

  Future<void> _saveTimetable() async {
    var box = await Hive.openBox('timetable_store');
    await box.put('my_timetable', timetableRows);
  }

  void _addRow() {
    setState(() {
      timetableRows.add({
        "Time": "Click to set",
        "Mon": "",
        "Tue": "",
        "Wed": "",
        "Thu": "",
        "Fri": "",
        "Sat": "",
      });
    });
    _saveTimetable();
  }

  void _deleteRow(int index) {
    setState(() {
      timetableRows.removeAt(index);
    });
    _saveTimetable();
  }

  Future<void> _selectTime(int index) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        timetableRows[index]["Time"] = picked.format(context);
      });
      _saveTimetable();
    }
  }

  // --- UPDATED EDIT CELL LOGIC ---
  void _editCell(int rowIndex, String colName) {
    if (colName == "Time") {
      _selectTime(rowIndex);
      return;
    }

    // Controller with current text
    TextEditingController controller =
        TextEditingController(text: timetableRows[rowIndex][colName]);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit $colName Content"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Enter Subject (e.g. Maths, Science)",
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                timetableRows[rowIndex][colName] = controller.text;
              });
              _saveTimetable();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Time Table"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.picture_as_pdf), onPressed: _exportPDF),
          IconButton(
              icon: const Icon(Icons.table_chart), onPressed: _exportExcel),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.indigo.shade50,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.indigo),
                SizedBox(width: 8),
                Text("Tap cell to edit | Long press to delete row",
                    style: TextStyle(fontSize: 12, color: Colors.indigo)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columnSpacing: 15,
                  headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
                  columns: columns
                      .map((col) => DataColumn(
                          label: Text(col,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold))))
                      .toList(),
                  rows: List.generate(timetableRows.length, (index) {
                    return DataRow(
                      cells: columns.map((col) {
                        return DataCell(
                          GestureDetector(
                            onLongPress: () => _deleteRow(index),
                            onTap: () => _editCell(index, col),
                            child: Container(
                              alignment: Alignment.center,
                              width: col == "Time" ? 85 : 100,
                              height: 50,
                              color: Colors
                                  .transparent, // Ensures the whole cell is clickable
                              child: Text(
                                timetableRows[index][col]!.isEmpty
                                    ? "-"
                                    : timetableRows[index][col]!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: col == "Time"
                                      ? Colors.blue[800]
                                      : Colors.black,
                                  fontWeight: col == "Time"
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add),
              label: const Text("Add New Time Slot"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // PDF Export logic remains same as provided
  Future<void> _exportPDF() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      build: (context) => pw.Column(
        children: [
          pw.Header(level: 0, child: pw.Text("Weekly Timetable")),
          pw.TableHelper.fromTextArray(
            headers: columns,
            data: timetableRows
                .map((row) => columns.map((col) => row[col]!).toList())
                .toList(),
          ),
        ],
      ),
    ));
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/timetable.pdf");
    await file.writeAsBytes(await pdf.save());
    if (mounted) OpenFile.open(file.path);
  }

  // Excel Export logic remains same as provided
  Future<void> _exportExcel() async {
    var excel = ex.Excel.createExcel();
    ex.Sheet sheet = excel['Timetable'];
    sheet.appendRow(columns.map((e) => ex.TextCellValue(e)).toList());
    for (var row in timetableRows) {
      sheet.appendRow(
          columns.map((col) => ex.TextCellValue(row[col]!)).toList());
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/timetable.xlsx");
    await file.writeAsBytes(excel.encode()!);
    if (mounted) OpenFile.open(file.path);
  }
}
