import 'package:sqflite/sqflite.dart';
import 'package:taqo_client/model/event.dart';
import 'package:taqo_client/storage/local_storage.dart';

part 'local_database.inc.dart';

/// Global reference of the database connection, using singleton pattern
class LocalDatabase extends LocalFileStorage {
  /// Singleton implementation

  /// The private constructor
  LocalDatabase._(): super(dbFilename) {
    _init();
  }

  static final LocalDatabase _instance = LocalDatabase._();

  factory LocalDatabase() {
    return _instance;
  }

  /// Actual content of the class
  static const dbFilename = 'experiments.db';
  Future<Database> _db;

  /// The actual initializer, which should only be called from the private constructor
  void _init() {
    _db = _openDatabase();
  }

  Future<Database> _openDatabase() async {
    return await openDatabase((await localFile).path, version: _dbVersion, onCreate: _onCreate);
  }

  Future<void> insertEvent(Event event) async {
    final db = await _db;
    await _insertEvent(db, event);
  }
}
