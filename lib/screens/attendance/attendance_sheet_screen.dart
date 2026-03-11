import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:excel/excel.dart' as ex;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';

class AttendanceSheetScreen extends StatefulWidget {
  final String className;

  const AttendanceSheetScreen({super.key, required this.className});

  @override
  State<AttendanceSheetScreen> createState() => _AttendanceSheetScreenState();
}

class _AttendanceSheetScreenState extends State<AttendanceSheetScreen> {
  late String currentClassName;
  DateTime selectedMonth = DateTime.now();

  Map<String, Map<String, Map<int, String>>> monthlyData = {};

  List<Map<String, dynamic>> students = [
    {"roll": "1", "name": "Student 1"},
    {"roll": "2", "name": "Student 2"},
  ];

  @override
  void initState() {
    super.initState();
    currentClassName = widget.className;
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    var box = await Hive.openBox('attendance_store');

    List? savedStudents = box.get('students_${widget.className}');
    if (savedStudents != null) {
      students = List<Map<String, dynamic>>.from(
        savedStudents.map((e) => Map<String, dynamic>.from(e)),
      );
    }

    var savedData = box.get('data_${widget.className}');
    if (savedData != null) {
      Map<dynamic, dynamic> rawData = savedData;

      monthlyData = rawData.map((mKey, mVal) {
        return MapEntry(
          mKey.toString(),
          (mVal as Map).map((rKey, rVal) {
            return MapEntry(
              rKey.toString(),
              Map<int, String>.from(rVal),
            );
          }),
        );
      });
    }

    setState(() {});
  }

  Future<void> _saveToHive() async {
    var box = await Hive.openBox('attendance_store');

    await box.put('students_${widget.className}', students);
    await box.put('data_${widget.className}', monthlyData);
  }

  // ---------------- ADD STUDENT ----------------

