import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class LocalDbService {
  static Database? _database;

  Future<Database> get database async {
    if (kIsWeb) throw UnsupportedError('Local database is not supported on web.');
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'vasool_drive_local.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await _createDb(db);
        await _createCustomerTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS auth_local');
          await _createDb(db);
        }
        if (oldVersion < 3) {
          await _createCustomerTables(db);
        }
      },
    );
  }

  Future<void> _createDb(Database db) async {
    await db.execute('''
      CREATE TABLE auth_local (
        name TEXT PRIMARY KEY,
        pin_hash TEXT,
        access_token TEXT,
        role TEXT,
        is_active INTEGER DEFAULT 1,
        is_locked INTEGER DEFAULT 0,
        last_sync TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<void> _createCustomerTables(Database db) async {
    await db.execute('''
      CREATE TABLE customers (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        customer_id TEXT,
        name TEXT NOT NULL,
        mobile_number TEXT NOT NULL,
        address TEXT,
        area TEXT,
        assigned_worker_id INTEGER,
        status TEXT DEFAULT 'active',
        is_synced INTEGER DEFAULT 0, 
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  // ... (keep _hashPin) ...
  // Hash PIN locally before storing or comparing (SHA-256 for local simplicity)
  String _hashPin(String pin) {
    var bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  // ... (keep saveUserLocally, verifyPinOffline, getLastUser, getLocalUser) ...
  Future<void> saveUserLocally({
    required String name,
    required String pin,
    String? token,
    String? role,
    bool? isActive,
    bool? isLocked,
  }) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert(
      'auth_local',
      {
        'name': name,
        'pin_hash': _hashPin(pin),
        'access_token': token,
        'role': role,
        'is_active': (isActive ?? true) ? 1 : 0,
        'is_locked': (isLocked ?? false) ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> verifyPinOffline(String name, String pin) async {
    if (kIsWeb) return 'web_offline_unavailable'; 
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'auth_local',
      where: 'name = ?',
      whereArgs: [name],
    );

    if (maps.isEmpty) return 'user_not_found';
    
    final user = maps.first;
    if (user['is_active'] == 0) return 'user_inactive';
    if (user['is_locked'] == 1) return 'account_locked';

    String storedHash = user['pin_hash'];
    if (storedHash == _hashPin(pin)) {
      return null; // Success
    }
    return 'invalid_pin';
  }

  Future<Map<String, dynamic>?> getLastUser() async {
    if (kIsWeb) return null;
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'auth_local',
      limit: 1,
      orderBy: 'name DESC', 
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getLocalUser(String name) async {
    if (kIsWeb) return null;
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'auth_local',
      where: 'name = ?',
      whereArgs: [name],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // --- Customer Methods ---

  Future<int> addCustomerLocally(Map<String, dynamic> customerData) async {
    if (kIsWeb) return 0;
    final db = await database;
    print('=== LOCAL DB: Adding customer ===');
    print('Customer data: $customerData');
    
    final id = await db.insert('customers', {
      'name': customerData['name'],
      'mobile_number': customerData['mobile_number'],
      'address': customerData['address'],
      'area': customerData['area'],
      'id_proof_number': customerData['id_proof_number'],
      'profile_image': customerData['profile_image'],
      'latitude': customerData['latitude'],
      'longitude': customerData['longitude'],
      'status': customerData['status'] ?? 'created',
      'created_at': customerData['created_at'] ?? DateTime.now().toIso8601String(),
      'is_synced': 0, // Not synced yet
      'server_id': null,
      'customer_id': null,
    });
    
    print('Customer saved with local ID: $id');
    return id;
  }

  Future<List<Map<String, dynamic>>> getPendingCustomers() async {
    if (kIsWeb) return [];
    final db = await database;
    print('=== LOCAL DB: Getting pending customers ===');
    
    final results = await db.query(
      'customers',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    
    print('Found ${results.length} pending customers in local DB');
    print('Raw results: $results');
    
    // Convert to format expected by API (include local_id as string key)
    final List<Map<String, dynamic>> pendingList = [];
    for (var row in results) {
      final Map<String, dynamic> customer = Map.from(row);
      // Use 'local_id' column (defined in schema line 55)
      customer['local_id'] = row['local_id'].toString(); // API expects local_id as string  
      print('Pending customer: ${customer['name']}, local_id: ${customer['local_id']}, mobile: ${customer['mobile_number']}');
      pendingList.add(customer);
    }
    
    return pendingList;
  }

  Future<void> updateCustomerSyncStatus(int localId, int serverId, String customerId) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update(
      'customers',
      {
        'server_id': serverId,
        'customer_id': customerId,
        'is_synced': 1
      },
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }
  
  Future<List<Map<String, dynamic>>> getAllLocalCustomers() async {
    if (kIsWeb) return [];
    final db = await database;
    return await db.query('customers', orderBy: 'created_at DESC');
  }
}
