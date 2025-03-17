import 'dart:math';
import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html; // Only used on web


// Replace with your Firebase options if needed.
class DefaultFirebaseOptions {
  static get currentPlatform => null;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shop Floor Audit Questionnaire',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: WelcomePage(),
    );
  }
}

class AuditInfo {
  String line;
  String shift;
  String auditorName;

  AuditInfo({this.line = '', this.shift = '', this.auditorName = ''});
}

class Section {
  final String name;
  final List<Question> questions;

  Section({required this.name, required this.questions});
}

class Question {
  final String text;
  bool? answer; // true for Yes, false for No, null if not answered yet
  String comment;

  Question({required this.text, this.answer, this.comment = ''});
}

/// ScoreData holds the overall score and each section's score.
class ScoreData {
  final double overallScore;
  final List<double> sectionScores;
  final List<String> sectionNames;

  ScoreData({
    required this.overallScore,
    required this.sectionScores,
    required this.sectionNames,
  });
}

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final AuditInfo auditInfo = AuditInfo();
  final _formKey = GlobalKey<FormState>();
  final List<String> lines = ['DCM02', 'DCM04', 'DCM06'];
  final List<String> shifts = ['1st shift', '2nd shift'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shop Floor Audit'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    'Welcome to Shop Floor Audit',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    'Complete the form below to start',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                SizedBox(height: 40),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Which line are you auditing?',
                    border: OutlineInputBorder(),
                  ),
                  value: auditInfo.line.isEmpty ? null : auditInfo.line,
                  items: lines.map((String line) {
                    return DropdownMenuItem<String>(
                      value: line,
                      child: Text(line),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      auditInfo.line = newValue ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a line';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Which shift are you auditing?',
                    border: OutlineInputBorder(),
                  ),
                  value: auditInfo.shift.isEmpty ? null : auditInfo.shift,
                  items: shifts.map((String shift) {
                    return DropdownMenuItem<String>(
                      value: shift,
                      child: Text(shift),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      auditInfo.shift = newValue ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a shift';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Auditor\'s Name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    auditInfo.auditorName = value;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomePage(auditInfo: auditInfo),
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Start Audit',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final AuditInfo auditInfo;

  HomePage({required this.auditInfo});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();

  // Define sections and their questions.
  late final List<Section> sections = [
    Section(name: 'DBS', questions: [
      Question(text: 'Do we have "Just-do-it" action on RCPS Board about highest failure on pareto chart?'),
      Question(text: 'Are the 4 steps for critical issues updated on time (every Friday)?'),
    ]),
    Section(name: 'Diebond', questions: [
      Question(text: 'Are the VIM system been used to print scrap label? (ask the TC to check the scrap parts and show the label)'),
      Question(text: 'Are all machines functioning? If not, is there someone aware to fix it?'),
    ]),
    Section(name: 'Wirebond', questions: [
      Question(text: 'Are all downtime on Hourly Registration been registered?'),
      Question(text: 'Is the daily checklist fully checked with a green mark?'),
      Question(text: 'Are the SOPs organized and in place?'),
      Question(text: 'Is the floor marking clear and being used correctly?'),
    ]),
    Section(name: 'System Solder', questions: [
      Question(text: 'PPE (glasses, gloves/finger cot) in place and properly used?'),
      Question(text: 'Are the VIM system been used to print scrap label? (ask the TC to check the scrap parts and show the label)'),
      Question(text: 'Are all machines functioning? If not, is there someone aware to fix it?'),
    ]),
    Section(name: 'Final Test', questions: [
      Question(text: 'Are all downtime on Hourly Registration been registered?'),
      Question(text: 'Is the daily checklist fully checked with a green mark?'),
      Question(text: 'Are the SOPs organized and in place?'),
    ]),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _scrollController.jumpTo(0);
    });
  }

  bool isAuditComplete() {
    for (Section section in sections) {
      for (Question question in section.questions) {
        if (question.answer == null) return false;
      }
    }
    return true;
  }

  List<String> getIncompleteSections() {
    List<String> incompleteSections = [];
    for (int i = 0; i < sections.length; i++) {
      for (Question question in sections[i].questions) {
        if (question.answer == null) {
          incompleteSections.add(sections[i].name);
          break;
        }
      }
    }
    return incompleteSections;
  }

  Widget _buildQuestionCard(Question question, int index) {
    // Use a unique key to avoid state mixing.
    return Card(
      key: ValueKey('section_${_selectedIndex}_question_$index'),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}. ${question.text}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text('Answer: '),
                Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: question.answer,
                      onChanged: (bool? value) {
                        setState(() {
                          question.answer = value;
                        });
                      },
                    ),
                    Text('Yes'),
                  ],
                ),
                Row(
                  children: [
                    Radio<bool>(
                      value: false,
                      groupValue: question.answer,
                      onChanged: (bool? value) {
                        setState(() {
                          question.answer = value;
                        });
                      },
                    ),
                    Text('No'),
                  ],
                ),
              ],
            ),
            TextField(
              key: ValueKey('section_${_selectedIndex}_question_${index}_comment'),
              decoration: InputDecoration(
                labelText: 'Comments / Improvement ideas (optional)',
              ),
              onChanged: (text) {
                question.comment = text;
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submitAudit() {
    if (!isAuditComplete()) {
      List<String> incomplete = getIncompleteSections();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please complete all questions in: ${incomplete.join(', ')}"),
          duration: Duration(seconds: 5),
        ),
      );
      if (!incomplete.contains(sections[_selectedIndex].name)) {
        for (int i = 0; i < sections.length; i++) {
          if (incomplete.contains(sections[i].name)) {
            setState(() {
              _selectedIndex = i;
              _scrollController.jumpTo(0);
            });
            break;
          }
        }
      }
      return;
    }

    int totalQuestions = 0;
    int totalYes = 0;
    List<double> sectionScores = [];
    List<String> sectionNames = [];
    for (Section section in sections) {
      int sectionTotal = section.questions.length;
      int sectionYes = section.questions.where((q) => q.answer == true).length;
      totalQuestions += sectionTotal;
      totalYes += sectionYes;
      sectionScores.add(100 * sectionYes / sectionTotal);
      sectionNames.add(section.name);
    }
    double overallScore = 100 * totalYes / totalQuestions;
    ScoreData scoreData = ScoreData(
      overallScore: overallScore,
      sectionScores: sectionScores,
      sectionNames: sectionNames,
    );

    String results = "";
    results += "Audit Information:\n";
    results += "Date & Time: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}\n";
    int dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays + 1;
    int weekNumber = ((dayOfYear - DateTime.now().weekday + 10) / 7).floor();
    results += "Week Number: $weekNumber\n";
    results += "Auditor: ${widget.auditInfo.auditorName}\n";
    results += "Line: ${widget.auditInfo.line}\n";
    results += "Shift: ${widget.auditInfo.shift}\n\n";
    for (Section section in sections) {
      results += "\nSection: ${section.name}\n";
      for (Question q in section.questions) {
        results += "${q.text}\nAnswer: ${q.answer! ? 'Yes' : 'No'}\n";
        if (q.comment.isNotEmpty) {
          results += "Comment: ${q.comment}\n";
        }
        results += "\n";
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Submit Audit"),
        content: SingleChildScrollView(child: Text(results)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Back"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => ThankYouPage(
                    auditInfo: widget.auditInfo,
                    scoreData: scoreData,
                    sections: sections,
                  ),
                ),
                (Route<dynamic> route) => false,
              );
            },
            child: Text("Confirm Submission"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Section currentSection = sections[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Questionnaire - ${currentSection.name}'),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: _selectedIndex > 0
                ? () {
                    setState(() {
                      _selectedIndex--;
                      _scrollController.jumpTo(0);
                    });
                  }
                : null,
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: _selectedIndex < sections.length - 1
                ? () {
                    setState(() {
                      _selectedIndex++;
                      _scrollController.jumpTo(0);
                    });
                  }
                : null,
          ),
          TextButton(
            onPressed: () async {
              bool? confirm = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Confirm Start Over"),
                  content: Text("You will lose the current process, are you sure?"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      child: Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      child: Text("Yes"),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => WelcomePage()),
                  (Route<dynamic> route) => false,
                );
              }
            },
            child: Text(
              "Start over",
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.grey[200],
            padding: EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Line: ${widget.auditInfo.line}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Shift: ${widget.auditInfo.shift}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Auditor: ${widget.auditInfo.auditorName}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Section ${_selectedIndex + 1} of ${sections.length}",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: currentSection.questions.length,
              itemBuilder: (context, index) {
                final question = currentSection.questions[index];
                return _buildQuestionCard(question, index);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isAuditComplete() ? _submitAudit : null,
        label: Text("Submit"),
        icon: Icon(Icons.send),
        backgroundColor: isAuditComplete() ? Colors.blue : Colors.grey,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: sections
            .map((section) => BottomNavigationBarItem(
                  icon: Icon(Icons.list),
                  label: section.name,
                ))
            .toList(),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
      ),
    );
  }
}

