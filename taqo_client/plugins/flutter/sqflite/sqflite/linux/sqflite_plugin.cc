// Copyright 2018 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
#include <mutex>

#include <pwd.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

#include <sqlite3.h>

#include "plugins/flutter/sqflite/sqflite/linux/sqflite_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar.h>
#include <flutter/standard_method_codec.h>

// Shared
const char SqfliteParamSql[] = "sql";
const char SqfliteParamSqlArguments[] = "arguments";
const char SqfliteParamInTransaction[] = "inTransaction"; // true, false or null
const char SqfliteParamNoResult[] = "noResult";
const char SqfliteParamContinueOnError[] = "continueOnError";
const char SqfliteParamMethod[] = "method";
// For each operation in a batch, we have either a result or an error
const char SqfliteParamResult[] = "result";
const char SqfliteParamError[] = "error";
const char SqfliteParamErrorCode[] = "code";
const char SqfliteParamErrorMessage[] = "message";
const char SqfliteParamErrorData[] = "data";

namespace sqflite_plugin {

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

// See channel_controller.dart for documentation.
const char kChannelName[] = "com.tekartik.sqflite";
const char kInMemoryPath[] = ":memory:";

const char kMethodGetPlatformVersion[] = "getPlatformVersion";
const char kMethodGetDatabasesPath[] = "getDatabasesPath";
const char kMethodDebugMode[] = "debugMode";
const char kMethodDebug[] = "debug";
const char kMethodOptions[] = "options";
const char kMethodOpenDatabase[] = "openDatabase";
const char kMethodCloseDatabase[] = "closeDatabase";
const char kMethodDeleteDatabase[] = "deleteDatabase";
const char kMethodExecute[] = "execute";
const char kMethodInsert[] = "insert";
const char kMethodUpdate[] = "update";
const char kMethodQuery[] = "query";
const char kMethodBatch[] = "batch";

// For open
const char kParamReadOnly[] = "readOnly";
const char kParamSingleInstance[] = "singleInstance";
// Open result
const char kParamRecovered[] = "recovered";
const char kParamRecoveredInTransaction[] = "recoveredInTransaction";

// For batch
const char kParamOperations[] = "operations";
// For each batch operation
const char kParamPath[] = "path";
const char kParamId[] = "id";
//const char kParamTable[] = "table";
//const char kParamValues[] = "values";

//const char kSqliteErrorCode[] = "sqlite_error";
//const char kErrorBadParam[] = "bad_param"; // internal only
//const char kErrorOpenFailed[] = "open_failed";
//const char kErrorDatabaseClosed[] = "database_closed";

// options
const char kParamQueryAsMapList[] = "queryAsMapList";

// debug
//const char kParamDatabases[] = "databases";
const char kParamLogLevel[] = "logLevel";
//const char kParamCmd[] = "cmd";
//const char kParamCmdGet[] = "get";

const int logLevelNone = 0;
const int logLevelSql = 1;
const int logLevelVerbose = 2;
int logLevel = logLevelNone;

// True for basic debugging (open/close and sql)
bool hasSqlLogLevel(int logLevel) {
  return logLevel >= logLevelSql;
}

// True for verbose debugging
bool hasVerboseLogLevel(int logLevel) {
  return logLevel >= logLevelVerbose;
}

//bool _extra_log = false;
//bool __extra_log = false; // to set to true for type debugging

class SqfliteDatabase {
  public:
    SqfliteDatabase() {}
    SqfliteDatabase(const SqfliteDatabase &db) {
      databaseId = db.databaseId;
      path = std::string(db.path);
      singleInstance = db.singleInstance;
      inTransaction = db.inTransaction;
      logLevel = db.logLevel;
    }

    int databaseId;
    std::string path;
    bool singleInstance;
    bool inTransaction;
    int logLevel;
};

std::map<int, SqfliteDatabase> databaseMap;
std::map<std::string, SqfliteDatabase> singleInstanceDatabaseMap;
std::mutex mapLock;
int databaseOpenCount = 0;
int lastDatabaseId = 0;

bool queryAsMapList = false;

}  // namespace

class SqflitePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrar *registrar);

  virtual ~SqflitePlugin();

 private:
  // Creates a plugin that communicates on the given channel.
  SqflitePlugin(std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel);

  // Called when a method is called on |channel_|;
  void HandleMethodCall(
      const flutter::MethodCall<EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<EncodableValue>> result);

  // The MethodChannel used for communication with the Flutter engine.
  std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel_;
};

