import 'dart:math';
import 'package:flutter/material.dart';

class MathChallengeScreen extends StatefulWidget {
  final VoidCallback onSuccess;

  const MathChallengeScreen({required this.onSuccess, Key? key}) : super(key: key);

  @override
  _MathChallengeScreenState createState() => _MathChallengeScreenState();
}

class _MathChallengeScreenState extends State<MathChallengeScreen> {
  late int num1;
  late int num2;
  String answer = '';
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    generateProblem();
  }

  void generateProblem() {
    final random = Random();
    setState(() {
      num1 = 10 + random.nextInt(31);  
      num2 = 10 + random.nextInt(31); 
    });
  }

  void checkAnswer() {
    if (int.tryParse(answer) == num1 + num2) {
      widget.onSuccess();
      Navigator.pop(context); 
    } else {
      setState(() {
        errorMessage = 'Incorrect answer. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Math Challenge')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$num1 + $num2 = ?', style: Theme.of(context).textTheme.headlineMedium),
            SizedBox(height: 10,),
            TextField(
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  answer = value;
                });
              },
            ),
             SizedBox(height: 10,),
            if (errorMessage.isNotEmpty)
              Text(errorMessage, style: const TextStyle(color: Colors.red)),
               SizedBox(height: 10,),
            ElevatedButton(
              onPressed: checkAnswer,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
