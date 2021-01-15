// Copyright 2021 Google LLC
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

package com.pacoapp.intellij;

import com.google.common.collect.Maps;
import com.google.common.collect.Sets;
import com.google.common.io.Files;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.intellij.concurrency.JobScheduler;
import com.intellij.history.core.LabelImpl;
import com.intellij.history.core.LocalHistoryFacade;
import com.intellij.history.integration.LocalHistoryImpl;
import com.intellij.openapi.application.ApplicationManager;
import com.intellij.openapi.compiler.*;
import com.intellij.openapi.components.ProjectComponent;
import com.intellij.openapi.project.Project;
import com.intellij.openapi.roots.ProjectRootManager;
import com.intellij.openapi.vcs.changes.Change;
import com.intellij.openapi.vcs.changes.ChangeList;
import com.intellij.openapi.vcs.changes.ChangeListListener;
import com.intellij.openapi.vcs.changes.ChangeListManager;
import com.intellij.openapi.vfs.VirtualFile;
import com.intellij.util.io.ZipUtil;
import com.intellij.util.messages.MessageBusConnection;
import com.jetbrains.lang.dart.analyzer.DartAnalysisServerService;
import com.jetbrains.lang.dart.analyzer.DartServerData;
import io.flutter.dart.DartPlugin;
import io.flutter.dart.FlutterDartAnalysisServer;
import io.flutter.dart.FlutterOutlineListener;
import org.dartlang.analysis.server.protocol.FlutterOutline;
import org.jetbrains.annotations.NotNull;
import org.joda.time.DateTime;

import java.io.*;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.*;
import java.util.concurrent.TimeUnit;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import java.util.zip.ZipOutputStream;

public class PacoProjectComponent implements ProjectComponent {
  public static final Logger log = Logger.getLogger(PacoProjectComponent.class.getName());
  public static final int MAX_LENGTH_OF_ANSWER = 500;

  private final Project project;
  private MessageBusConnection connection;
  private FlutterDartAnalysisServer flutterDartAnalysisServer;
  private FlutterOutlineListener outlineListener;
  private String outlineListenerFilePath;
  private static final String FLUTTER_NOTIFICATION_OUTLINE = "flutter.outline";
  private DartAnalysisServerService dartAnalysisServerService;

  public PacoProjectComponent(Project project) {
    this.project = project;
  }

  @Override
  public void projectOpened() {
    PacoApplicationComponent pacoAppComponent = PacoApplicationComponent.instance();
    Map<String, String> data = Maps.newHashMap();
    data.put("project", project.getName());
    PacoApplicationComponent.appendPacoEvent(PacoIntellijEventTypes.EventType.PROJECT_OPENED, data);
    pacoAppComponent.addRunManagerListener(project);
    pacoAppComponent.addFileEditorManagerListener(project);
    registerCompilerListener(project);
    registerDartAnalysisListener(project);
    registerChangelistManagerListener(project);
    createSnapshotOfFiles(project, pacoAppComponent);
  }

  private void createSnapshotOfFiles(Project project, PacoApplicationComponent pacoAppComponent) {
    //ApplicationManager.getApplication().executeOnPooledThread(new Runnable() {
    ApplicationManager.getApplication().runReadAction(new Runnable() {
      public void run() {
        _createSnapshotOfFiles(project, pacoAppComponent);
      }
    });
  }