// static
void SqflitePlugin::RegisterWithRegistrar(flutter::PluginRegistrar *registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      registrar->messenger(), kChannelName,
      &flutter::StandardMethodCodec::GetInstance());
  auto *channel_pointer = channel.get();

  // Uses new instead of make_unique due to private constructor.
  std::unique_ptr<SqflitePlugin> plugin(new SqflitePlugin(std::move(channel)));

  channel_pointer->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });
  registrar->EnableInputBlockingForChannel(kChannelName);

  registrar->AddPlugin(std::move(plugin));
}

SqflitePlugin::SqflitePlugin(std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel)
    : channel_(std::move(channel)) {}

SqflitePlugin::~SqflitePlugin() {}

std::unique_ptr<SqfliteDatabase> getDatabase(const flutter::MethodCall<EncodableValue> &method_call) {
  EncodableMap args(method_call.arguments()->MapValue());
  int databaseId = args[EncodableValue(kParamId)].IntValue();

  auto db = databaseMap.find(databaseId);
  if (db == databaseMap.end()) {
    std::cout << "db not found" << std::endl;
    return nullptr;
  }

  return std::unique_ptr<SqfliteDatabase>(new SqfliteDatabase(db->second));
}

std::unique_ptr<SqfliteDatabase> getSingleInstanceDatabase(const flutter::MethodCall<EncodableValue> &method_call) {
  EncodableMap args(method_call.arguments()->MapValue());
  std::string path = args[EncodableValue(kParamPath)].StringValue();

  auto db = singleInstanceDatabaseMap.find(path);
  if (db == singleInstanceDatabaseMap.end()) {
    return nullptr;
  }

  return std::unique_ptr<SqfliteDatabase>(new SqfliteDatabase(db->second));
}

std::string makeDatabasesPath() {
  char *var = getenv("HOME");
  if (nullptr == var) {
    struct passwd *pw = getpwuid(getuid());
    var = pw->pw_dir;
  }
  std::string home_dir(var);
  std::string db_path =  home_dir + "/.sqflite";
  mkdir(db_path.c_str(), DEFFILEMODE | S_IXUSR);

  return db_path;
}

bool isInMemoryPath(std::string path) {
  return (0 == path.compare(std::string(kInMemoryPath)));
}

EncodableValue getOpenResult(int databaseId, bool recovered, bool recoveredInTransaction) {
  EncodableMap res;
  res[EncodableValue(kParamId)] = EncodableValue(databaseId);
  if (recovered) {
    res[EncodableValue(kParamRecovered)] = EncodableValue(true);
  }
  if (recoveredInTransaction) {
    res[EncodableValue(kParamRecoveredInTransaction)] = EncodableValue(true);
  }
  return EncodableValue(res);
}

void handleOpenDatabase(const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  EncodableMap args(method_call.arguments()->MapValue());
  std::string path = args[EncodableValue(kParamPath)].StringValue();
  bool read_only = false;
  if (args[EncodableValue(kParamReadOnly)].IsInt()) {
    read_only = args[EncodableValue(kParamReadOnly)].IntValue() != 0;
  } else if (args[EncodableValue(kParamReadOnly)].IsInt()) {
    read_only = args[EncodableValue(kParamReadOnly)].BoolValue();
  }
  bool in_memory = isInMemoryPath(path);
  bool single = false;
  if (args[EncodableValue(kParamSingleInstance)].IsInt()) {
    single = args[EncodableValue(kParamSingleInstance)].IntValue() != 0;
  } else if (args[EncodableValue(kParamSingleInstance)].IsBool()) {
    single = args[EncodableValue(kParamSingleInstance)].BoolValue();
  }
  bool single_instance = single && !in_memory;

  if (hasSqlLogLevel(logLevel)) {
    std::cout << "Opening " << path << (read_only ? " read-only" : "")
        << (single_instance ? " new instance" : "") << std::endl;
  }

  if (single_instance) {
    std::lock_guard<std::mutex> lockGuard(mapLock);
    std::unique_ptr<SqfliteDatabase> database = getSingleInstanceDatabase(method_call);
    if (nullptr != database) {
      std::cout << "Re-opened " << (database->inTransaction ? " (in transaction)" : "")
          << " single instance " << path << " id " << database->databaseId << std::endl;
      EncodableValue res = getOpenResult(database->databaseId, true, database->inTransaction);
      result->Success(&res);
      return;
    }
  }

  if (!in_memory && !read_only) {
    makeDatabasesPath();
  }

  int databaseId;
  {
    std::lock_guard<std::mutex> lockGuard(mapLock);
    SqfliteDatabase database;
    databaseId = ++lastDatabaseId;
    database.inTransaction = false;
    database.singleInstance = single_instance;
    database.databaseId = databaseId;
    database.path = path;
    database.logLevel = logLevel;
    databaseMap[databaseId] = database;
    if (single_instance) {
      singleInstanceDatabaseMap[path] = database;
    }
    if (databaseOpenCount++ == 0) {
      if (hasVerboseLogLevel(logLevel)) {
        std::cout << "Creating operation queue" << std::endl;
      }
    }
  }

  EncodableValue res = getOpenResult(databaseId, false, false);
  result->Success(&res);
}

