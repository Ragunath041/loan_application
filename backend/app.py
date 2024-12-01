from flask import Flask, request, jsonify
from flask_cors import CORS
import psycopg2
import pandas as pd
import pickle
import numpy as np
app = Flask(__name__)
CORS(app)
try:
    conn = psycopg2.connect(
        dbname="loan_scope",
        user="postgres",
        password="root",
        host="localhost",
        port="5432"
    )
    print("Database connected successfully.")
except Exception as e:
    print(f"Database connection error: {e}")
csv_file = 'cibil_data.csv'
cibil_data = pd.read_csv(csv_file)
with open('cibil_predictor_model.pkl', 'rb') as f:
    model = pickle.load(f)
@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    username = data.get('username')
    email = data.get('email')
    password = data.get('password')
    try:
        with conn.cursor() as cursor:
            cursor.execute(""" 
                INSERT INTO users (username, email, password)
                VALUES (%s, %s, %s);
            """, (username, email, password))
            conn.commit()
        return jsonify({"message": "Registration successful"}), 201
    except Exception as e:
        conn.rollback()
        print(f"Error during registration: {e}")
        return jsonify({"message": "An error occurred during registration. Please try again."}), 500
@app.route('/get_cibil', methods=['POST'])
def get_cibil():
    data = request.get_json()  # Get the JSON data from the request
    pan_number = data.get('pan')  # Extract the PAN number from the data

    cibil_data_result = get_cibil_data(pan_number)

    if cibil_data_result:
        return jsonify({
            "message": "Data found",
            "data": cibil_data_result
        }), 200
    else:
        return jsonify({"message": "PAN number not found"}), 404

def get_cibil_data(pan_number):
    # Access the cibil_data dataframe to fetch the user info based on the PAN number
    result = cibil_data[cibil_data['PAN'] == pan_number]
    if not result.empty:
        user_info = result.iloc[0]
        loans = result[result['PAN'] == pan_number]
        loan_details = {
            'personalLoan': None,
            'goldLoans': [],
            'consumerLoans': [],
            'creditCard': user_info['CREDITCARD'],
            'latePayments': user_info['LATEPAYMENT']
        }
        for _, loan in loans.iterrows():
            loan_type = loan['LOANTYPE']
            loan_detail = {
                'sanctionedAmount': loan['SANCTIONEDAMOUNT'],
                'currentAmount': loan['CURRENTAMOUNT']
            }
            if loan_type == 'PERSONAL LOAN':
                loan_details['personalLoan'] = loan_detail
            elif loan_type == 'GOLD LOAN':
                loan_details['goldLoans'].append(loan_detail)
            elif loan_type == 'CONSUMER LOAN':
                loan_details['consumerLoans'].append(loan_detail)

        return {
            'name': user_info['Name'],
            'pan': user_info['PAN'],
            'cibil': int(user_info['CIBIL']),
            'dob': user_info['DOB'],
            'loanDetails': loan_details
        }
    return None


@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')
    try:
        with conn.cursor() as cursor:
            cursor.execute(""" 
                SELECT * FROM users WHERE username = %s AND password = %s;
            """, (username, password))
            user = cursor.fetchone()
            if user:
                return jsonify({"message": "Login successful"}), 200
            else:
                return jsonify({"message": "Invalid username or password"}), 401
    except Exception as e:
        print(f"Error during login: {e}")
        return jsonify({"message": "An error occurred during login. Please try again."}), 500
@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json()
    loan_amount = data.get('loan_amount')
    loan_duration = data.get('loan_duration')
    pan_number = data.get('pan')  # Get PAN number from request
    user_data = get_cibil_data(pan_number)
    if not user_data:
        return jsonify({"message": "PAN number not found"}), 404
    features = np.array([
        loan_amount,
        loan_duration,
        1 if user_data['loanDetails']['creditCard'] == 'YES' else 0,
        1 if user_data['loanDetails']['latePayments'] == 'YES' else 0,
        1 if user_data['loanDetails']['personalLoan'] else 0,
        len(user_data['loanDetails']['goldLoans']),  # Number of gold loans
        len(user_data['loanDetails']['consumerLoans'])  # Number of consumer loans
    ]).reshape(1, -1)
    predicted_score = model.predict(features)[0]
    def calculate_initial_drop(user_data):
        drop = 0
        if len(user_data['loanDetails']['goldLoans']) == 0 and len(user_data['loanDetails']['consumerLoans']) == 0 and user_data['loanDetails']['creditCard'] == 'NO':
            drop = 20  # No loans, no credit cards, no late payments
        elif user_data['loanDetails']['latePayments'] == 'YES':
            drop = 40  # Late payments present
        elif len(user_data['loanDetails']['goldLoans']) > 0 or len(user_data['loanDetails']['consumerLoans']) > 0:
            if user_data['loanDetails']['latePayments'] == 'NO':
                drop = 30  # Loans without late payments
            else:
                drop = 35  # Loans with late payments
        elif user_data['loanDetails']['creditCard'] == 'YES':
            if user_data['loanDetails']['latePayments'] == 'YES':
                drop = 35  # Credit card with late payments
            else:
                drop = 25  # Credit card without late payments
        return drop
    initial_drop = calculate_initial_drop(user_data)
    predicted_score -= initial_drop
    return jsonify({'predicted_score': int(predicted_score)})
@app.route('/calculate_future_cibil', methods=['POST'])
def calculate_future_cibil():
    data = request.get_json()
    predicted_score = data.get('predicted_score')
    interest_rate = data.get('interest_rate')
    months_paid_correctly = data.get('months_paid_correctly')
    late_payments = data.get('late_payments')
    future_score_increase = months_paid_correctly * 5  # Each correct payment increases score
    future_score_drop = late_payments * 10  # Each late payment drops score
    future_cibil_score = predicted_score + future_score_increase - future_score_drop
    return jsonify({'future_cibil_score': future_cibil_score})
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
    # app.run()