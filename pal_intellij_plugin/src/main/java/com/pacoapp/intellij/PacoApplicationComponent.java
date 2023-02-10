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

import com.google.common.collect.Lists;
import com.google.common.collect.Maps;
import com.intellij.AppTopics;
import com.intellij.execution.BeforeRunTask;
import com.intellij.execution.BeforeRunTaskProvider;
import com.intellij.execution.RunManagerEx;
import com.intellij.execution.configurations.RunConfiguration;
import com.intellij.history.core.LabelImpl;
import com.intellij.openapi.actionSystem.ActionManager;
import com.intellij.openapi.actionSystem.ex.AnActionListener;
import com.intellij.openapi.application.ApplicationInfo;
import com.intellij.openapi.application.ApplicationManager;
import com.intellij.openapi.components.ApplicationComponent;
import com.intellij.openapi.editor.EditorFactory;
import com.intellij.openapi.extensions.Extensions;
import com.intellij.openapi.externalSystem.model.task.ExternalSystemTaskNotificationListener;
import com.intellij.openapi.fileEditor.FileEditorManager;
import com.intellij.openapi.project.Project;
import com.intellij.openapi.project.ProjectManager;
import com.intellij.openapi.roots.ProjectRootManager;
import com.intellij.openapi.util.BuildNumber;
import com.intellij.openapi.util.Key;
import com.intellij.openapi.vfs.VirtualFile;
import com.intellij.openapi.vfs.VirtualFileManager;
import com.intellij.util.messages.MessageBus;
import com.intellij.util.messages.MessageBusConnection;
import com.pacoapp.intellij.launch.PacoBeforeRunTask;
import com.pacoapp.intellij.launch.PacoBeforeRunTaskProvider;
import com.pacoapp.intellij.launch.PacoRunManagerListener;
import com.pacoapp.paco.UserPreferences;
import com.pacoapp.paco.net.EventUploader;
import com.pacoapp.paco.net.tesp.TespClient;
import com.pacoapp.paco.net.tesp.message.request.TespRequestAddEvent;
import com.pacoapp.paco.shared.model2.*;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.joda.time.DateTime;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.*;
import java.util.logging.Logger;

public class PacoApplicationComponent implements ApplicationComponent {

  public static final Logger log = Logger.getLogger(PacoApplicationComponent.class.getName());
  private static final boolean DEBUG = false;
  private static ExperimentDAO experiment;
  private static UserPreferences userPreferences;
  private final int queueTimeoutSeconds = 10;
  private static ConcurrentLinkedQueue<PacoEvent> pacoEventsQueue = new ConcurrentLinkedQueue<PacoEvent>();
  private static ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(1);
  private static ScheduledFuture<?> scheduledFuture;
  private MessageBusConnection connection;

  public static String lastFile = null;
  public static BigDecimal lastTime = new BigDecimal(0);
  public static final BigDecimal FREQUENCY = new BigDecimal(2l * 60); // max secs between events for continuous coding
  private MyFileEditorManagerListener fileEditorListener;
  private ExternalSystemTaskNotificationListener palTaskListener;
  private TespClient tespClient;
  private Map<Project, LabelImpl> projectLabel = Maps.newHashMap();

  public static synchronized PacoApplicationComponent instance() {
    return ApplicationManager.getApplication().getComponent(PacoApplicationComponent.class);
  }

  public static boolean shouldLogFile(VirtualFile file) {
    return true;
  }

  public static boolean enoughTimePassed() {
    BigDecimal currentTime = getCurrentTimestamp();
    return lastTime.add(FREQUENCY).compareTo(currentTime) < 0;
  }

  public static BigDecimal getCurrentTimestamp() {
    return new BigDecimal(String.valueOf(System.currentTimeMillis() / 1000.0)).setScale(4, BigDecimal.ROUND_HALF_UP);
  }


  public void initComponent() {
    userPreferences = new UserPreferences();
    initTcpClient();
    setupEventListeners();
    setupQueueProcessor();
    appendPacoEvent(PacoIntellijEventTypes.EventType.IDE_STARTED, Maps.newHashMap());
  }

  private void initTcpClient() {
    try {
      tespClient = new TespClient("127.0.0.1", 31415);
    } catch (IOException e) {
      log.warning("Could not connect to PalEventServer: " + e.getMessage());
    }
  }

  public void disposeComponent() {
    log.info("Disposing PacoApplicationComponent");
    try {
      connection.disconnect();
      if (tespClient != null) {
        tespClient.close();
      }
    } catch (Exception e) {
    }

    try {
      scheduledFuture.cancel(true);
    } catch (Exception e) {
    }
    appendPacoEvent(PacoIntellijEventTypes.EventType.IDE_STOPPED, null);
    processPacoEventQueue();
  }

