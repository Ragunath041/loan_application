import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoanPage extends StatefulWidget {
  final String userPanNumber;
  final int currentCibilScore;

  const LoanPage({super.key, required this.userPanNumber, required this.currentCibilScore});

  @override
  _LoanPageState createState() => _LoanPageState();
}

class _LoanPageState extends State<LoanPage> {
  final TextEditingController _loanAmountController = TextEditingController();
  final TextEditingController _loanDurationController = TextEditingController();
  final TextEditingController _monthlyIncomeController = TextEditingController();
  final TextEditingController _interestRateController = TextEditingController();
  final TextEditingController _monthsPaidCorrectlyController = TextEditingController();
  final TextEditingController _latePaymentsController = TextEditingController();

  int? _predictedScore;
  int? _futureCibilScore;
  bool _showFutureCibilInputs = false;
  bool _displayFinalScores = false;

  Future<void> _predictCibil() async {
    final requestBody = {
      'current_score': widget.currentCibilScore,
      'loan_amount': int.parse(_loanAmountController.text),
      'loan_duration': int.parse(_loanDurationController.text),
      'monthly_income': int.parse(_monthlyIncomeController.text),
      'pan': widget.userPanNumber,
    };
    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/predict'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestBody),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _predictedScore = data['predicted_score'];
        _showFutureCibilInputs = true;
      });
    }
  }

  Future<void> _calculateFutureCibil() async {
    final requestBody = {
      'predicted_score': _predictedScore,
      'interest_rate': double.parse(_interestRateController.text),
      'months_paid_correctly': int.parse(_monthsPaidCorrectlyController.text),
      'late_payments': int.parse(_latePaymentsController.text),
      'pan': widget.userPanNumber,
    };
    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/calculate_future_cibil'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestBody),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _futureCibilScore = data['future_cibil_score'];
        _displayFinalScores = true;  // Only show scores now
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Loan Prediction',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),

              if (!_displayFinalScores && !_showFutureCibilInputs) ...[
                _buildTextField(_loanAmountController, 'Loan Amount'),
                _buildTextField(_loanDurationController, 'Loan Duration (months)'),
                _buildTextField(_monthlyIncomeController, 'Monthly Income'),
                const SizedBox(height: 20),
                _buildActionButton('Predict CIBIL Score', _predictCibil),
              ],

              if (_predictedScore != null && !_showFutureCibilInputs) ...[
                const SizedBox(height: 20),
                _buildScoreSection('Predicted CIBIL Score', _predictedScore!),
                const SizedBox(height: 25),
                _buildActionButton('Calculate Future CIBIL Score', () {
                  setState(() {
                    _showFutureCibilInputs = true;
                  });
                }),
              ],

              if (_showFutureCibilInputs && !_displayFinalScores) ...[
                const SizedBox(height: 20),
                _buildTextField(_interestRateController, 'Interest Rate (%)'),
                _buildTextField(_monthsPaidCorrectlyController, 'Months Paid Correctly'),
                _buildTextField(_latePaymentsController, 'Late Payments'),
                const SizedBox(height: 20),
                _buildActionButton('Calculate Future CIBIL Score', _calculateFutureCibil),
              ],

              if (_displayFinalScores) ...[
                _buildScoreSection('Predicted CIBIL Score', _predictedScore!),
                const SizedBox(height: 15),
                _buildScoreSection('  Future CIBIL Score   ', _futureCibilScore!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white),
          filled: true,
          fillColor: Colors.grey[850],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: Colors.blue),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreSection(String title, int score) {
    return Container(
      padding: const EdgeInsets.all(15.0),
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.blue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(
            '$score',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        primary: Colors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}
