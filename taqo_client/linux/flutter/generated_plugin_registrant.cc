//
//  Generated file. Do not edit.
//

#include "generated_plugin_registrant.h"

#include <url_launcher_plugin.h>
#include <path_provider_plugin.h>
#include <taqo_time_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  UrlLauncherPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherPlugin"));
  PathProviderPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PathProviderPlugin"));
  TaqoTimePluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("TaqoTimePlugin"));
}
