import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error
import pickle
df = pd.read_csv('cibil_data.csv')
df['CREDITCARD'] = df['CREDITCARD'].apply(lambda x: 1 if x == 'YES' else 0)
df['LATEPAYMENT'] = df['LATEPAYMENT'].apply(lambda x: 1 if x == 'YES' else 0)
df = pd.get_dummies(df, columns=['LOANTYPE'])
X = df[['SANCTIONEDAMOUNT', 'CURRENTAMOUNT', 'CREDITCARD', 'LATEPAYMENT', 
         'LOANTYPE_PERSONAL LOAN', 'LOANTYPE_GOLD LOAN', 
         'LOANTYPE_CONSUMER LOAN']]
y = df['CIBIL']
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
model = RandomForestRegressor(n_estimators=100, random_state=42)
model.fit(X_train, y_train)
y_pred = model.predict(X_test)
mse = mean_squared_error(y_test, y_pred)
print(f"Model Mean Squared Error: {mse}")
with open('cibil_predictor_model.pkl', 'wb') as f:
    pickle.dump(model, f)
print("Model trained and saved successfully.")