  public static void appendPacoEvent(final PacoIntellijEventTypes.EventType type, final Map<String, String> data) {
    ApplicationManager.getApplication().executeOnPooledThread(new Runnable() {
      public void run() {
        PacoEvent event = PacoEventUtil.createEvent();
        List<Output> outputs = Lists.newArrayList();
        outputs.add(new Output("type", type.toString()));
        outputs.add(new Output("apps_used", getIdeVersion()));
        //TODO detect if we are in a flutter experiment to guard adding this output
        //outputs.add(new Output("ide", "IntelliJ IDEA"));0
        if (data != null && data.keySet() != null) {
          for (String name : data.keySet()) {
            String value = data.get(name);
            outputs.add(new Output(name, value));
          }
          event.setWhat(outputs);
        }
        pacoEventsQueue.add(event);
      }
    });
  }

  @NotNull
  private static String getIdeVersion() {
    String versionName = "unknown version name";
    String buildAsStr = "unkknown build label";
    ApplicationInfo instance = ApplicationInfo.getInstance();
    if (instance != null) {
      if (instance.getVersionName() != null) {
        versionName = instance.getVersionName();
      }
      if (instance.getBuild() != null) {
        BuildNumber build = instance.getBuild();
        buildAsStr = build.asString();
      }
    }
    return versionName + " " + buildAsStr;
  }


  @Nullable
  private static ExperimentDAO getExperiment() {
    if (experiment == null) {
      experiment = HardwiredExperimentCreator.loadExperiment();
    }
    return experiment;
  }

  private void setupEventListeners() {
    ApplicationManager.getApplication().executeOnPooledThread(
            new Runnable() {
      public void run() {
        MessageBus bus = ApplicationManager.getApplication().getMessageBus();
        connection = bus.connect();
        //registerDocumentSyncListener();
        registerEditorFactoryDocumentListener();
        registerFileListener();
        registerCommandListener();
        registerEditorDocumentListeners();
        registerLaunchListener();
      }
    });
  }

  private void registerEditorDocumentListeners() {
    Project[] projects = ProjectManager.getInstance().getOpenProjects();

    for (Project project : projects) {
      addFileEditorManagerListener(project);
    }
  }

  private synchronized MyFileEditorManagerListener getFileEditorListener() {
    if (fileEditorListener == null) {
      fileEditorListener = new MyFileEditorManagerListener(this);
    }
    return fileEditorListener;
  }

  public void addFileEditorManagerListener(Project project) {
    FileEditorManager fileEditorMgr = FileEditorManager.getInstance(project);

    MyFileEditorManagerListener fileEditorListener = getFileEditorListener();
    // ensure that there doesn't become multiple instances
    fileEditorMgr.removeFileEditorManagerListener(fileEditorListener);
    fileEditorMgr.addFileEditorManagerListener(fileEditorListener);
  }

  public void removeFileEditorManagerListener(Project project) {
    FileEditorManager.getInstance(project).removeFileEditorManagerListener(getFileEditorListener());
  }

  private void registerCommandListener() {
    CommandExecutionListener commandListener = new CommandExecutionListener(this);
    ActionManager.getInstance().addAnActionListener(commandListener);
  }

  private void registerFileListener() {
    FileListener fileListener = new FileListener(this);
    VirtualFileManager.getInstance().addVirtualFileListener(fileListener);
  }

  private void registerEditorFactoryDocumentListener() {
    EditorFactory.getInstance().getEventMulticaster().addDocumentListener(new DocumentListener());
  }

  private void registerDocumentSyncListener() {
    connection.subscribe(AppTopics.FILE_DOCUMENT_SYNC, new SaveListener());
  }

  private void setupQueueProcessor() {
    final Runnable handler = new Runnable() {
      public void run() {
        processPacoEventQueue();
      }
    };
    long delay = queueTimeoutSeconds;
    scheduledFuture = scheduler.scheduleAtFixedRate(handler, delay, delay, java.util.concurrent.TimeUnit.SECONDS);
  }

  private void processPacoEventQueue() {
    if (tespClient == null) {
      initTcpClient();
    }
    if (tespClient == null) {
      log.severe("cannot connect to PAL Event Server");
      return;
    }
    // get single event from queue
    ArrayList<PacoEvent> pacoEvents = new ArrayList<PacoEvent>();

    while (true) {
      PacoEvent pacoEvent = pacoEventsQueue.poll();
      if (pacoEvent == null) {
        break;
      }
      pacoEvents.add(pacoEvent);
    }
    if (!pacoEvents.isEmpty()) {
      sendPacoEvent(pacoEvents);
    }

  }

  private void sendPacoEvent(ArrayList<PacoEvent> pacoEvents) {
    String jsonEvents = PacoEventUtil.jsonify(pacoEvents);
    //    log.info("Paco Event to be sent:\n" + jsonEvents);

    final TespRequestAddEvent event = TespRequestAddEvent.withPayload(jsonEvents);

    try {
      if (tespClient == null) {
        initTcpClient();
      }
      if (tespClient == null) {
        log.severe("cannot connect to PAL Event Server");
        return;
      }
      tespClient.send(event);
    } catch (IOException e) {
      log.warning("Got exception sending pacoEvents to tcpClient: " + e.getMessage());
    }
  }

