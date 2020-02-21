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
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#include "plugins/flutter/url_launcher_linux/linux/url_launcher_linux.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar.h>
#include <flutter/standard_method_codec.h>

namespace url_launcher_linux {

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

// See channel_controller.dart for documentation.
const char kChannelName[] = "plugins.flutter.io/url_launcher";
const char kCanLaunchMethod[] = "canLaunch";
const char kLaunchMethod[] = "launch";
const char kUrlArg[] = "url";

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

class UrlLauncherPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrar *registrar);

  virtual ~UrlLauncherPlugin();

 private:
  // Creates a plugin that communicates on the given channel.
  UrlLauncherPlugin(
      std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel);

  // Called when a method is called on |channel_|;
  void HandleMethodCall(
      const flutter::MethodCall<EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<EncodableValue>> result);

  // The MethodChannel used for communication with the Flutter engine.
  std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel_;
};

// Creates a valid channel response object given the list of filenames.
//
// An empty array is treated as a cancelled operation.
//static EncodableValue CreateResponseObject(const std::string path) {
//  if (0 == path.length()) {
//    return EncodableValue();
//  }
//  return EncodableValue(path);
//}

// static
void UrlLauncherPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrar *registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      registrar->messenger(), kChannelName,
      &flutter::StandardMethodCodec::GetInstance());
  auto *channel_pointer = channel.get();

  // Uses new instead of make_unique due to private constructor.
  std::unique_ptr<UrlLauncherPlugin> plugin(new UrlLauncherPlugin(std::move(channel)));

  channel_pointer->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });
  registrar->EnableInputBlockingForChannel(kChannelName);

  registrar->AddPlugin(std::move(plugin));
}

UrlLauncherPlugin::UrlLauncherPlugin(
    std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel)
    : channel_(std::move(channel)) {}

UrlLauncherPlugin::~UrlLauncherPlugin() {}

void UrlLauncherPlugin::HandleMethodCall(
    const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  if (!method_call.arguments() || !method_call.arguments()->IsMap()) {
    result->Error("Bad Arguments", "Argument map missing or malformed");
    return;
  }

  auto args = method_call.arguments()->MapValue();
  auto value = ValueOrNull(args, kUrlArg);
  auto url = value.StringValue();
  if (url.empty()) {
    result->Error("Bad Arguments", "Must provide URL");
    return;
  }

  if (0 == method_call.method_name().compare(kCanLaunchMethod)) {
    auto res = EncodableValue(true);
    result->Success(&res);
    return;
  } else if (0 == method_call.method_name().compare(kLaunchMethod)) {
    auto pid = fork();
    if (0 == pid) {
      execl("/usr/bin/xdg-open", "xdg-open", url.c_str(), (char*) nullptr);
      exit(1);
    }

    int status = 0;
    waitpid(pid, &status, 0);
    if (0 != status) {
      result->Error("Failed to open", "Failed to open URL");
      return;
    }

    auto res = EncodableValue(true);
    result->Success(&res);
    return;
  }

  result->NotImplemented();
}

}  // namespace url_launcher_linux

void UrlLauncherPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  // The plugin registrar owns the plugin, registered callbacks, etc., so must
  // remain valid for the life of the application.
  static auto *plugin_registrar = new flutter::PluginRegistrar(registrar);
  url_launcher_linux::UrlLauncherPlugin::RegisterWithRegistrar(plugin_registrar);
}
