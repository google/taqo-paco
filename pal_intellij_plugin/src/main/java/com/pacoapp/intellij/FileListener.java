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
import com.intellij.openapi.project.Project;
import com.intellij.openapi.project.ProjectManager;
import com.intellij.openapi.vfs.*;
import org.jetbrains.annotations.NotNull;

import java.util.HashMap;
import java.util.List;

public class FileListener implements VirtualFileListener {
  private final PacoApplicationComponent pacoAppComponent;

  public FileListener(PacoApplicationComponent pacoApplicationComponent) {
    this.pacoAppComponent = pacoApplicationComponent;
  }

  @Override
  public void propertyChanged(@NotNull VirtualFilePropertyEvent event) {
    System.out.println("FileListener propertyChanged " + event.getPropertyName() + "," + event.toString());
  }

  @Override
  public void contentsChanged(@NotNull VirtualFileEvent event) {
    if (event.isFromRefresh()) {
      recordRefresh(event);
    } else if (event.isFromSave()) {
      recordSave(event);
    }
  }

  @Override
  public void fileCreated(@NotNull VirtualFileEvent event) {
    VirtualFile file = event.getFile();
    String fileContents = getFileContents(file);
    HashMap<String, String> data = getDataMapWithFileAdded(event.getFile());
    data.put("edit", fileContents);
    pacoAppComponent.appendPacoEvent(PacoIntellijEventTypes.EventType.DOCUMENT_CREATED, data);
  }

  public static HashMap<String, String> getDataMapWithFileAdded(VirtualFile filePath) {
    HashMap<String, String> data = Maps.newHashMap();
    if (filePath != null) {
      data.put("file", filePath.getCanonicalPath());
      data.put("file_type", filePath.getFileType().getName());
    }
    return data;
  }

  @Override
  public void fileDeleted(@NotNull VirtualFileEvent event) {
    HashMap<String, String> data = getDataMapWithFileAdded(event.getFile());
    pacoAppComponent.appendPacoEvent(PacoIntellijEventTypes.EventType.DOCUMENT_DELETED, data);
  }

  @Override
  public void fileMoved(@NotNull VirtualFileMoveEvent event) {
    HashMap<String, String> data = getDataMapWithFileAdded(event.getFile());
    pacoAppComponent.appendPacoEvent(PacoIntellijEventTypes.EventType.DOCUMENT_MOVED, data);
  }

  @Override
  public void fileCopied(@NotNull VirtualFileCopyEvent event) {
    HashMap<String, String> data = getDataMapWithFileAdded(event.getFile());
    pacoAppComponent.appendPacoEvent(PacoIntellijEventTypes.EventType.DOCUMENT_COPIED, data);
  }


  private void recordSave(VirtualFileEvent event) {
    VirtualFile file = event.getFile();
    String filePath = file.getCanonicalPath();
    HashMap<String, String> data = getDataMapWithFileAdded(file);
    Project[] projects = ProjectManager.getInstance().getOpenProjects();
    Project foundProject = null;
    for (int i = 0; i < projects.length; i++) {
      Project project = projects[i];
      String projectPath = project.getBaseDir().getCanonicalPath();
      if (filePath.startsWith(projectPath)) {
        foundProject = project;
      }
    }
    pacoAppComponent.appendPacoEvent(PacoIntellijEventTypes.EventType.DOCUMENT_SAVED, data);
  }

  private void recordRefresh(VirtualFileEvent event) {
    return;
    // TODO remove DOCUMENT_REFRESH events - too noisy
//    String fileContents = getFileContents(event.getFile());
//    HashMap<String, String> data = getDataMapWithFileAdded(event.getFile());
//    data.put("edit", fileContents);
//    pacoAppComponent.appendPacoEvent(PacoIntellijEventTypes.EventType.DOCUMENT_REFRESHED, data);
  }

  private String getFileContents(VirtualFile file) {
    return "...content elided...";
  }

}
