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

import com.intellij.openapi.fileEditor.FileEditorManager;
import com.intellij.openapi.fileEditor.FileEditorManagerEvent;
import com.intellij.openapi.fileEditor.FileEditorManagerListener;
import com.intellij.openapi.vfs.VirtualFile;
import org.jetbrains.annotations.NotNull;

import java.util.HashMap;

public class MyFileEditorManagerListener implements FileEditorManagerListener {
  private final PacoApplicationComponent pacoApplicationComponent;

  public MyFileEditorManagerListener(PacoApplicationComponent pacoApplicationComponent) {
    this.pacoApplicationComponent = pacoApplicationComponent;

  }

  @Override
  public void fileOpened(@NotNull FileEditorManager source, @NotNull VirtualFile file) {
    HashMap<String, String> data = FileListener.getDataMapWithFileAdded(file);
    pacoApplicationComponent.appendPacoEvent(PacoIntellijEventTypes.EventType.DOCUMENT_OPENED, data);
  }

  @Override
  public void fileClosed(@NotNull FileEditorManager source, @NotNull VirtualFile file) {
    HashMap<String, String> data = FileListener.getDataMapWithFileAdded(file);
    pacoApplicationComponent.appendPacoEvent(PacoIntellijEventTypes.EventType.DOCUMENT_CLOSED, data);
  }

  @Override
  public void selectionChanged(@NotNull FileEditorManagerEvent event) {
    HashMap<String, String> data = FileListener.getDataMapWithFileAdded(event.getNewFile());
    pacoApplicationComponent.appendPacoEvent(PacoIntellijEventTypes.EventType.DOCUMENT_FOCUSED, data);
  }

  private String getPath(VirtualFile file) {
    return file.getCanonicalPath();
  }
}
