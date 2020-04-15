//
//  Generated file. Do not edit.
//

#include "generated_plugin_registrant.h"

#include <path_provider_plugin.h>
#include <shared_preferences_plugin.h>
#include <sqflite_plugin.h>
#include <taqo_time_plugin.h>
#include <url_launcher_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  PathProviderPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PathProviderPlugin"));
  SharedPreferencesPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("SharedPreferencesPlugin"));
  SqflitePluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("SqflitePlugin"));
  TaqoTimePluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("TaqoTimePlugin"));
  UrlLauncherPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherPlugin"));
}
