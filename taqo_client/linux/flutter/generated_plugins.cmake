list(APPEND FLUTTER_PLUGIN_LIST
  url_launcher_fde
  path_provider_linux
  taqo_time_plugin
)

foreach(plugin ${FLUTTER_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${plugin}/linux plugins/${plugin})
  target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)
endforeach(plugin)