  void _addStudent() {
    TextEditingController nameController = TextEditingController();
    TextEditingController rollController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Student"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: rollController,
              decoration: const InputDecoration(labelText: "Roll No"),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                students.add({
                  "roll": rollController.text,
                  "name": nameController.text,
                });
              });

              _saveToHive();
              Navigator.pop(context);
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  // ---------------- REMOVE STUDENT ----------------

  void _removeStudent(int index) {
    setState(() {
      students.removeAt(index);
    });

    _saveToHive();
  }

  int get daysInMonth =>
      DateUtils.getDaysInMonth(selectedMonth.year, selectedMonth.month);

  String get monthKey => "${selectedMonth.month}_${selectedMonth.year}";

  void _updateAttendance(String roll, int day) {
    DateTime now = DateTime.now();

    if (selectedMonth.year == now.year &&
        selectedMonth.month == now.month &&
        day > now.day) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cannot mark attendance for future dates!"),
        ),
      );
      return;
    }

    setState(() {
      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = {};
      }

      if (!monthlyData[monthKey]!.containsKey(roll)) {
        monthlyData[monthKey]![roll] = {};
      }

      String currentStatus = monthlyData[monthKey]![roll]![day] ?? "";

      if (currentStatus == "P") {
        monthlyData[monthKey]![roll]![day] = "A";
      } else if (currentStatus == "A") {
        monthlyData[monthKey]![roll]![day] = "";
      } else {
        monthlyData[monthKey]![roll]![day] = "P";
      }
    });

    _saveToHive();
  }

  void _editStudent(int index) {
    TextEditingController nameController =
        TextEditingController(text: students[index]['name']);

    TextEditingController rollController =
        TextEditingController(text: students[index]['roll']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Student Info"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: rollController,
              decoration: const InputDecoration(labelText: "Roll No"),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                students[index]['name'] = nameController.text;
                students[index]['roll'] = rollController.text;
              });

              _saveToHive();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  Future<void> _exportPDF() async {
    final pdf = pw.Document();
    List<String> headers = ["Roll", "Name"];
    for (int i = 1; i <= daysInMonth; i++) {
      headers.add(i.toString());
    }

    List<List<String>> dataRows = [];

    for (var s in students) {
      String roll = s['roll'];
      List<String> row = [roll, s['name']];

      for (int day = 1; day <= daysInMonth; day++) {
        row.add(monthlyData[monthKey]?[roll]?[day] ?? "");
      }

      dataRows.add(row);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(1200, 700, marginAll: 10),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Attendance Sheet - $currentClassName",
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text(
                "Month: ${_getMonthName(selectedMonth.month)} ${selectedMonth.year}"),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(headers: headers, data: dataRows),
          ],
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/attendance_$currentClassName.pdf");

    await file.writeAsBytes(await pdf.save());

    if (!mounted) return;

    OpenFile.open(file.path);
  }

  Future<void> _exportExcel() async {
    var excel = ex.Excel.createExcel();
    ex.Sheet sheet = excel['Attendance'];

    List<ex.CellValue> headerRow = [
      ex.TextCellValue("Roll"),
      ex.TextCellValue("Name")
    ];

    for (int i = 1; i <= daysInMonth; i++) {
      headerRow.add(ex.TextCellValue(i.toString()));
    }

    sheet.appendRow(headerRow);

    for (var s in students) {
      String roll = s['roll'];

      List<ex.CellValue> row = [
        ex.TextCellValue(roll),
        ex.TextCellValue(s['name'])
      ];

      for (int day = 1; day <= daysInMonth; day++) {
        row.add(ex.TextCellValue(monthlyData[monthKey]?[roll]?[day] ?? ""));
      }

      sheet.appendRow(row);
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/attendance_$currentClassName.xlsx");

    await file.writeAsBytes(excel.encode()!);

    if (!mounted) return;

    OpenFile.open(file.path);
  }

  Future<void> _pickMonth() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Month"),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(12, (index) {
            return ChoiceChip(
              label: Text(_getMonthName(index + 1)),
              selected: selectedMonth.month == index + 1,
              onSelected: (selected) {
                if (selected) {
                  Navigator.pop(context);
                  _pickYear(index + 1);
                }
              },
            );
          }),
        ),
      ),
    );
  }

  void _pickYear(int month) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Select Year for ${_getMonthName(month)}"),
        content: SizedBox(
          width: 300,
          height: 300,
          child: YearPicker(
            firstDate: DateTime(2023),
            lastDate: DateTime.now(),
            selectedDate: selectedMonth,
            onChanged: (dateTime) {
              setState(() {
                selectedMonth = DateTime(dateTime.year, month);
              });
              _loadSavedData();
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentClassName),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.person_add), onPressed: _addStudent),
          IconButton(
              icon: const Icon(Icons.picture_as_pdf), onPressed: _exportPDF),
          IconButton(
              icon: const Icon(Icons.table_chart), onPressed: _exportExcel),
        ],
      ),
      body: Column(
        children: [
          GestureDetector(
            onTap: _pickMonth,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.indigo.shade50,
              child: Center(
                child: Text(
                  "${_getMonthName(selectedMonth.month)} ${selectedMonth.year} (Change Month)",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 10,
                columns: [
                  const DataColumn(label: Text('Roll')),
                  const DataColumn(label: Text('Name')),
                  const DataColumn(label: Text('Delete')),
                  for (int i = 1; i <= daysInMonth; i++) ...{
                    DataColumn(label: Text('$i'))
                  },
                ],
                rows: List.generate(students.length, (index) {
                  String roll = students[index]['roll'];

                  return DataRow(
                    cells: [
                      DataCell(InkWell(
                          onTap: () => _editStudent(index), child: Text(roll))),
                      DataCell(InkWell(
                          onTap: () => _editStudent(index),
                          child: Text(students[index]['name']))),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeStudent(index),
                        ),
                      ),
                      for (int day = 1; day <= daysInMonth; day++) ...{
                        DataCell(
                          GestureDetector(
                            onTap: () => _updateAttendance(roll, day),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: _getColor(
                                    monthlyData[monthKey]?[roll]?[day]),
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  monthlyData[monthKey]?[roll]?[day] ?? "",
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                        )
                      },
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(String? status) {
    if (status == "P") return Colors.green;
    if (status == "A") return Colors.red;
    return Colors.white;
  }

  String _getMonthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[month - 1];
  }
}