  private void _createSnapshotOfFiles(Project project, PacoApplicationComponent pacoAppComponent) {
    LabelImpl label = createVersionLabel(project);
    pacoAppComponent.store(project, label);

    VirtualFile[] contentRoots = ProjectRootManager.getInstance(project).getContentRootsFromAllModules();
    List<VirtualFile> projectFiles = new ArrayList<>();
    VirtualFile baseUrl = null;
    for (int i = 0; i < contentRoots.length; i++) {
      VirtualFile cr = contentRoots[i];
      System.out.println("cr = " + cr.getCanonicalPath());
      VirtualFile lib = cr.findChild("lib");

      if (lib != null) {
        baseUrl = lib.getParent();
        System.out.println("lib folder files: " + Arrays.stream(lib.getChildren()).map(VirtualFile::getUrl).collect(Collectors.joining("\n")));
        addChildrenToProjectFiles(projectFiles, lib);
      }
      VirtualFile test = cr.findChild("test");
      if (test != null) {
        System.out.println("lib folder files: " + Arrays.stream(test.getChildren()).map(VirtualFile::getUrl).collect(Collectors.joining("\n")));
        addChildrenToProjectFiles(projectFiles, test);
      }
      VirtualFile pubspec = cr.findChild("pubspec.yaml");
      if (pubspec != null) {
        System.out.println("Pubspec.yaml: " + pubspec.getUrl());
        addChildrenToProjectFiles(projectFiles, pubspec);
      }
    }

    System.out.println("project files: " + projectFiles.stream().map(VirtualFile::getUrl).collect(Collectors.joining("\n")));
    File tmpDir = Files.createTempDir();
    Path pathBase = baseUrl == null ? Paths.get("") : Paths.get(baseUrl.getPath());
    export(pathBase, tmpDir, projectFiles, pacoAppComponent);
  }

  private LabelImpl createVersionLabel(Project project) {
    LocalHistoryFacade facade = LocalHistoryImpl.getInstanceImpl().getFacade();
    return facade.putUserLabel("pal_baseline_" + DateTime.now().toString(), project.getLocationHash());
  }

  public void export(Path basepath, File tmpDir, List<VirtualFile> projectFiles, PacoApplicationComponent pacoAppComponent) {
    File zipFile = createZipFile("PAL_SNAPSHOT", tmpDir);
    log.info("zip file snapshot = " + zipFile.getAbsolutePath());
    ZipOutputStream outputStream = null;
    Set<String> writtenPaths = Sets.newHashSet();
    try {
      outputStream = new ZipOutputStream(new FileOutputStream(zipFile));
      for (VirtualFile projectFile : projectFiles) {
        String relativePath = basepath.relativize(Paths.get(projectFile.getPath())).toString();
        ZipUtil.addFileToZip(outputStream, new File(projectFile.getPath()), relativePath, writtenPaths, new FileFilter() {
          @Override
          public boolean accept(File pathname) {
            if (pathname.getAbsolutePath().contains(tmpDir.getAbsolutePath()))
              return false;
            else
              return true;
          }
        });
      }
    } catch (FileNotFoundException e) {
    } catch (IOException e) {
      log.severe("Could not build snapshot: " + e.getMessage());
    }
    if (outputStream != null) {
      try {
        outputStream.close();
      } catch (IOException e) {
        e.printStackTrace();
      }
    }
    Map<String, String> data = Maps.newHashMap();
    data.put("snapshot_file", zipFile.getAbsolutePath());
    if (zipFile.length() <= 1000000 /* 1mb max*/) {
      String base64EncodedZipFile = Base64.getEncoder().encodeToString(getBytesOfZip(zipFile));
      if (base64EncodedZipFile != null) {
        data.put("base_snapshot_contents", "zipfile===" + base64EncodedZipFile);
      }
    }
    pacoAppComponent.appendPacoEvent(PacoIntellijEventTypes.EventType.PROJECT_SNAPSHOT, data);
    project.save(); // TODO - do I need to do this?
  }

  private byte[] getBytesOfZip(File zipFile) {
    try {
      return java.nio.file.Files.readAllBytes(zipFile.toPath());
    } catch (IOException e) {
      e.printStackTrace();
      return null;
    }
  }

  private File createZipFile(String moduleName, File localStorage) {
    String localStorageAbsolutePath = localStorage.getAbsolutePath();
    File zipFile = Paths.get(localStorageAbsolutePath, moduleName + System.currentTimeMillis() + ".zip").toFile();
    try {
      zipFile.createNewFile();
    } catch (IOException e) {
      log.severe("Cannot create snapshot zipfile: " + e.getMessage());
    }
    return zipFile;
  }


