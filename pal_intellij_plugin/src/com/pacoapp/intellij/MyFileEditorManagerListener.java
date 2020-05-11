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