void bind(sqlite3_stmt *pStmt, EncodableList &sqlArgs) {
  //std::cout << "mike bind_vars" << std::endl;
  std::vector<EncodableValue>::iterator it;
  int i = 1;
  int ret;
  for (it = sqlArgs.begin(); it != sqlArgs.end(); it++) {
    if (it->IsBool()) {
      ret = sqlite3_bind_int(pStmt, i++, it->BoolValue() ? 1 : 0);
    } else if (it->IsInt()) {
      ret = sqlite3_bind_int(pStmt, i++, it->IntValue());
    } else if (it->IsLong()) {
      ret = sqlite3_bind_int64(pStmt, i++, it->LongValue());
    } else if (it->IsDouble()) {
      ret = sqlite3_bind_double(pStmt, i++, it->DoubleValue());
    } else if (it->IsString()) {
      ret = sqlite3_bind_text(pStmt, i++, it->StringValue().c_str(), -1, nullptr);
    } else {
      //std::cout << "mike1" << (i-1) << ": " << "uhoh" << std::endl;
    }
    //std::cout << "mike1" << (i-1) << ": " << ret << std::endl;
  }
}

EncodableValue step(sqlite3_stmt *pStmt) {
  EncodableList columns;
  EncodableList rows;

  bool first = true;
  int ret;
  while (true) {
    ret = sqlite3_step(pStmt);
    //std::cout << "ROW(100): " << ret << std::endl;
    if (SQLITE_ROW != ret) {
      break;
    }

    int count = sqlite3_column_count(pStmt);
    int i;
    if (first) {
      first = false;
      for (i = 0; i < count; i++) {
        const char *name = sqlite3_column_name(pStmt, i);
        //std::cout << "mike20" << i << ": " << name << std::endl;
        columns.push_back(EncodableValue(std::string(name)));
      }
    }

    EncodableMap rowAsMapList;
    EncodableList row;
    for (i = 0; i < count; i++) {
      int type = sqlite3_column_type(pStmt, i);
      EncodableValue value;
      if (SQLITE_INTEGER == type) {
        value = EncodableValue((long)sqlite3_column_int64(pStmt, i));
        //std::cout << "mike21" << i << ": " << (sqlite3_column_int(pStmt, i)) << std::endl;
      } else if (SQLITE_FLOAT == type) {
        value = EncodableValue(sqlite3_column_double(pStmt, i));
        //std::cout << "mike21" << i << ": " << (sqlite3_column_double(pStmt, i)) << std::endl;
      } else if (SQLITE_TEXT == type) {
        const char *c_str = (const char *) sqlite3_column_text(pStmt, i);
        value = EncodableValue(std::string(c_str));
        //std::cout << "mike21" << i << ": " << (sqlite3_column_text(pStmt, i)) << std::endl;
      }

      if (queryAsMapList) {
        rowAsMapList[columns[i]] = value;
      } else {
        row.push_back(value);
      }
    }

    if (queryAsMapList) {
      rows.push_back((EncodableValue)rowAsMapList);
    } else {
      rows.push_back((EncodableValue)row);
    }
  }

  if (queryAsMapList) {
    // list of {name: value, name: value} maps
    return (EncodableValue) rows;
  } else {
    EncodableMap res;
    res[EncodableValue(std::string("columns"))] = columns;
    res[EncodableValue(std::string("rows"))] = rows;
    return (EncodableValue) res;
  }
}

