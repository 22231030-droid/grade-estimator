import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const StudyTrackApp());
}

class StudyTrackApp extends StatelessWidget {
  const StudyTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StudyTrack',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        fontFamily: 'Arial',
      ),
      home: const HomePage(),
    );
  }
}

class CourseComponent {
  String type;
  double score;
  double weight;

  CourseComponent({
    required this.type,
    required this.score,
    required this.weight,
  });

  Map<String, dynamic> toJson(){
    return{
      'type': type,
      'score':score,
      'weight':weight,
    };
  }
  
  factory CourseComponent.fromJson(Map<String, dynamic> json){
    return CourseComponent(
      type: json['type'],
       score:(json['score'] as num).toDouble(),
        weight: (json['weight'] as num).toDouble(),
        );
  }

  double get resultPercent => score;

  double get weightedContribution => (score * weight) / 100;
}

class Course {
  String name;
  List<CourseComponent> components;

  Course({
    required this.name,
    required this.components,
  });
  
  Map<String, dynamic> toJson(){
    return{
      'name': name,
      'components': components.map((c) => c.toJson()).toList(),
    };
  }

  factory Course.fromJson(Map<String, dynamic> json){
    return Course(
      name: (json['name'] ?? '').toString(),
      components: json['components'] != null
      ? (json['components'] as List).map((c) => CourseComponent.fromJson(c)).toList():[],
    );
  }

  double get average {
    double total = 0;
    for (var c in components) {
      total += c.weightedContribution;
    }
    return total;
  }

  double get gpa {
    double value = average / 25;
    if (value > 4.0) return 4.0;
    if (value < 0) return 0.0;
    return value;
  }

  String get letterGrade {
    double avg = average;
    if (avg >= 90) return 'A';
    if (avg >= 80) return 'B';
    if (avg >= 70) return 'C';
    if (avg >= 60) return 'D';
    return 'F';
  }

  bool get passed => average >= 60;
}

class StudyEvent {
  String title;
  String course;
  DateTime date;
  String type;
  String note;

  StudyEvent({
    required this.title,
    required this.course,
    required this.date,
    required this.type,
    required this.note,
  });

  Map<String, dynamic> toJson(){
    return{
      'title': title,
      'course': course,
      'date': date.toIso8601String(),
      'type': type,
      'note': note,
    };
  }

