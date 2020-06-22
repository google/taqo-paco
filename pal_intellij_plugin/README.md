If necessary, follow below as required.

# Building
- Open the pal_intellij_plugin project in IntelliJ
- In the Project Structure (File->Project Structure), under Platform Settings -> SDKs,
add a JDK (if necessary) and the IntelliJ Platform Plugin SDK, using the + icon
- Under Project Settings -> Project, select the IntelliJ SDK for the Project SDK
- Under Project Settings -> Modules, use the + icon to add a new module of type
IntelliJ Platform Plugin. This should create a module with the src folder marked as
Source Folders and the resouces folder marked as Resource Folders
- Add all of the jar files under libs/lib/ to Dependencies
- Click OK to close Project Structure
- The project should now Build without errors

# Running / Debugging
- In the Run/Debug Configurations (Run->Edit Configurations...), use the + icon to
add a "Plugin" run configuration. It maybe listed under "Templates" if you don't see it
in the list.
- Select the proper module and JRE
- You should now be about to use IntelliJ to run/debug the plugin