void doExecute(std::string method_name, std::string sql, EncodableList &sql_args,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result,
    std::unique_ptr<SqfliteDatabase> database) {
  if (hasSqlLogLevel(database->logLevel)) {
    std::cout << sql << " " << sql_args.size() << std::endl;
  }

  sqlite3 *pDb;
  int ret = sqlite3_open(database->path.c_str(), &pDb);
  //std::cout << "mike0: " << ret << std::endl;
  sqlite3_busy_timeout(pDb, 5000);

  sqlite3_stmt *pStmt;
  ret = sqlite3_prepare_v2(pDb, sql.c_str(), -1, &pStmt, nullptr);
  //std::cout << "mike10: " << ret << std::endl;
  if (0 != ret) {
    const char *msg = sqlite3_errmsg(pDb);
    std::cout << msg << std::endl;
  }

  if (sql_args.size() > 0) {
    bind(pStmt, sql_args);
  }

  auto res = step(pStmt);

  ret = sqlite3_finalize(pStmt);
  //std::cout << "mike3: " << ret << std::endl;
  sqlite3_close(pDb);

  if (0 == method_name.compare(kMethodInsert)) {
    sqlite3_int64 rowId = sqlite3_last_insert_rowid(pDb);
    res = EncodableValue((long)rowId);
    result->Success(&res);
  } else if ((res.IsList() && (res.ListValue()).size() > 0) || (res.IsMap() && (res.MapValue()).size() > 0)) {
    result->Success(&res);
  } else {
    result->Success();
  }
}

void execute(const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result,
    std::unique_ptr<SqfliteDatabase> database) {
  EncodableMap args(method_call.arguments()->MapValue());
  std::string sql = args[EncodableValue(SqfliteParamSql)].StringValue();
  EncodableList sql_args;
  if (args[EncodableValue(SqfliteParamSqlArguments)].IsList()) {
    sql_args = args[EncodableValue(SqfliteParamSqlArguments)].ListValue();
  }

  doExecute(method_call.method_name(), sql, sql_args, std::move(result), std::move(database));
}

void handleInsert(const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  std::unique_ptr<SqfliteDatabase> database = getDatabase(method_call);
  if (nullptr == database) {
    // TODO The tests seems to not like getting an error here
    //std::cout << "db not found" << std::endl;
    //result->Error(kSqliteErrorCode, kErrorDatabaseClosed);
    result->Success();
    return;
  }

  execute(method_call, std::move(result), std::move(database));
}

void handleQuery(const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  std::unique_ptr<SqfliteDatabase> database = getDatabase(method_call);
  if (nullptr == database) {
    // TODO The tests seems to not like getting an error here
    //std::cout << "db not found" << std::endl;
    //result->Error(kSqliteErrorCode, kErrorDatabaseClosed);
    result->Success();
    return;
  }

  execute(method_call, std::move(result), std::move(database));
}

void handleUpdate(const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  std::unique_ptr<SqfliteDatabase> database = getDatabase(method_call);
  if (nullptr == database) {
    // TODO The tests seems to not like getting an error here
    //std::cout << "db not found" << std::endl;
    //result->Error(kSqliteErrorCode, kErrorDatabaseClosed);
    result->Success();
    return;
  }

  execute(method_call, std::move(result), std::move(database));
}

void handleExecute(const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  std::unique_ptr<SqfliteDatabase> database = getDatabase(method_call);
  if (nullptr == database) {
    // TODO The tests seems to not like getting an error here
    //std::cout << "db not found" << std::endl;
    //result->Error(kSqliteErrorCode, kErrorDatabaseClosed);
    result->Success();
    return;
  }

  execute(method_call, std::move(result), std::move(database));
}

void handleBatch(const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  std::unique_ptr<SqfliteDatabase> database = getDatabase(method_call);
  if (nullptr == database) {
    // TODO The tests seems to not like getting an error here
    //std::cout << "db not found" << std::endl;
    //result->Error(kSqliteErrorCode, kErrorDatabaseClosed);
    result->Success();
    return;
  }

  EncodableMap args(method_call.arguments()->MapValue());
  EncodableList ops = args[EncodableValue(kParamOperations)].ListValue();

  std::vector<EncodableValue>::iterator it;
  for (it = ops.begin(); it != ops.end(); it++) {
    EncodableMap op = (*it).MapValue();
    std::string method = op[EncodableValue(SqfliteParamMethod)].StringValue();
    std::string sql = op[EncodableValue(SqfliteParamSql)].StringValue();
    EncodableList sql_args;
    if (op[EncodableValue(SqfliteParamSqlArguments)].IsList()) {
      sql_args = op[EncodableValue(SqfliteParamSqlArguments)].ListValue();
    }

    // TODO how to handle batch results?
    //doExecute(method, sql, sql_args, std::move(result), database);
  }

  result->Success();
}