  factory StudyEvent.fromJson(Map<String, dynamic> json){
    return StudyEvent(
      title: (json['title'] ?? '').toString(),
      course: (json['course'] ?? '').toString(),
      date: json['date'] != null
      ? DateTime.parse(json['date'].toString())
      : DateTime.now(),
      type: (json['type'] ?? 'Other').toString(),
      note: (json['note'] ?? '').toString(),
      );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedTab = 0;

  final List<Course> courses = [];

  final List<StudyEvent> events = [];

  Future<void> saveData() async{
    final prefs = await SharedPreferences.getInstance();

    List<String> coursesData = courses.map((c) => jsonEncode(c.toJson())).toList();
    List<String> eventsData = events.map((e) => jsonEncode(e.toJson())).toList();

    await prefs.setStringList('courses', coursesData);
    await prefs.setStringList('events', eventsData);
  }

  Future<void> loadData() async{
    final prefs = await SharedPreferences.getInstance();

    List<String>? coursesData = prefs.getStringList('courses');
    List<String>? eventsData = prefs.getStringList('events');

      setState((){
        courses.clear();
        events.clear();

        if(coursesData != null){
        
        courses.addAll(
          coursesData.map((c) => Course.fromJson(jsonDecode(c))).toList(),
          );
      }

      if(eventsData != null){
        
        events.addAll(
          eventsData.map((e) => StudyEvent.fromJson(jsonDecode(e))).toList(),
        );
      }
    });
  }

  @override
  void initState(){
    super.initState();
    loadData();
  }

  final TextEditingController courseNameController = TextEditingController();

  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            buildSidebar(),
            Expanded(
              child: selectedTab == 0 ? buildGradesPage() : buildCalendarPage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSidebar() {
    return Container(
      width: 92,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF2142FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school, color: Colors.white),
          ),
          const SizedBox(height: 10),
          const Text(
            'StudyTrack',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const Text(
            'Grade & Schedule Planner',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          IconButton(
            onPressed: () {
              setState(() {
                selectedTab = 0;
              });
            },
            icon: Icon(
              Icons.school_outlined,
              color: selectedTab == 0 ? const Color(0xFF2142FF) : Colors.grey,
            ),
          ),
          const Text('Grades', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 18),
          IconButton(
            onPressed: () {
              setState(() {
                selectedTab = 1;
              });
            },
            icon: Icon(
              Icons.calendar_month_outlined,
              color: selectedTab == 1 ? const Color(0xFF2142FF) : Colors.grey,
            ),
          ),
          const Text('Calendar', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget buildTopTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              selectedTab = 0;
            });
          },
          icon: const Icon(Icons.school_outlined, size: 18),
          label: const Text('Grades'),
          style: OutlinedButton.styleFrom(
            backgroundColor:
                selectedTab == 0 ? const Color(0xFFF1F4FF) : Colors.white,
            foregroundColor: const Color(0xFF334155),
            side: BorderSide(
              color: selectedTab == 0
                  ? const Color(0xFFD6DFFF)
                  : const Color(0xFFE5E7EB),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              selectedTab = 1;
            });
          },
          icon: const Icon(Icons.calendar_month_outlined, size: 18),
          label: const Text('Calendar'),
          style: OutlinedButton.styleFrom(
            backgroundColor:
                selectedTab == 1 ? const Color(0xFFF1F4FF) : Colors.white,
            foregroundColor: const Color(0xFF334155),
            side: BorderSide(
              color: selectedTab == 1
                  ? const Color(0xFFD6DFFF)
                  : const Color(0xFFE5E7EB),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildGradesPage() {
    double gpa = 0;
    if (courses.isNotEmpty) {
      gpa = courses.map((c) => c.gpa).reduce((a, b) => a + b) / courses.length;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTopTabs(),
          const SizedBox(height: 24),
          const Text(
            'Grade Estimator',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your courses and track your grades easily.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 22),
          buildAddCourseCard(),
          const SizedBox(height: 20),
          buildGpaCard(gpa),
          const SizedBox(height: 20),
          ...courses.asMap().entries.map((entry) {
            return buildCourseCard(entry.value, entry.key);
          }),
        ],
      ),
    );
  }

  Widget buildAddCourseCard() {
    return buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '+  Add a Course',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: courseNameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Introduction to Computer Science',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFD9DDF0)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: addCourse,
                icon: const Icon(Icons.add),
                label: const Text('Add Course'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C96FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildGpaCard(double gpa) {
    return buildCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.show_chart, color: Color(0xFF2142FF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Cumulative GPA\n${gpa.toStringAsFixed(2)} / 4.00',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            courses.isEmpty ? 'Enter scores to see your GPA' : '',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget buildCourseCard(Course course, int courseIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_book, color: Color(0xFF2142FF)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    course.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      course.letterGrade,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: course.passed ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      '${course.average.toStringAsFixed(1)}%',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      courses.removeAt(courseIndex);
                      
                    });
                    saveData();
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${course.components.length} components',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Component',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Score',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Weight %',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Result',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...course.components.asMap().entries.map((entry) {
              int compIndex = entry.key;
              CourseComponent c = entry.value;

              Color typeColor = Colors.blue;
              if (c.type == 'Midterm') typeColor = Colors.orange;
              if (c.type == 'Final') typeColor = Colors.red;
              if (c.type == 'Homework') typeColor = Colors.green;
              if (c.type == 'Project') typeColor = Colors.purple;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        c.type,
                        style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Text(c.score.toStringAsFixed(0))),
                    Expanded(child: Text(c.weight.toStringAsFixed(0))),
                    Expanded(
                      child: Text(
                        '${c.resultPercent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: c.resultPercent >= 60
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          course.components.removeAt(compIndex);
                        });
                        saveData();
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => showAddComponentDialog(courseIndex),
              icon: const Icon(Icons.add),
              label: const Text('Add Component'),
            ),
            const SizedBox(height: 14),
            Text(
              'Average: ${course.average.toStringAsFixed(2)}%   |   GPA: ${course.gpa.toStringAsFixed(2)} / 4.00   |   ${course.passed ? "Passed" : "Failed"}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: course.passed ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCalendarPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTopTabs(),
          const SizedBox(height: 24),
          const Text(
            'Course Calendar',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Track important dates — exams, quizzes, projects, and more.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 900) {
                return Column(
                  children: [
                    buildCalendarCard(),
                    const SizedBox(height: 20),
                    buildRightCalendarSide(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: buildCalendarCard()),
                  const SizedBox(width: 20),
                  Expanded(flex: 1, child: buildRightCalendarSide()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildCalendarCard() {
    final days = getCalendarDays(selectedMonth);
    final monthName = getMonthName(selectedMonth.month);

    return buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$monthName ${selectedMonth.year}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  setState(() {
                    selectedMonth =
                        DateTime(selectedMonth.year, selectedMonth.month - 1);
                  });
                },
                icon: const Icon(Icons.chevron_left),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    final now = DateTime.now();
                    selectedMonth = DateTime(now.year, now.month);
                    selectedDate = DateTime(now.year, now.month, now.day);
                  });
                },
                child: const Text('Today'),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    selectedMonth =
                        DateTime(selectedMonth.year, selectedMonth.month + 1);
                  });
                },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: const [
              Expanded(child: Center(child: Text('Sun', style: TextStyle(color: Colors.grey)))),
              Expanded(child: Center(child: Text('Mon', style: TextStyle(color: Colors.grey)))),
              Expanded(child: Center(child: Text('Tue', style: TextStyle(color: Colors.grey)))),
              Expanded(child: Center(child: Text('Wed', style: TextStyle(color: Colors.grey)))),
              Expanded(child: Center(child: Text('Thu', style: TextStyle(color: Colors.grey)))),
              Expanded(child: Center(child: Text('Fri', style: TextStyle(color: Colors.grey)))),
              Expanded(child: Center(child: Text('Sat', style: TextStyle(color: Colors.grey)))),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, index) {
              final day = days[index];

              if (day == null) {
                return const SizedBox.shrink();
              }

              final isSelected = isSameDate(day, selectedDate);
              final isToday = isSameDate(day, DateTime.now());
              final dayEvents = getEventsForDate(day);
              final hasEvent = dayEvents.isNotEmpty;

              return InkWell(
                onTap: () {
                  setState(() {
                    selectedDate = day;
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2142FF)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: isToday && !isSelected
                        ? Border.all(color: const Color(0xFF2142FF))
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (hasEvent)
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 4,
                          runSpacing: 4,
                          children: dayEvents.take(3).map((e) {
                            return Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : getEventColor(e.type),
                                shape: BoxShape.circle,
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildRightCalendarSide() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: showAddEventDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Event'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2142FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upcoming Events',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              buildUpcomingEventsSection(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Legend',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 18,
                runSpacing: 10,
                children: [
                  legendItem(Colors.red, 'Exam'),
                  legendItem(Colors.purple, 'Project'),
                  legendItem(Colors.grey, 'Other'),
                  legendItem(Colors.blue, 'Quiz'),
                  legendItem(Colors.green, 'Homework'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildUpcomingEventsSection() {
    final upcoming = [...events];
    upcoming.sort((a, b) => a.date.compareTo(b.date));

    if (upcoming.isEmpty) {
      return const Text(
        'No upcoming events.',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      children: upcoming.take(5).toList().asMap().entries.map((entry) {
        final index = entry.key;
        final event = entry.value;

        return Container(
          margin: EdgeInsets.only(bottom: index == 4 ? 0 : 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: getEventColor(event.type),
                child: const Icon(Icons.event, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${event.course} • ${event.date.day}/${event.date.month}/${event.date.year}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.type,
                      style: TextStyle(
                        fontSize: 12,
                        color: getEventColor(event.type),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (event.note.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.note,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  Widget legendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  List<DateTime?> getCalendarDays(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    final firstWeekday = firstDayOfMonth.weekday % 7;
    final totalDays = lastDayOfMonth.day;

    List<DateTime?> days = [];

    for (int i = 0; i < firstWeekday; i++) {
      days.add(null);
    }

    for (int day = 1; day <= totalDays; day++) {
      days.add(DateTime(month.year, month.month, day));
    }

    while (days.length % 7 != 0) {
      days.add(null);
    }

    return days;
  }

  List<StudyEvent> getEventsForDate(DateTime day) {
    return events.where((event) => isSameDate(event.date, day)).toList();
  }

  bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String getMonthName(int month) {
    const names = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month];
  }

  Color getEventColor(String type) {
    switch (type) {
      case 'Exam':
        return Colors.red;
      case 'Project':
        return Colors.purple;
      case 'Quiz':
        return Colors.blue;
      case 'Homework':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void addCourse() {
    String name = courseNameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      courses.add(
        Course(
          name: name,
          components: [],
        ),
      );
      courseNameController.clear();
    });

    saveData();
  }

  void showAddComponentDialog(int courseIndex) {
    final scoreController = TextEditingController();
    final weightController = TextEditingController();
    String selectedType = 'Quiz';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Component'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedType,
                        items: const [
                          DropdownMenuItem(value: 'Midterm', child: Text('Midterm')),
                          DropdownMenuItem(value: 'Final', child: Text('Final')),
                          DropdownMenuItem(value: 'Quiz', child: Text('Quiz')),
                          DropdownMenuItem(value: 'Homework', child: Text('Homework')),
                          DropdownMenuItem(value: 'Project', child: Text('Project')),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedType = value!;
                          });
                        },
                        decoration: const InputDecoration(labelText: 'Type'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: scoreController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Score'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Weight %'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final score = double.tryParse(scoreController.text) ?? 0;
                final weight = double.tryParse(weightController.text) ?? 0;

                setState(() {
                  courses[courseIndex].components.add(
                    CourseComponent(
                      type: selectedType,
                      score: score,
                      weight: weight,
                    ),
                  );
                });

                saveData();

                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void showAddEventDialog() {
    final titleController = TextEditingController();
    final courseController = TextEditingController();
    final noteController = TextEditingController();

    DateTime pickedDate = selectedDate;
    String selectedType = 'Exam';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('New Event'),
              content: SizedBox(
                width: 430,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Event Title *',
                          hintText: 'e.g. Midterm Exam',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: courseController,
                        decoration: const InputDecoration(
                          labelText: 'Course',
                          hintText: 'e.g. MATH 101',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Date *',
                          hintText:
                              '${pickedDate.month}/${pickedDate.day}/${pickedDate.year}',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: pickedDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2035),
                          );
                          if (date != null) {
                            setDialogState(() {
                              pickedDate = date;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: selectedType,
                        items: const [
                          DropdownMenuItem(value: 'Exam', child: Text('Exam')),
                          DropdownMenuItem(value: 'Quiz', child: Text('Quiz')),
                          DropdownMenuItem(value: 'Project', child: Text('Project')),
                          DropdownMenuItem(value: 'Homework', child: Text('Homework')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedType = value!;
                          });
                        },
                        decoration: const InputDecoration(labelText: 'Type'),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: noteController,
                        decoration: const InputDecoration(
                          labelText: 'Note (optional)',
                          hintText: 'Chapters 1-5, open book...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) return;

                    setState(() {
                      events.add(
                        StudyEvent(
                          title: titleController.text.trim(),
                          course: courseController.text.trim(),
                          date: pickedDate,
                          type: selectedType,
                          note: noteController.text.trim(),
                        ),
                      );
                      selectedDate = pickedDate;
                      selectedMonth = DateTime(pickedDate.year, pickedDate.month);
                    });

                    saveData();
                    Navigator.pop(context);
                  },
                  child: const Text('Save Event'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}