  private static void sendPacoEventDirectly(final ArrayList<PacoEvent> pacoEvents) {
    EventStore eventStore = new EventStore() {
      @Override
      public EventInterface getEvent(Long aLong, DateTime dateTime, String s, Long aLong1, Long aLong2) {
        log.info("gettEvent into EventStore");
        return null;
      }

      @Override
      public void updateEvent(EventInterface eventInterface) {
        log.info("updateEvent into EventStore");
      }

      @Override
      public void insertEvent(EventInterface eventInterface) {
        log.info("insertEvent into EventStore");
      }
    };

    new EventUploader(userPreferences.getServerAddress(), eventStore).uploadEvents(pacoEvents);
  }


  /**
   * Utility to find project information for Files sent via events.
   *
   * @param file
   * @return List<Project>
   */
  public static List<Project> projectsContainingFile(VirtualFile file) {
    Project[] openProjects = ProjectManager.getInstance().getOpenProjects();
    List<Project> projectsWithFile = Lists.newArrayList();
    for (Project project : openProjects) {
      ProjectRootManager projRootMgr = ProjectRootManager.getInstance(project);
      if (projRootMgr.getFileIndex().isInContent(file)) {
        projectsWithFile.add(project);
      }
    }
    return projectsWithFile;
  }


  // defer this to the project component instance(s)

  private void registerLaunchListener() {
//        Project[] openProjects = ProjectManager.getInstance().getOpenProjects();
//        for (Project project : openProjects) {
//            addRunManagerListener(project);
//
//        }
  }

  public void addRunManagerListener(Project project) {
    RunManagerEx projectRunManager = (RunManagerEx) RunManagerEx.getInstance(project);
    BeforeRunTaskProvider<PacoBeforeRunTask> beforeRunTaskProvider = getBeforeRunTaskProvider(project);

    projectRunManager.addRunManagerListener(new PacoRunManagerListener(projectRunManager, project, beforeRunTaskProvider));

    for (RunConfiguration runConfiguration : projectRunManager.getAllConfigurationsList()) {
      addPacoTaskToRunConfiguration(projectRunManager, runConfiguration, beforeRunTaskProvider);
    }
  }


  private BeforeRunTaskProvider<PacoBeforeRunTask> getBeforeRunTaskProvider(Project project) {
    BeforeRunTaskProvider<PacoBeforeRunTask> beforeRunTaskProvider = null;
    List<BeforeRunTaskProvider<BeforeRunTask<?>>> extensions = BeforeRunTaskProvider.EP_NAME.getExtensions(project);
    for (BeforeRunTaskProvider<? extends BeforeRunTask> extension : extensions) {
      String name = extension.getName();
      if (name.equals(PacoBeforeRunTaskProvider.EXTENSION_NAME))
        beforeRunTaskProvider = (BeforeRunTaskProvider<PacoBeforeRunTask>) extension;
    }
    return beforeRunTaskProvider;
  }

  public static void addPacoTaskToRunConfiguration(RunManagerEx projectRunManager, RunConfiguration runConfiguration, BeforeRunTaskProvider<PacoBeforeRunTask> beforeRunTaskProvider) {
    List<BeforeRunTask> beforeRunTasks = projectRunManager.getBeforeRunTasks(runConfiguration);
    if (!containsPacoListener(beforeRunTasks, beforeRunTaskProvider.getId())) {
      beforeRunTasks = new ArrayList(beforeRunTasks);
      beforeRunTasks.add(beforeRunTaskProvider.createTask(runConfiguration));
      projectRunManager.setBeforeRunTasks(runConfiguration, beforeRunTasks, true);
    }
  }

  private static boolean containsPacoListener(List<BeforeRunTask> tasks, Key<PacoBeforeRunTask> providerId) {
    for (BeforeRunTask task : tasks) {
      if (providerId.equals(task.getProviderId())) {
        return true;
      }
    }
    return false;
  }

  public void removeRunManagerListener(Project project) {
    RunManagerEx projectRunManager = (RunManagerEx) RunManagerEx.getInstance(project);
    BeforeRunTaskProvider<PacoBeforeRunTask> beforeRunTaskProvider = getBeforeRunTaskProvider(project);

    for (RunConfiguration runConfiguration : projectRunManager.getAllConfigurationsList()) {
      List<BeforeRunTask> beforeRunTasksForConfiguration = projectRunManager.getBeforeRunTasks(runConfiguration);
      beforeRunTasksForConfiguration.removeIf(task -> beforeRunTaskProvider.getId().equals(task.getProviderId()));
      projectRunManager.setBeforeRunTasks(runConfiguration, beforeRunTasksForConfiguration, true);
    }
  }


  public void store(Project project, LabelImpl label) {
    projectLabel.put(project, label);
  }

  public LabelImpl getLabel(Project project) {
    return projectLabel.get(project);
  }
}