void handleGetDatabasesPath(const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  EncodableValue res(makeDatabasesPath());
  result->Success(&res);
}

void closeDatabase(SqfliteDatabase database) {
  {
    std::lock_guard<std::mutex> lockGuard(mapLock);
    databaseMap.erase(database.databaseId);
    if (database.singleInstance) {
      singleInstanceDatabaseMap.erase(database.path);
    }
    if (0 == --databaseOpenCount) {
      if (hasVerboseLogLevel(logLevel)) {
        std::cout << "No more databases open" << std::endl;
      }
    }
  }
}

void handleCloseDatabase(const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  std::unique_ptr<SqfliteDatabase> database = getDatabase(method_call);
  if (nullptr == database) {
    // TODO The tests seems to not like getting an error here
    //std::cout << "db not found" << std::endl;
    //result->Error(kSqliteErrorCode, kErrorDatabaseClosed);
    result->Success();
    return;
  }

  closeDatabase(*database);

  if (hasSqlLogLevel(database->logLevel)) {
    std::cout << "closing " << database->path << std::endl;
  }

  result->Success();
}

void handleDeleteDatabase(const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  std::unique_ptr<SqfliteDatabase> database = getSingleInstanceDatabase(method_call);

  if (nullptr == database) {
    // TODO The tests seems to not like getting an error here
    //std::cout << "db not found" << std::endl;
    //result->Error(kSqliteErrorCode, kErrorDatabaseClosed);
    result->Success();
    return;
  }

  closeDatabase(*database);
  remove(database->path.c_str());

  if (hasSqlLogLevel(logLevel)) {
    std::cout << "Deleting opened " << database->path << " id " << database->databaseId << std::endl;
  }

  result->Success();
}

void handleOptions(const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  EncodableMap args(method_call.arguments()->MapValue());
  bool asMapList = false;
  if (args[EncodableValue(kParamQueryAsMapList)].IsBool()) {
    asMapList = args[EncodableValue(kParamQueryAsMapList)].BoolValue();
  } else if (args[EncodableValue(kParamQueryAsMapList)].IsInt()) {
    asMapList = args[EncodableValue(kParamQueryAsMapList)].IntValue() != 0;
  }

  queryAsMapList = asMapList;

  if (args[EncodableValue(kParamLogLevel)].IsInt()) {
    logLevel = args[EncodableValue(kParamLogLevel)].IntValue();
  }

  std::cout << "Sqflite: loglevel " << logLevel << std::endl;

  result->Success();
}

void handleDebug(const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  result->NotImplemented();
}

void handleDebugMode(const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  result->NotImplemented();
}

