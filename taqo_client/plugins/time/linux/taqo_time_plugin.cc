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
#include "taqo_time_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar.h>
#include <flutter/standard_method_codec.h>

namespace taqo_time_plugin {

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

// See channel_controller.dart for documentation.
const char kChannelName[] = "taqo_time_plugin";
//const char kInitializeMethod[] = "initialize";
//const char kCancelMethod[] = "cancel";
//const char kBackgroundChannelName[] = "com.taqo.survey/taqo_time_plugin_background";
//const char kInitializedMethod[] = "initialized";

// Looks for |key| in |map|, returning the associated value if it is present, or
// a Null EncodableValue if not.
//const EncodableValue &ValueOrNull(const EncodableMap &map, const char *key) {
//  static EncodableValue null_value;
//  auto it = map.find(EncodableValue(key));
//  if (it == map.end()) {
//    return null_value;
//  }
//  return it->second;
//}

}  // namespace

class TaqoTimePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrar *registrar);

  virtual ~TaqoTimePlugin();

 private:
  // Creates a plugin that communicates on the given channel.
  TaqoTimePlugin(
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
//static EncodableValue CreateResponseObject(
//    const std::vector<std::string> &filenames) {
//  if (filenames.empty()) {
//    return EncodableValue();
//  }
//  EncodableList response;
//  for (const std::string &filename : filenames) {
//    response.push_back(EncodableValue(filename));
//  }
//  return EncodableValue(std::move(response));
//}

// static
void TaqoTimePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrar *registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      registrar->messenger(), kChannelName,
      &flutter::StandardMethodCodec::GetInstance());
  auto *channel_pointer = channel.get();

  // Uses new instead of make_unique due to private constructor.
  std::unique_ptr<TaqoTimePlugin> plugin(new TaqoTimePlugin(std::move(channel)));

  channel_pointer->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });
  registrar->EnableInputBlockingForChannel(kChannelName);

  registrar->AddPlugin(std::move(plugin));
}

TaqoTimePlugin::TaqoTimePlugin(
    std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel)
    : channel_(std::move(channel)) {}

TaqoTimePlugin::~TaqoTimePlugin() {}

void TaqoTimePlugin::HandleMethodCall(
    const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
//  if (!method_call.arguments() || !method_call.arguments()->IsMap()) {
//    result->Error("Bad Arguments", "Argument map missing or malformed");
//    return;
//  }

  // TODO Implement channel methods
  auto res = EncodableValue();
  result->Success(&res);
  //result->NotImplemented();
}

}  // namespace taqo_time_plugin

void TaqoTimePluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  // The plugin registrar owns the plugin, registered callbacks, etc., so must
  // remain valid for the life of the application.
  static auto *plugin_registrar = new flutter::PluginRegistrar(registrar);
  taqo_time_plugin::TaqoTimePlugin::RegisterWithRegistrar(plugin_registrar);
}
