# taqo_survey

A *research* tool for behavioral research. It is the next version of Paco.

It has been completely rewritten to be more modular and more easily runnable and maintainable across both mobile and desktop platforms.

The main app is in the `taqo_client` subdirectory, which contains a Flutter project. More information can be found in `taqo_client/README.md`.

The `data_binding_builder` subdirectory contains a Dart project that generates code for database-object connection. The instructions for running the builder is also in `taqo_client/README.md`. Since the generated files are also under version control, one does not need to run this builder unless the database-object relation described in this project is changed. 

The pal_event_server directory is the desktop daemon that manages data and native interaction services, e.g., dbus, alarm scheduling, data storage interaction, event triggering, data uploading, etc.