void SqflitePlugin::HandleMethodCall(const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
// debugging method calls
/*
  std::cout << "method_name()==" << method_call.method_name() << std::endl;
  if (method_call.arguments() && method_call.arguments()->IsMap()) {
    auto args = method_call.arguments()->MapValue();
    std::map<EncodableValue, EncodableValue>::iterator it;
    for (it = args.begin(); it != args.end(); it++) {
      if (it->second.IsBool()) {
        std::cout << it->first.StringValue() << ": " << it->second.BoolValue() << std::endl;
      } else if (it->second.IsInt()) {
        std::cout << it->first.StringValue() << ": " << it->second.IntValue() << std::endl;
      } else if (it->second.IsLong()) {
        std::cout << it->first.StringValue() << ": " << it->second.LongValue() << std::endl;
      } else if (it->second.IsDouble()) {
        std::cout << it->first.StringValue() << ": " << it->second.DoubleValue() << std::endl;
      } else if (it->second.IsString()) {
        std::cout << it->first.StringValue() << ": " << it->second.StringValue() << std::endl;
      } else if (it->second.IsList()) {
        std::cout << it->first.StringValue() << ": " << "list" << std::endl;
        std::vector<EncodableValue>::iterator jt;
        for (jt = it->second.ListValue().begin(); jt != it->second.ListValue().end(); jt++) {
          if (jt->IsBool()) {
            std::cout << "\t" << jt->BoolValue() << std::endl;
          } else if (jt->IsInt()) {
            std::cout << "\t" << jt->IntValue() << std::endl;
          } else if (jt->IsLong()) {
            std::cout << "\t" << jt->LongValue() << std::endl;
          } else if (jt->IsDouble()) {
            std::cout << "\t" << jt->DoubleValue() << std::endl;
          } else if (jt->IsString()) {
            std::cout << "\t" << jt->StringValue() << std::endl;
          } else if (jt->IsList()) {
            std::cout << "\t" << "list" << std::endl;
          } else if (jt->IsMap()) {
            std::map<EncodableValue, EncodableValue>::iterator kt;
            for (kt = jt->MapValue().begin(); kt != jt->MapValue().end(); kt++) {
              if (kt->second.IsBool()) {
                std::cout << kt->first.StringValue() << ": " << kt->second.BoolValue() << std::endl;
              } else if (kt->second.IsInt()) {
                std::cout << kt->first.StringValue() << ": " << kt->second.IntValue() << std::endl;
              } else if (kt->second.IsLong()) {
                std::cout << kt->first.StringValue() << ": " << kt->second.LongValue() << std::endl;
              } else if (kt->second.IsDouble()) {
                std::cout << kt->first.StringValue() << ": " << kt->second.DoubleValue() << std::endl;
              } else if (kt->second.IsString()) {
                std::cout << kt->first.StringValue() << ": " << kt->second.StringValue() << std::endl;
              } else if (kt->second.IsList()) {
                std::cout << kt->first.StringValue() << ": " << "list" << std::endl;
                std::vector<EncodableValue>::iterator mt;
                for (mt = kt->second.ListValue().begin(); mt != kt->second.ListValue().end(); mt++) {
                  if (mt->IsBool()) {
                    std::cout << "\t" << mt->BoolValue() << std::endl;
                  } else if (mt->IsInt()) {
                    std::cout << "\t" << mt->IntValue() << std::endl;
                  } else if (mt->IsLong()) {
                    std::cout << "\t" << mt->LongValue() << std::endl;
                  } else if (mt->IsDouble()) {
                    std::cout << "\t" << mt->DoubleValue() << std::endl;
                  } else if (mt->IsString()) {
                    std::cout << "\t" << mt->StringValue() << std::endl;
                  } else if (mt->IsList()) {
                    std::cout << "\t" << "list" << std::endl;
                  } else if (mt->IsMap()) {
                    std::cout << "\t" << "map" << std::endl;
                  }
                }
              } else if (kt->second.IsMap()) {
                std::cout << kt->first.StringValue() << ": " << "map" << std::endl;
              }
            }
          }
        }
      } else if (it->second.IsMap()) {
        std::cout << it->first.StringValue() << ": " << "map" << std::endl;
      }
    }
  }
*/

  if (0 == method_call.method_name().compare(kMethodGetPlatformVersion)) {
    auto res = EncodableValue("Linux");
    result->Success(&res);
  } else if (0 == method_call.method_name().compare(kMethodOpenDatabase)) {
    handleOpenDatabase(method_call, std::move(result));
  } else if (0 == method_call.method_name().compare(kMethodInsert)) {
    handleInsert(method_call, std::move(result));
  } else if (0 == method_call.method_name().compare(kMethodQuery)) {
    handleQuery(method_call, std::move(result));
  } else if (0 == method_call.method_name().compare(kMethodUpdate)) {
    handleUpdate(method_call, std::move(result));
  } else if (0 == method_call.method_name().compare(kMethodExecute)) {
    handleExecute(method_call, std::move(result));
  } else if (0 == method_call.method_name().compare(kMethodBatch)) {
    handleBatch(method_call, std::move(result));
  } else if (0 == method_call.method_name().compare(kMethodGetDatabasesPath)) {
    handleGetDatabasesPath(method_call, std::move(result));
  } else if (0 == method_call.method_name().compare(kMethodCloseDatabase)) {
    handleCloseDatabase(method_call, std::move(result));
  } else if (0 == method_call.method_name().compare(kMethodDeleteDatabase)) {
    handleDeleteDatabase(method_call, std::move(result));
  } else if (0 == method_call.method_name().compare(kMethodOptions)) {
    handleOptions(method_call, std::move(result));
  } else if (0 == method_call.method_name().compare(kMethodDebug)) {
    handleDebug(method_call, std::move(result));
  } else if (0 == method_call.method_name().compare(kMethodDebugMode)) {
    handleDebugMode(method_call, std::move(result));
  } else {
    result->NotImplemented();
  }
}

}  // namespace sqflite_plugin

void SqflitePluginRegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar) {
  // The plugin registrar owns the plugin, registered callbacks, etc., so must
  // remain valid for the life of the application.
  static auto *plugin_registrar = new flutter::PluginRegistrar(registrar);
  sqflite_plugin::SqflitePlugin::RegisterWithRegistrar(plugin_registrar);
}
