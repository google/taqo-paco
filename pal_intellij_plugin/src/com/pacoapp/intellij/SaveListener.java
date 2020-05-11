package com.pacoapp.intellij;

import com.intellij.openapi.editor.Document;
import com.intellij.openapi.fileEditor.FileDocumentManager;
import com.intellij.openapi.fileEditor.FileDocumentManagerAdapter;
import com.intellij.openapi.vfs.VirtualFile;

import java.util.HashMap;

public class SaveListener extends FileDocumentManagerAdapter {

  @Override
  public void beforeDocumentSaving(Document document) {
    VirtualFile file = FileDocumentManager.getInstance().getFile(document);
    if (PacoApplicationComponent.shouldLogFile(file)) {
      HashMap<String, String> data = FileListener.getDataMapWithFileAdded(file);
      PacoApplicationComponent.appendPacoEvent(PacoIntellijEventTypes.EventType.DOCUMENT_SAVED, data);
    }
  }

}
