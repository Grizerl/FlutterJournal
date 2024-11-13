import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_journal/widgets/sign_in_screen.dart';

class Grade {
  final String id;
  final String subject;
  final String date;
  final String score;

  Grade(this.id, this.subject, this.date, this.score);
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Grade> grades = [];
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _scoreController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String? _selectedDate;
  bool _isDescending = true;

  @override
  void initState() {
    super.initState();
    _fetchGrades();
  }

  Future<void> _fetchGrades() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('grades')
          .where('userId', isEqualTo: user.uid)
          .get();

      setState(() {
        grades = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Grade(doc.id, data['subject'], data['date'], data['score']);
        }).toList();
        _sortGrades();
      });
    }
  }

  void _sortGrades() {
    grades.sort((a, b) => _isDescending
        ? b.date.compareTo(a.date)
        : a.date.compareTo(b.date));
  }

  Future<void> _addGrade() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (_subjectController.text.isNotEmpty &&
          _scoreController.text.isNotEmpty &&
          _selectedDate != null) {
        final newGrade = Grade(
          '',
          _subjectController.text,
          _selectedDate!,
          _scoreController.text,
        );

        try {
          final docRef = await FirebaseFirestore.instance.collection('grades').add({
            'subject': newGrade.subject,
            'date': newGrade.date,
            'score': newGrade.score,
            'userId': user.uid,
          });

          setState(() {
            grades.add(Grade(docRef.id, newGrade.subject, newGrade.date, newGrade.score));
            _sortGrades();
            _subjectController.clear();
            _scoreController.clear();
            _selectedDate = null;
            _dateController.clear();
          });
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding grade: $e')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields')));
      }
    }
  }

  void _toggleSortOrder() {
    setState(() {
      _isDescending = !_isDescending;
      _sortGrades();
    });
  }

  void _menuOpen(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Grades History'),
                onTap: () => Navigator.of(context).pop(),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Log Out'),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const SignInScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Remove Account',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  try {
                    User? user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      // Delete grades before deleting the user account
                      final gradesSnapshot = await FirebaseFirestore.instance
                          .collection('grades')
                          .where('userId', isEqualTo: user.uid)
                          .get();
                      for (var gradeDoc in gradesSnapshot.docs) {
                        await FirebaseFirestore.instance
                            .collection('grades')
                            .doc(gradeDoc.id)
                            .delete();
                      }

                      // Now delete the user account
                      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
                      await user.delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Account and grades deleted')),
                      );

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SignInScreen()),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No user is logged in')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectDate(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (selectedDate != null && selectedDate != _selectedDate) {
      setState(() {
        _selectedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
        _dateController.text = _selectedDate ?? "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(_isDescending ? Icons.arrow_downward : Icons.arrow_upward, color: Colors.white),
          onPressed: _toggleSortOrder,
        ),
        title: const Text("Grades Overview", style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.orange[900],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(15),
            bottomRight: Radius.circular(15),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_open),
            color: Colors.white,
            onPressed: () => _menuOpen(context),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: grades.length,
        itemBuilder: (BuildContext context, int index) {
          return Dismissible(
            key: Key(grades[index].id),
            background: Container(color: Colors.red),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) async {
              await FirebaseFirestore.instance.collection('grades').doc(grades[index].id).delete();
              setState(() {
                grades.removeAt(index);
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${grades[index].subject} deleted')));
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                title: Text(grades[index].subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date: ${grades[index].date}'),
                    Text('Rating: ${grades[index].score}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.deepOrange),
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('grades').doc(grades[index].id).delete();
                    setState(() {
                      grades.removeAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${grades[index].subject} deleted')));
                  },
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange[900],
        foregroundColor: Colors.white,
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: Colors.grey[850],
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create Estimate',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _subjectController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        labelStyle: TextStyle(color: Colors.white),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _scoreController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Rating',
                        labelStyle: TextStyle(color: Colors.white),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                        ),
                      ),
                      keyboardType: TextInputType.number,

                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _dateController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        labelStyle: TextStyle(color: Colors.white),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                        ),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _addGrade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[900],
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 32,
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}