/// A custom widget that displays a radar (spider) chart.
class RadarChartWidget extends StatelessWidget {
  final List<double> scores;
  final List<String> labels;

  RadarChartWidget({required this.scores, required this.labels});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double size = min(constraints.maxWidth, constraints.maxHeight);
      return Container(
        width: size,
        height: size,
        child: CustomPaint(
          painter: RadarChartPainter(scores: scores, labels: labels),
        ),
      );
    });
  }
}

class RadarChartPainter extends CustomPainter {
  final List<double> scores;
  final List<String> labels;

  RadarChartPainter({required this.scores, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final int n = scores.length;
    final center = Offset(size.width / 2, size.height / 2);
    // Reduced radius factor for a smaller chart
    final double radius = min(size.width, size.height) / 2 * 0.6;

    final Paint gridPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke;

    // Draw concentric polygons
    int levels = 5;
    for (int level = 1; level <= levels; level++) {
      double r = radius * level / levels;
      List<Offset> points = [];
      for (int i = 0; i < n; i++) {
        double angle = (2 * pi / n) * i - pi / 2;
        points.add(Offset(center.dx + r * cos(angle), center.dy + r * sin(angle)));
      }
      _drawPolygon(canvas, points, gridPaint);
    }

    // Draw radial lines
    for (int i = 0; i < n; i++) {
      double angle = (2 * pi / n) * i - pi / 2;
      canvas.drawLine(center, Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle)), gridPaint);
    }

