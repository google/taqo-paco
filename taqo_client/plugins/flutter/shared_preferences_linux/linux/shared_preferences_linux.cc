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
#include <pwd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

#include "leveldb/db.h"

#include "plugins/flutter/shared_preferences_linux/linux/shared_preferences_linux.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar.h>
#include <flutter/standard_method_codec.h>

namespace shared_preferences_linux {

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

// See channel_controller.dart for documentation.
const char kChannelName[] = "plugins.flutter.io/shared_preferences";
const char kSetBoolMethod[] = "setBool";
const char kSetDoubleMethod[] = "setDouble";
const char kSetIntMethod[] = "setInt";
const char kSetStringMethod[] = "setString";
const char kSetStringListMethod[] = "setStringList";
const char kGetAllMethod[] = "getAll";
const char kRemoveMethod[] = "remove";
const char kClearMethod[] = "clear";
const char kKeyArg[] = "key";
const char kValueArg[] = "value";

std::string kBoolPrefix("a447e80_");
std::string kIntPrefix("40bc979_");
std::string kDoublePrefix("4a095b9_");
std::string kStringPrefix("b80fa55_");
std::string kStringListPrefix("d4a9f92_");

// Looks for |key| in |map|, returning the associated value if it is present, or
// a Null EncodableValue if not.
const EncodableValue &ValueOrNull(const EncodableMap &map, const char *key) {
  static EncodableValue null_value;
  auto it = map.find(EncodableValue(key));
  if (it == map.end()) {
    return null_value;
  }
  return it->second;
}

}  // namespace

class SharedPreferencesPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrar *registrar);

  virtual ~SharedPreferencesPlugin();

 private:
  // Creates a plugin that communicates on the given channel.
  SharedPreferencesPlugin(
      std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel);

  // Called when a method is called on |channel_|;
  void HandleMethodCall(
      const flutter::MethodCall<EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<EncodableValue>> result);

  // The MethodChannel used for communication with the Flutter engine.
  std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel_;
};

static std::string GetDBPath() {
  char *var = getenv("HOME");
  if (nullptr == var) {
    struct passwd *pw = getpwuid(getuid());
    var = pw->pw_dir;
  }
  std::string home_dir(var);
  std::string db_path =  home_dir + "/.taqo";
  mkdir(db_path.c_str(), DEFFILEMODE | S_IXUSR);
  return (db_path + "/sharedpreferences");
}

// static
void SharedPreferencesPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrar *registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      registrar->messenger(), kChannelName,
      &flutter::StandardMethodCodec::GetInstance());
  auto *channel_pointer = channel.get();

  // Uses new instead of make_unique due to private constructor.
  std::unique_ptr<SharedPreferencesPlugin> plugin(new SharedPreferencesPlugin(std::move(channel)));

  channel_pointer->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });
  registrar->EnableInputBlockingForChannel(kChannelName);

  registrar->AddPlugin(std::move(plugin));
}

SharedPreferencesPlugin::SharedPreferencesPlugin(
    std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel)
    : channel_(std::move(channel)) {}

SharedPreferencesPlugin::~SharedPreferencesPlugin() {}

void SharedPreferencesPlugin::HandleMethodCall(
    const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  leveldb::DB *db;
  leveldb::Options options;
  options.create_if_missing = true;
  leveldb::Status status = leveldb::DB::Open(options, GetDBPath().c_str(), &db);
  assert(status.ok());

  std::string key;
  EncodableValue v;

  if (method_call.arguments() && method_call.arguments()->IsMap()) {
    auto args = method_call.arguments()->MapValue();
    auto k = ValueOrNull(args, kKeyArg);
    key = k.StringValue();
    if (key.empty()) {
      result->Error(method_call.method_name(), "Must provide key");
      return;
    }

    v = ValueOrNull(args, kValueArg);
  }

  if (0 == method_call.method_name().compare(kSetBoolMethod)) {
    auto value = v.BoolValue();
    std::string string_value = kBoolPrefix + (value ? "true" : "false");
    db->Put(leveldb::WriteOptions(), key, leveldb::Slice(string_value));
    result->Success();
  } else if (0 == method_call.method_name().compare(kSetDoubleMethod)) {
    auto value = v.DoubleValue();
    std::string string_value = kDoublePrefix + std::to_string(value);
    db->Put(leveldb::WriteOptions(), key, leveldb::Slice(string_value));
    result->Success();
  } else if (0 == method_call.method_name().compare(kSetIntMethod)) {
    auto value = v.IntValue();
    std::string string_value = kIntPrefix + std::to_string(value);
    db->Put(leveldb::WriteOptions(), key, leveldb::Slice(string_value));
    result->Success();
  } else if (0 == method_call.method_name().compare(kSetStringMethod)) {
    auto value = v.StringValue();
    std::string string_value = kStringPrefix + value;
    db->Put(leveldb::WriteOptions(), key, leveldb::Slice(string_value));
    result->Success();
  } else if (0 == method_call.method_name().compare(kSetStringListMethod)) {
    //auto value = v.ListValue();
    result->Success();
  } else if (0 == method_call.method_name().compare(kGetAllMethod)) {
    EncodableMap prefs{};
    leveldb::Iterator *it = db->NewIterator(leveldb::ReadOptions());
    for (it->SeekToFirst(); it->Valid(); it->Next()) {
      EncodableValue k(it->key().ToString());
      std::string v(it->value().ToString());
      std::string prefix = v.substr(0, 8);
      std::string suffix = v.substr(8);
      if (0 == prefix.compare(kBoolPrefix)) {
        if (0 == suffix.compare("true")) {
          prefs.insert(std::pair<EncodableValue, EncodableValue>(k, EncodableValue(true)));
        } else {
          prefs.insert(std::pair<EncodableValue, EncodableValue>(k, EncodableValue(false)));
        }
      } else if (0 == prefix.compare(kDoublePrefix)) {
        prefs.insert(std::pair<EncodableValue, EncodableValue>(k, EncodableValue(std::stod(suffix))));
      } else if (0 == prefix.compare(kIntPrefix)) {
        prefs.insert(std::pair<EncodableValue, EncodableValue>(k, EncodableValue(std::stoi(suffix))));
      } else if (0 == prefix.compare(kStringPrefix)) {
        prefs.insert(std::pair<EncodableValue, EncodableValue>(k, EncodableValue(suffix)));
      }
    }
    EncodableValue res(prefs);
    result->Success(&res);
  } else if (0 == method_call.method_name().compare(kRemoveMethod)) {
    db->Delete(leveldb::WriteOptions(), key);
    result->Success();
  } else if (0 == method_call.method_name().compare(kClearMethod)) {
    result->Success();
  } else {
    result->NotImplemented();
  }

  delete db;
}

}  // namespace shared_preferences_linux

void SharedPreferencesPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  // The plugin registrar owns the plugin, registered callbacks, etc., so must
  // remain valid for the life of the application.
  static auto *plugin_registrar = new flutter::PluginRegistrar(registrar);
  shared_preferences_linux::SharedPreferencesPlugin::RegisterWithRegistrar(plugin_registrar);
}
