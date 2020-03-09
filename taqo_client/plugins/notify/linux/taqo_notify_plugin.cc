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
//#include <thread>
#include <signal.h>
#include <unistd.h>

#include <libnotify/notify.h>

#include "plugins/notify/linux/taqo_notify_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar.h>
#include <flutter/standard_method_codec.h>

namespace taqo_notify_plugin {

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

// See channel_controller.dart for documentation.
const char kNotificationAppName[] = "Taqo Survey";

const char kChannelName[] = "taqo_notify_plugin";
const char kInitializeMethod[] = "initialize";
const char kNotifyMethod[] = "notify";
const char kCancelMethod[] = "cancel";
const char kHandleCallbackMethod[] = "handle";
const char kTitleArg[] = "title";
const char kBodyArg[] = "body";
const char kPayloadArg[] = "payload";
const char kIdArg[] = "id";

}  // namespace

class TaqoNotifyPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrar *registrar);

  virtual ~TaqoNotifyPlugin();

  // The MethodChannel used for communication with the Flutter engine.
  std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel_;

 private:
  // Creates a plugin that communicates on the given channel.
  TaqoNotifyPlugin(std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel);

  // Called when a method is called on |channel_|;
  void HandleMethodCall(
      const flutter::MethodCall<EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<EncodableValue>> result);
};

// static
void TaqoNotifyPlugin::RegisterWithRegistrar(flutter::PluginRegistrar *registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      registrar->messenger(), kChannelName,
      &flutter::StandardMethodCodec::GetInstance());
  auto *channel_pointer = channel.get();

  // Uses new instead of make_unique due to private constructor.
  std::unique_ptr<TaqoNotifyPlugin> plugin(new TaqoNotifyPlugin(std::move(channel)));

  channel_pointer->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });
  registrar->EnableInputBlockingForChannel(kChannelName);

  registrar->AddPlugin(std::move(plugin));
}

TaqoNotifyPlugin::TaqoNotifyPlugin(std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel)
    : channel_(std::move(channel)) {}

TaqoNotifyPlugin::~TaqoNotifyPlugin() {}

// Returns the path of the directory containing this executable, or an empty
// string if the directory cannot be found.
std::string GetExecutableDirectory() {
  char buffer[PATH_MAX + 1];
  ssize_t length = readlink("/proc/self/exe", buffer, sizeof(buffer));
  if (length > PATH_MAX) {
    std::cerr << "Couldn't locate executable" << std::endl;
    return "";
  }
  std::string executable_path(buffer, length);
  size_t last_separator_position = executable_path.find_last_of('/');
  if (last_separator_position == std::string::npos) {
    std::cerr << "Unabled to find parent directory of " << executable_path << std::endl;
    return "";
  }
  return executable_path.substr(0, last_separator_position);
}

std::string getIconPath() {
  std::string base_directory = GetExecutableDirectory();
  std::string path = base_directory + "/data/flutter_assets/assets/paco256.png";
  return path;
}

static TaqoNotifyPlugin *plugin_;
static int callback_id_ = -1;

//static pthread_mutex_t lock_;
static pthread_t flutter_th_ = -1;

void sigHandle(int sig) {
  if (SIGUSR1 != sig) return;

  //std::cout << "Received " << sig << " " << std::this_thread::get_id() << std::endl;
  if (callback_id_ >= 0) {
    plugin_->channel_->InvokeMethod(kHandleCallbackMethod,
        std::make_unique<EncodableValue>(callback_id_));
    callback_id_ = -1;
  }
  //pthread_mutex_unlock(&lock_);
}

static bool gMainLoopRunning_ = false;
static auto notifications_ = std::map<int, NotifyNotification*>();

// We need a GMainLoop to handle notification actions
static void * main_loop(void *cxt) {
  notify_init(kNotificationAppName);
  GMainContext *context = (GMainContext *) cxt;
  GMainLoop *loop = g_main_loop_new(context, false);

  //std::cout << "Running main loop" << std::endl;
  g_main_loop_run(loop);
  //std::cout << "Done main loop" << std::endl;

  notify_uninit();
  gMainLoopRunning_ = false;
  return nullptr;
}

static void handle(NotifyNotification *notification, char *action, gpointer user_data) {
  auto payload = reinterpret_cast<int *>(user_data);
  auto id = *payload;
  //std::cout << "Handle " << id << " " << std::this_thread::get_id() << std::endl;
  //pthread_mutex_lock(&lock_);   // this lock is released by the other thread
  callback_id_ = id;
  pthread_kill(flutter_th_, SIGUSR1);

  notifications_.erase(id);
  delete payload;
}

void TaqoNotifyPlugin::HandleMethodCall(
    const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {

  if (0 == method_call.method_name().compare(kInitializeMethod)) {
    if (!gMainLoopRunning_) {
      plugin_ = this;
      flutter_th_ = pthread_self();
      signal(SIGUSR1, sigHandle);

      // We need a GMainLoop to handle notification actions
      auto context = g_main_context_default();
      pthread_t main_loop_thread;
      pthread_create(&main_loop_thread, nullptr, main_loop, (void *) context);
      gMainLoopRunning_ = true;
    }

    auto res = EncodableValue(true);
    result->Success(&res);
  } else if (0 == method_call.method_name().compare(kNotifyMethod)) {
    if (!method_call.arguments() || !method_call.arguments()->IsMap()) {
      auto res = EncodableValue(false);
      result->Success(&res);
      return;
    }
    auto args = method_call.arguments()->MapValue();
    auto title = args[EncodableValue(kTitleArg)].StringValue();
    auto body = args[EncodableValue(kBodyArg)].StringValue();
    auto id = args[EncodableValue(kPayloadArg)].IntValue();

    NotifyNotification *notification = notify_notification_new(title.c_str(), body.c_str(),
        getIconPath().c_str());
    notify_notification_set_timeout(notification, NOTIFY_EXPIRES_NEVER);
    notify_notification_set_urgency(notification, NOTIFY_URGENCY_CRITICAL);

    int *payload = new int(id);
    // "default" action (clicked on the Notification)
    notify_notification_add_action(notification, "default", "Participate",
        (NotifyActionCallback) handle, (void *) payload, nullptr);

    if (!notify_notification_show(notification, 0)) {
      auto res = EncodableValue(false);
      result->Success(&res);
      return;
    }

    notifications_[id] = notification;

    auto res = EncodableValue(true);
    result->Success(&res);
  } else if (0 == method_call.method_name().compare(kCancelMethod)) {
    if (!method_call.arguments() || !method_call.arguments()->IsMap()) {
      auto res = EncodableValue(false);
      result->Success(&res);
      return;
    }
    auto args = method_call.arguments()->MapValue();
    auto id = args[EncodableValue(kIdArg)].IntValue();

    if (notifications_.find(id) == notifications_.end()) {
      auto res = EncodableValue(false);
      result->Success(&res);
      return;
    }

    notify_notification_close(notifications_[id], nullptr);
    notifications_.erase(id);

    auto res = EncodableValue(true);
    result->Success(&res);
  } else {
    result->NotImplemented();
  }
}

}  // namespace taqo_notify_plugin

void TaqoNotifyPluginRegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar) {
  // The plugin registrar owns the plugin, registered callbacks, etc., so must
  // remain valid for the life of the application.
  static auto *plugin_registrar = new flutter::PluginRegistrar(registrar);
  taqo_notify_plugin::TaqoNotifyPlugin::RegisterWithRegistrar(plugin_registrar);
}