    // Draw data polygon
    List<Offset> dataPoints = [];
    for (int i = 0; i < n; i++) {
      double angle = (2 * pi / n) * i - pi / 2;
      double r = radius * (scores[i] / 100.0);
      dataPoints.add(Offset(center.dx + r * cos(angle), center.dy + r * sin(angle)));
    }
    if (dataPoints.isNotEmpty) {
      Path dataPath = Path()..moveTo(dataPoints[0].dx, dataPoints[0].dy);
      for (int i = 1; i < dataPoints.length; i++) {
        dataPath.lineTo(dataPoints[i].dx, dataPoints[i].dy);
      }
      dataPath.close();

      final Paint dataFillPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      final Paint dataStrokePaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawPath(dataPath, dataFillPaint);
      canvas.drawPath(dataPath, dataStrokePaint);
    }

    // Draw labels for each axis
    for (int i = 0; i < n; i++) {
      double angle = (2 * pi / n) * i - pi / 2;
      Offset labelOffset = Offset(center.dx + (radius + 20) * cos(angle),
          center.dy + (radius + 20) * sin(angle));
      TextSpan span = TextSpan(
          style: TextStyle(color: Colors.black, fontSize: 12), text: labels[i]);
      TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.center,
          textDirection: ui.TextDirection.ltr);
      tp.layout();
      Offset adjusted = labelOffset - Offset(tp.width / 2, tp.height / 2);
      tp.paint(canvas, adjusted);
    }

    // Draw score numbers near each data point
    for (int i = 0; i < n; i++) {
      double angle = (2 * pi / n) * i - pi / 2;
      double r = radius * (scores[i] / 100.0);
      // Place score text 10 pixels further along the same direction
      Offset textOffset = Offset(center.dx + (r + 10) * cos(angle), center.dy + (r + 10) * sin(angle));
      TextSpan span = TextSpan(
          style: TextStyle(color: Colors.blue, fontSize: 12),
          text: '${scores[i].toStringAsFixed(0)}%');
      TextPainter tp = TextPainter(
          text: span, textAlign: TextAlign.center, textDirection: ui.TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, textOffset - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _drawPolygon(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;
    Path path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class ThankYouPage extends StatelessWidget {
  final AuditInfo auditInfo;
  final ScoreData scoreData;
  final List<Section> sections;

  // GlobalKey for capturing the radar chart widget.
  final GlobalKey _chartKey = GlobalKey();

  ThankYouPage({
    required this.auditInfo,
    required this.scoreData,
    required this.sections,
  });

  // Capture the radar chart from the RepaintBoundary.
  Future<ui.Image> _captureChart() async {
    RenderRepaintBoundary boundary =
        _chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    return image;
  }

  // Generate and export the audit report as an HTML file.
  Future<void> exportAsHtml(BuildContext context) async {
    ui.Image chartImage = await _captureChart();
    ByteData? byteData =
        await chartImage.toByteData(format: ui.ImageByteFormat.png);
    String base64Image = base64Encode(byteData!.buffer.asUint8List());

    DateTime now = DateTime.now();
    int dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    int weekNumber = ((dayOfYear - now.weekday + 10) / 7).floor();

    // Build HTML content that includes date/time, week number, auditor info, radar chart and questions.
    StringBuffer questionsBuffer = StringBuffer();
    for (Section section in sections) {
      questionsBuffer.writeln('<h2>Section: ${section.name}</h2>');
      for (Question q in section.questions) {
        questionsBuffer.writeln(
            '<p><strong>${q.text}</strong><br>Answer: ${q.answer == true ? "Yes" : "No"}<br>'
            '${q.comment.isNotEmpty ? "Comment: " + q.comment + "<br>" : ""}</p>');
      }
    }

    String htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <title>Audit Report - ${auditInfo.line}</title>
  <style>
    body { font-family: Arial, sans-serif; }
    .container { max-width: 800px; margin: 0 auto; }
    h1, h2 { color: #333; }
    .chart-container { max-width: 400px; margin: 0 auto; } /* Control chart size */
    .no-answer { color: red; }
    .question { margin-bottom: 10px; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Audit Results</h1>
    <p>
      Date & Time: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(now)}<br>
      Week: $weekNumber<br>
      Auditor: ${auditInfo.auditorName}
    </p>
    <p>
      Line: ${auditInfo.line}<br>
      Shift: ${auditInfo.shift}
    </p>
    <h2>Overall Score: ${scoreData.overallScore.toStringAsFixed(1)}%</h2>
    <h2>Section Scores</h2>
    <div class="chart-container">
      <img src="data:image/png;base64,${base64Image}" alt="Radar Chart" style="width: 100%;">
    </div>
    <h2>Questions and Responses</h2>
''';
for (Section section in sections) {
  htmlContent += '<h2>Section: ${section.name}</h2>\n';
  for (Question q in section.questions) {
    String answerClass = q.answer == false ? 'no-answer' : '';
    htmlContent += '<div class="question"><strong';
    if (q.answer == false) {
      htmlContent += ' class="no-answer"';
    }
    htmlContent += '>${q.text}</strong><br>\n';
    htmlContent += 'Answer: <span class="${answerClass}">${q.answer == true ? "Yes" : "No"}</span>';
    if (q.comment.isNotEmpty) {
      htmlContent += ' - Comment: ${q.comment}';
    }
    htmlContent += '</div>\n';
  }
}

htmlContent += '''
  </div>
</body>
</html>
''';

    if (kIsWeb) {
      // For web: trigger a download using dart:html.
      final bytes = utf8.encode(htmlContent);
      final blob = html.Blob([bytes], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = 'audit_report.html';
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } else {
      // For mobile/desktop: write the file to a temporary directory and share.
      final tempDir = await getTemporaryDirectory();
      File file = File('${tempDir.path}/audit_report.html');
      await file.writeAsString(htmlContent);
      Share.shareFiles([file.path], text: 'Audit Report');
    }
  }

  @override
  Widget build(BuildContext context) {
    double chartSize = min(MediaQuery.of(context).size.width * 0.6, 300);
    return Scaffold(
      appBar: AppBar(
        title: Text('Audit Completed'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 100,
                ),
                SizedBox(height: 32),
                Text(
                  'Thank You!',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  'Your audit has been submitted successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 16),
                Text(
                  'Line: ${auditInfo.line}, Shift: ${auditInfo.shift}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                Text(
                  'Auditor: ${auditInfo.auditorName}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                SizedBox(height: 32),
                Text(
                  'Overall Score: ${scoreData.overallScore.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 32),
                Text(
                  'Section Scores',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                RepaintBoundary(
                  key: _chartKey,
                  child: Container(
                    width: chartSize,
                    height: chartSize,
                    child: RadarChartWidget(
                      scores: scoreData.sectionScores,
                      labels: scoreData.sectionNames,
                    ),
                  ),
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => exportAsHtml(context),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Download Audit HTML',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => WelcomePage()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 24.0),
                    child: Text(
                      'Create Another Audit',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