  private void addChildrenToProjectFiles(List<VirtualFile> projectFiles, VirtualFile file) {
    if (file.isDirectory()) {
      VirtualFile[] children = file.getChildren();
      for (int j = 0; j < children.length; j++) {
        VirtualFile child = children[j];
        if (!child.isDirectory() && !projectFiles.contains(child)) {
          projectFiles.add(child);
        } else if (child.isDirectory()) {
          addChildrenToProjectFiles(projectFiles, child);
        }
      }
    } else {
      projectFiles.add(file);
    }
  }

  // Thought this would allow getting Local History, but, it does not get called when files change.
  private void registerChangelistManagerListener(Project project) {
    final ChangeListManager changeListManager = ChangeListManager.getInstance(project);
    ChangeListListener changeListListener = new ChangeListListener() {
      @Override
      public void changeListAdded(ChangeList changeList) {
        System.out.println("changeList = " + changeList.getName());
      }

      @Override
      public void changesRemoved(Collection<Change> collection, ChangeList changeList) {
        System.out.println("changeList = " + changeList.getName());
      }

      @Override
      public void changesAdded(Collection<Change> collection, ChangeList changeList) {
        System.out.println("changeList = " + changeList.getName());
      }

      @Override
      public void changeListRemoved(ChangeList changeList) {
        System.out.println("changeList = " + changeList.getName());
      }

      @Override
      public void changeListChanged(ChangeList changeList) {
        System.out.println("changeList = " + changeList.getName());
      }

      @Override
      public void changeListRenamed(ChangeList changeList, String s) {
        System.out.println("changeList = " + changeList.getName());
      }

      @Override
      public void changeListCommentChanged(ChangeList changeList, String s) {
        System.out.println("changeList = " + changeList.getName());
      }

      @Override
      public void changesMoved(Collection<Change> collection, ChangeList changeList, ChangeList changeList1) {
        System.out.println("changeList = " + changeList.getName());
      }

      @Override
      public void defaultListChanged(ChangeList changeList, ChangeList changeList1) {
        System.out.println("changeList = " + changeList.getName());
      }

      @Override
      public void unchangedFileStatusChanged() {
        System.out.println("unchangedFileStatusChanged");
      }

      @Override
      public void changeListUpdateDone() {
        System.out.println("changeListUpdateDone");
      }
    };
    changeListManager.addChangeListListener(changeListListener);
  }

  private void registerDartAnalysisListener(Project project) {
    JobScheduler.getScheduler().scheduleWithFixedDelay(() -> {
      final DartAnalysisServerService analysisService = DartPlugin.getInstance().getAnalysisService(project);
      if (analysisService != null) {
        dartAnalysisServerService = analysisService;
      }
    }, 100, 100, TimeUnit.MILLISECONDS);
//    flutterDartAnalysisServer = FlutterDartAnalysisServer.getInstance(project);
//
//    flutterDartAnalysisServer.addOutlineListener(outlineListenerFilePath, outlineListener);
  }

  public void getErrors(VirtualFile file) {
    if (dartAnalysisServerService != null) {
//      final String id = dartServiceEx.generateUniqueId();
//
//      JsonObject request = new JsonObject();
//
//      request.addProperty("id", id);
//      request.addProperty("method", "analysis.getErrors");
//      JsonObject params = new JsonObject();
//      params.add("file", new JsonPrimitive("/Users/bobevans/IdeaProjects/my_test_flutter/lib/main.dart"));
//      request.add("params", params);

      List<DartServerData.DartError> errors = dartAnalysisServerService.getErrors(file);
    }
  }

