# LoanBuddy Mobile App

<p align="center">
  <!-- Replace with actual logo when available -->
  <!-- <img src="assets/logo.png" alt="LoanBuddy Logo" width="200"/> -->
</p>

> A comprehensive personal loan management application for tracking, managing, and organizing your personal loans.

## 📱 Overview

LoanBuddy is a Flutter-based mobile application designed to help individuals manage personal loans they've given to others. It provides an intuitive interface to track borrowers, loan amounts, due dates, and payment histories, along with features like custom reminders, data export/import, and analytics dashboards.

## ✨ Features

### Core Features
- **Loan Management**: Create, edit, and delete loans with borrower details
- **Payment Tracking**: Record and manage payments for each loan
- **Dashboard**: Get a quick overview of active loans, overdue loans, and upcoming payments
- **WhatsApp Integration**: Quickly contact borrowers through WhatsApp

### Advanced Features
- **Export/Import Data**: Backup and restore your loan data using CSV files
- **Analytics Dashboard**: Visualize your loan data with charts and statistics
- **Custom Reminders**: Set personalized notification schedules for loan due dates

## 📸 Screenshots

<p align="center">
  <!-- Add actual screenshots when available -->
  <!-- 
  <img src="screenshots/dashboard.png" width="200" alt="Dashboard Screen"/>
  <img src="screenshots/loan_details.png" width="200" alt="Loan Details Screen"/>
  <img src="screenshots/analytics.png" width="200" alt="Analytics Dashboard"/>
  <img src="screenshots/reminders.png" width="200" alt="Custom Reminders"/>
  -->
</p>

## 🛠️ Installation

### Prerequisites
- Flutter 3.5.0 or higher
- Dart 3.5.3 or higher
- Android SDK or iOS development tools

### Setup
1. Clone the repository:
   ```
   git clone https://github.com/RensithUdara/LoanBuddy-Mobile-App.git
   ```

2. Navigate to the project directory:
   ```
   cd loanbuddy_mobile_app
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

4. Run the application:
   ```
   flutter run
   ```

## 🧰 Technologies Used

- **Flutter**: UI framework for cross-platform development
- **Provider**: State management
- **SQLite**: Local database for storing loan and payment data
- **FL Chart**: Data visualization for analytics
- **CSV**: Data import/export functionality
- **Flutter Local Notifications**: Custom reminder scheduling
- **Path Provider & File Picker**: File system operations for data backup

## 🔍 Project Structure

```
lib/
├── controllers/       # State management providers
├── models/            # Data models
├── services/          # Business logic and external services
├── utils/             # Helper functions and constants
└── views/             # UI components
    ├── screens/       # Full-screen views
    └── widgets/       # Reusable UI components
```

## 📊 Data Management

LoanBuddy uses SQLite for local data storage. The database schema includes:

- **Loans Table**: Stores loan information including borrower details, amounts, and dates
- **Payments Table**: Records all payments with references to associated loans

Data can be exported to CSV files and reimported, allowing for backup and transfer between devices.

## 🚀 Getting Started

1. After launching the app, you'll see the dashboard with an overview of your loans.
2. Tap the "+" button to add a new loan with borrower details and loan terms.
3. For each loan, you can add payments, edit details, or mark it as completed.
4. Use the drawer menu to access advanced features like Analytics and Export/Import.

## 🔄 Roadmap

- [ ] Multi-currency support
- [ ] Cloud synchronization across devices
- [ ] Borrower profiles with history
- [ ] Interest calculation based on different models
- [ ] Document attachment for loan agreements

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` file for more information.

## 👤 Contact

Rensith Udara - [@rensith](https://twitter.com/rensith) - rensith@example.com

Project Link: [https://github.com/RensithUdara/LoanBuddy-Mobile-App](https://github.com/RensithUdara/LoanBuddy-Mobile-App)

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/RensithUdara">Rensith Udara</a>
</p>
