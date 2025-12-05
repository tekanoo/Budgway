# Budgway - Professional Budget Management

A professional and intuitive budget management application developed with Flutter and Firebase.

**Live App:** [https://budgway.com/](https://budgway.com/)

## Features

- **Financial Tracking**: Complete management of income, fixed charges, and expenses.
- **Dashboard**: Clear visualization of your current financial status.
- **Analytics & Charts**: Interactive charts to track budget evolution (powered by fl_chart).
- **Authentication**: Secure login via Firebase Auth.
- **Cloud Storage**: Real-time data synchronization with Cloud Firestore.
- **Cross-Platform**: Compatible with Web, Android, and iOS.

## Technologies

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Auth, Firestore, Hosting)
- **State Management**: Provider
- **Charts**: FL Chart

## Installation

1. Clone the repository:
   `ash
   git clone https://github.com/tekanoo/BudgetApp.git
   `

2. Install dependencies:
   `ash
   flutter pub get
   `

3. Configure Firebase:
   - Ensure you have the Firebase CLI installed.
   - Run lutterfire configure to link your Firebase project.

4. Run the application:
   `ash
   flutter run
   `

## Security

This project is configured to not expose sensitive data. Firebase configuration files (firebase_options.dart, google-services.json) are ignored by Git.

## Author

Personal financial management project.