  private void processNotification(JsonObject response) {
    final JsonElement eventElement = response.get("event");
    if (eventElement == null || !eventElement.isJsonPrimitive()) {
      return;
    }
    final String event = eventElement.getAsString();
    if (event.equals(FLUTTER_NOTIFICATION_OUTLINE)) {
      final JsonObject paramsObject = response.get("params").getAsJsonObject();
      final String file = paramsObject.get("file").getAsString();

      final JsonElement instrumentedCodeElement = paramsObject.get("instrumentedCode");
      final String instrumentedCode = instrumentedCodeElement != null ? instrumentedCodeElement.getAsString() : null;

      final JsonObject outlineObject = paramsObject.get("outline").getAsJsonObject();
      final FlutterOutline outline = FlutterOutline.fromJson(outlineObject);
      log.info("outline = " + outline.toString());

    } else if (event.equals("analysis.errors")) {
      final JsonObject paramsObject = response.get("params").getAsJsonObject();
      final String file = paramsObject.get("file").getAsString();
      JsonArray errorArray = paramsObject.get("errors").getAsJsonArray();
      if (errorArray.size() > 0) {
        for (int i = 0; i < errorArray.size(); i++) {
          JsonObject error = (JsonObject) errorArray.get(i);
          String severity = error.get("severity").getAsString();
          String type = error.get("type").getAsString();
          JsonObject locationObject = error.get("location").getAsJsonObject();
          String locationFile = locationObject.get("file").getAsString();
          String locationLine = locationObject.get("startLine").getAsString();
          String locationColumn = locationObject.get("startColumn").getAsString();

          String message = error.get("message").getAsString();
          String code = error.get("code").getAsString();
          String hasFix = error.get("hasFix").getAsString();
          log.info("Error: " + i+ ": file=" + file + ", sev=" + severity +", type=" + type + ", location=" + locationFile + ":" + locationLine + "," + locationColumn + ", message=" + message + ", code="+code +", hasFix=" + hasFix);

        }
      }
    }
  }
  private void registerCompilerListener(Project project) {

    connection = project.getMessageBus().connect();
    connection.subscribe(CompilerTopics.COMPILATION_STATUS, new CompilationStatusListener() {
      @Override
      public void compilationFinished(boolean aborted, int errors, int warnings, CompileContext compileContext) {
        PacoApplicationComponent pacoAppComponent = PacoApplicationComponent.instance();

        Map<String, String> data = Maps.newHashMap();
        data.put("project", project.getName());
        data.put("compilation_overview", "aborted: " + aborted + ", error cnt: " + errors + ", warnings: " + warnings);
        addMessages(compileContext, "error", CompilerMessageCategory.ERROR, data);
        addMessages(compileContext, "information", CompilerMessageCategory.INFORMATION, data);
        addMessages(compileContext, "warning", CompilerMessageCategory.WARNING, data);
        addMessages(compileContext, "statistics", CompilerMessageCategory.STATISTICS, data);

        pacoAppComponent.appendPacoEvent(PacoIntellijEventTypes.EventType.PROJECT_COMPILATION, data);
      }
    });
  }

  private void addMessages(CompileContext compileContext, String msgType, CompilerMessageCategory category, Map<String, String> data) {
    CompilerMessage[] messages = compileContext.getMessages(category);
    log.info(compileContext.getMessageCount(category) + " " + msgType + " messages");

    for (int i = 0; i < messages.length; i++) {
      CompilerMessage message = messages[i];
      log.info((i + 1) + ": " + message.getMessage());
      data.put(msgType + "_msg_" + i, truncateMessage(message));
      if (message.getVirtualFile() != null) {
        data.put(msgType + "_file_" + i, truncateString(message.getVirtualFile().getPath()));
      }
    }
  }

  @NotNull
  private String truncateMessage(CompilerMessage message) {
    String messageText = message.getMessage();
    if (message == null || messageText == null) {
      return "message was null";
    }
    return truncateString(messageText);
  }

  @NotNull
  private String truncateString(String text) {
    if (text.length() > MAX_LENGTH_OF_ANSWER) {
      return text.substring(0, MAX_LENGTH_OF_ANSWER - 1);
    } else {
      return text;
    }
  }


  @Override
  public void projectClosed() {
    PacoApplicationComponent pacoAppComponent = PacoApplicationComponent.instance();
    Map<String, String> data = Maps.newHashMap();
    data.put("project", project.getName());
    pacoAppComponent.appendPacoEvent(PacoIntellijEventTypes.EventType.PROJECT_CLOSED, data);
    pacoAppComponent.removeRunManagerListener(project);
    pacoAppComponent.removeFileEditorManagerListener(project);
    connection.deliverImmediately();
    connection.disconnect();
    //flutterDartAnalysisServer.removeOutlineListener(outlineListenerFilePath, outlineListener);
    //dartServiceEx.removeListener(PacoProjectComponent.this::processNotification);
  }
}
