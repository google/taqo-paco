package com.pacoapp.intellij;

import com.intellij.openapi.editor.event.DocumentEvent;
import com.intellij.openapi.vfs.VirtualFile;
import org.jetbrains.annotations.NotNull;

import java.util.HashMap;

public class DocumentListener implements com.intellij.openapi.editor.event.DocumentListener {

  boolean recordMicroChanges = false;
  boolean bufferChanges = false;

  @Override
  public void beforeDocumentChange(DocumentEvent documentEvent) {
  }

  @Override
  public void documentChanged(DocumentEvent documentEvent) {
    return;

    // skip these micro edits for now.
//    final FileDocumentManager instance = FileDocumentManager.getInstance();
//    final VirtualFile file = instance.getFile(documentEvent.getDocument());
//    if (file != null && !file.getUrl().startsWith("mock://")) {
//      if (PacoApplicationComponent.shouldLogFile(file)) {
//        if (recordMicroChanges) {
//          recordChange(documentEvent, file);
//        } else if (bufferChanges) {
//          addChangeToBuffer(documentEvent, file);
//        }
//      }
//    }
  }

  private void addChangeToBuffer(DocumentEvent documentEvent, VirtualFile file) {
    HashMap<String, String> data = collectChangeData(documentEvent, file);
    // TODO documentChangeBuffer.add(data);
  }

  private void recordChange(DocumentEvent documentEvent, VirtualFile file) {
    HashMap<String, String> data = collectChangeData(documentEvent, file);
    PacoApplicationComponent.appendPacoEvent(PacoIntellijEventTypes.EventType.DOCUMENT_CHANGED, data);
  }

  @NotNull
  private HashMap<String, String> collectChangeData(DocumentEvent documentEvent, VirtualFile file) {
    HashMap<String, String> data = FileListener.getDataMapWithFileAdded(file);
    CharSequence newText = documentEvent.getNewFragment();
    CharSequence oldText = documentEvent.getOldFragment();
//    data.put("old_text", oldText.toString());
//    data.put("new_text", newText.toString());
    data.put("start", Integer.toString(documentEvent.getOffset()));
    data.put("length", Integer.toString(documentEvent.getOldLength()));
    return data;
  }
}
