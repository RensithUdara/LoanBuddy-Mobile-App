import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/loan_model.dart';
import '../models/payment_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Singleton constructor
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  // Database getter
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'loanbuddy.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Create tables
  Future<void> _onCreate(Database db, int version) async {
    // Create Loans table
    await db.execute('''
      CREATE TABLE loans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        borrower_name TEXT NOT NULL,
        whatsapp_number TEXT NOT NULL,
        loan_amount REAL NOT NULL,
        paid_amount REAL NOT NULL DEFAULT 0,
        loan_date TEXT NOT NULL,
        due_date TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create Payments table
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        loan_id INTEGER NOT NULL,
        payment_amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (loan_id) REFERENCES loans (id) ON DELETE CASCADE
      )
    ''');
  }

  // CRUD Operations for Loans
  
  // Insert a new loan
  Future<int> insertLoan(Loan loan) async {
    Database db = await database;
    return await db.insert('loans', loan.toMap());
  }

  // Get all loans
  Future<List<Loan>> getLoans({String? status}) async {
    Database db = await database;
    
    List<Map<String, dynamic>> maps;
    
    if (status != null) {
      maps = await db.query(
        'loans',
        where: 'status = ?',
        whereArgs: [status],
        orderBy: 'due_date ASC',
      );
    } else {
      maps = await db.query('loans', orderBy: 'due_date ASC');
    }
    
    return List.generate(maps.length, (i) {
      return Loan.fromMap(maps[i]);
    });
  }

  // Get a single loan by ID
  Future<Loan?> getLoan(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'loans',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Loan.fromMap(maps.first);
    }
    return null;
  }

  // Update loan
  Future<int> updateLoan(Loan loan) async {
    Database db = await database;
    return await db.update(
      'loans',
      loan.toMap(),
      where: 'id = ?',
      whereArgs: [loan.id],
    );
  }

  // Delete loan
  Future<int> deleteLoan(int id) async {
    Database db = await database;
    
    // Delete associated payments first
    await db.delete(
      'payments',
      where: 'loan_id = ?',
      whereArgs: [id],
    );
    
    // Then delete the loan
    return await db.delete(
      'loans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get total loans amount
  Future<double> getTotalLoanAmount() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT SUM(loan_amount) as total FROM loans WHERE status = ?',
      [LoanStatus.active.name],
    );
    return result.first['total'] ?? 0.0;
  }

  // Get total outstanding amount
  Future<double> getTotalOutstandingAmount() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT SUM(loan_amount - paid_amount) as total FROM loans WHERE status = ?',
      [LoanStatus.active.name],
    );
    return result.first['total'] ?? 0.0;
  }

  // CRUD Operations for Payments

  // Insert a new payment
  Future<int> insertPayment(Payment payment) async {
    Database db = await database;
    
    // Begin a transaction
    return await db.transaction((txn) async {
      // Insert the payment
      int paymentId = await txn.insert('payments', payment.toMap());
      
      // Update the loan's paid amount
      await txn.rawUpdate('''
        UPDATE loans 
        SET paid_amount = paid_amount + ?, 
            updated_at = ?,
            status = CASE 
                      WHEN (paid_amount + ?) >= loan_amount 
                      THEN ? 
                      ELSE status 
                    END
        WHERE id = ?
      ''', [
        payment.paymentAmount,
        DateTime.now().toString(),
        payment.paymentAmount,
        LoanStatus.completed.name,
        payment.loanId
      ]);
      
      return paymentId;
    });
  }

  // Get payments for a specific loan
  Future<List<Payment>> getPaymentsForLoan(int loanId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'loan_id = ?',
      whereArgs: [loanId],
      orderBy: 'payment_date DESC',
    );

    return List.generate(maps.length, (i) {
      return Payment.fromMap(maps[i]);
    });
  }

  // Delete payment
  Future<int> deletePayment(int id, int loanId, double amount) async {
    Database db = await database;
    
    // Begin a transaction
    return await db.transaction((txn) async {
      // Delete the payment
      int result = await txn.delete(
        'payments',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      // Update the loan's paid amount
      await txn.rawUpdate('''
        UPDATE loans 
        SET paid_amount = paid_amount - ?,
            updated_at = ?,
            status = ? 
        WHERE id = ?
      ''', [
        amount,
        DateTime.now().toString(),
        LoanStatus.active.name,
        loanId
      ]);
      
      return result;
    });
  }
}