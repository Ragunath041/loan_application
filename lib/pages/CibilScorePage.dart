import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:loan_application/pages/LoanPage.dart';

class CibilScorePage extends StatefulWidget {
  const CibilScorePage({super.key});

  @override
  _CibilScorePageState createState() => _CibilScorePageState();
}

class _CibilScorePageState extends State<CibilScorePage> {
  String panNumber = '';
  Map<String, dynamic>? cibilData;

  Future<void> fetchCibilData() async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/get_cibil'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"pan": panNumber}),
    );

    if (response.statusCode == 200) {
      setState(() {
        cibilData = json.decode(response.body)['data'];
      });
    } else {
      print("Error fetching data: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("CIBIL Score" , style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Enter PAN Number',
                labelStyle: TextStyle(color: Colors.white),
                filled: true,
                fillColor: Colors.white24,
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                panNumber = value;
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: fetchCibilData,
              style: ElevatedButton.styleFrom(
                primary: Colors.blue,
                onPrimary: Colors.white,
              ),
              child: const Text('Fetch CIBIL data'),
            ),
            const SizedBox(height: 20),
            if (cibilData != null) buildCibilDetails(),
          ],
        ),
      ),
    );
  }

  Widget buildCibilDetails() {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(top: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.blueAccent, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CIBIL Score Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            const Divider(color: Colors.blueAccent),
            detailRow('Name', cibilData!['name']),
            detailRow('PAN', cibilData!['pan']),
            detailRow('CIBIL Score', cibilData!['cibil'].toString()),
            detailRow('DOB', cibilData!['dob']),
            const SizedBox(height: 20),

            const Text('Loan Details:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
           const Divider(color: Colors.blueAccent),
            if (cibilData!['loanDetails']['personalLoan'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: loanDetailRow(
                  'Personal Loan',
                  'Sanctioned: ${cibilData!['loanDetails']['personalLoan']['sanctionedAmount']}',
                  'Current: ${cibilData!['loanDetails']['personalLoan']['currentAmount']}',
                ),
              ),
            if (cibilData!['loanDetails']['goldLoans'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.blueAccent),
                  const Text(
                    'Gold Loans',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  ...cibilData!['loanDetails']['goldLoans'].map((loan) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: loanDetailRow(
                        'Gold Loan',
                        'Sanctioned: ${loan['sanctionedAmount']}',
                        'Current: ${loan['currentAmount']}',
                      ),
                    );
                  }).toList(),
                ],
              ),
            if (cibilData!['loanDetails']['consumerLoans'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.blueAccent),
                  const Text(
                    'Consumer Loans',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  ...cibilData!['loanDetails']['consumerLoans'].map((loan) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: loanDetailRow(
                        'Consumer Loan',
                        'Sanctioned: ${loan['sanctionedAmount']}',
                        'Current: ${loan['currentAmount']}',
                      ),
                    );
                  }).toList(),
                ],
              ),

            detailRow('Credit Card', cibilData!['loanDetails']['creditCard']),
            detailRow('Late Payments', cibilData!['loanDetails']['latePayments'].toString()),
            const SizedBox(height: 20),
            
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _showPredictionOptions(context);
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue,
                  onPrimary: Colors.white,
                ),
                child: const Text("Predict CIBIL"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget loanDetailRow(String title, String sanctioned, String current) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(
              '$sanctioned | $current',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showPredictionOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose an Option'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Loan'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => LoanPage(
                        userPanNumber: panNumber,
                        currentCibilScore: cibilData!['cibil'],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
