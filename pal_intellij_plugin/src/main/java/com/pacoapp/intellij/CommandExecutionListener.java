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
import com.google.common.collect.Sets;
import com.google.common.io.Files;
import com.intellij.codeInsight.TargetElementUtil;
import com.intellij.history.core.LabelImpl;
import com.intellij.history.core.LocalHistoryFacade;
import com.intellij.history.integration.IdeaGateway;
import com.intellij.history.integration.LocalHistoryImpl;
import com.intellij.history.integration.LocalHistoryUtilSubclass;
import com.intellij.history.integration.ui.models.DirectoryHistoryDialogModel;
import com.intellij.openapi.actionSystem.AnAction;
import com.intellij.openapi.actionSystem.AnActionEvent;
import com.intellij.openapi.actionSystem.CommonDataKeys;
import com.intellij.openapi.actionSystem.DataContext;
import com.intellij.openapi.actionSystem.ex.AnActionListener;
import com.intellij.openapi.diff.impl.patch.FilePatch;
import com.intellij.openapi.diff.impl.patch.IdeaTextPatchBuilder;
import com.intellij.openapi.editor.Document;
import com.intellij.openapi.editor.Editor;
import com.intellij.openapi.editor.SelectionModel;
import com.intellij.openapi.editor.actions.*;
import com.intellij.openapi.fileEditor.FileDocumentManager;
import com.intellij.openapi.project.Project;
import com.intellij.openapi.vcs.VcsException;
import com.intellij.openapi.vcs.changes.CommitContext;
import com.intellij.openapi.vcs.changes.patch.PatchWriter;
import com.intellij.openapi.vfs.VirtualFile;
import com.intellij.psi.PsiElement;
import org.joda.time.DateTime;
import org.joda.time.format.DateTimeFormat;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.file.Path;
import java.util.*;
import java.util.logging.Logger;

public class CommandExecutionListener implements AnActionListener {



  public static final Logger log = Logger.getLogger(CommandExecutionListener.class.getName());
  public static final String DATE_TIME_FORMAT = "yyyy_MM_dd_HH:mm:ssZ";
  private final PacoApplicationComponent pacoApplicationComponent;

  private static boolean cutInProgress = false;
  private static boolean pasteInProgress = false;
  private static boolean undoInProgress = false;
  private static boolean redoInProgress = false;
  public static final Set<Class<? extends AnAction>> CURSOR_ACTIONS = Sets.newLinkedHashSet();
  static {
    CURSOR_ACTIONS.add(MoveCaretDownAction.class);
    CURSOR_ACTIONS.add(MoveCaretDownWithSelectionAction.class);
    CURSOR_ACTIONS.add(MoveCaretLeftAction.class);
    CURSOR_ACTIONS.add(MoveCaretLeftWithSelectionAction.class);
    CURSOR_ACTIONS.add(MoveCaretRightAction.class);
    CURSOR_ACTIONS.add(MoveCaretRightWithSelectionAction.class);
    CURSOR_ACTIONS.add(MoveCaretUpAction.class);
    CURSOR_ACTIONS.add(MoveCaretUpWithSelectionAction.class);
    CURSOR_ACTIONS.add(NextWordAction.class);
    CURSOR_ACTIONS.add(NextWordWithSelectionAction.class);
    CURSOR_ACTIONS.add(PreviousWordAction.class);
    CURSOR_ACTIONS.add(PreviousWordWithSelectionAction.class);
    CURSOR_ACTIONS.add(PageBottomAction.class);
    CURSOR_ACTIONS.add(PageBottomWithSelectionAction.class);
    CURSOR_ACTIONS.add(PageDownAction.class);
    CURSOR_ACTIONS.add(PageDownWithSelectionAction.class);
    CURSOR_ACTIONS.add(PageTopAction.class);
    CURSOR_ACTIONS.add(PageTopWithSelectionAction.class);
    CURSOR_ACTIONS.add(PageUpAction.class);
    CURSOR_ACTIONS.add(PageUpWithSelectionAction.class);
    CURSOR_ACTIONS.add(LineEndAction.class);
    CURSOR_ACTIONS.add(LineEndWithSelectionAction.class);
    CURSOR_ACTIONS.add(LineStartAction.class);
    CURSOR_ACTIONS.add(LineStartWithSelectionAction.class);
    CURSOR_ACTIONS.add(BackspaceAction.class);
    CURSOR_ACTIONS.add(EnterAction.class);
  }

  public CommandExecutionListener(PacoApplicationComponent pacoApplicationComponent) {
    this.pacoApplicationComponent = pacoApplicationComponent;
  }

  protected void scheduleRevisionsUpdate(Project project, LocalHistoryFacade.Listener listener) {
    LocalHistoryFacade facade = LocalHistoryImpl.getInstanceImpl().getFacade();
    IdeaGateway gateway = LocalHistoryImpl.getInstanceImpl().getGateway();
    VirtualFile projectBaseDir = project.getBaseDir();

    String dateTimeString = getDateTimeString();

    try {
      LabelImpl storedLabel = pacoApplicationComponent.getLabel(project);
      DirectoryHistoryDialogModel myModel = new DirectoryHistoryDialogModel(project, gateway, facade, projectBaseDir.findChild("lib"));
      List<FilePatch> patchesLib = Lists.newArrayList();
      if (myModel == null || storedLabel == null) {
        log.severe("There is either no model or no label for doing scheduleRevisionsUpdate. myModel: "
                + (myModel != null)
                + ", label: " + (storedLabel != null));
      } else {
        int index = LocalHistoryUtilSubclass.findRevisionIndexToRevert(myModel, storedLabel);
        System.out.println("index value for label, " + storedLabel.toString() + ",= " + index);
        if (index >= 1) {
          myModel.clearRevisions();
          myModel.selectRevisions(-1, index);
          patchesLib.addAll(IdeaTextPatchBuilder.buildPatch(project, myModel.getChanges(), projectBaseDir + "/lib", false));
        }

        myModel = new DirectoryHistoryDialogModel(project, gateway, facade, projectBaseDir.findChild("test"));
        index = LocalHistoryUtilSubclass.findRevisionIndexToRevert(myModel, storedLabel);
        System.out.println("index value for label, " + storedLabel.toString() + ",= " + index);
        if (index >= 1) {
          myModel.clearRevisions();
          myModel.selectRevisions(-1, index); // set to 0, maybe, there is some weirdness in selecting revisions. Labels make revisions too.
          List<FilePatch> patchesTest = IdeaTextPatchBuilder.buildPatch(project, myModel.getChanges(), projectBaseDir + "/test", false);
          patchesLib.addAll(patchesTest);
        }
        if (patchesLib.size() > 0) {
          Path basePath = projectBaseDir.toNioPath();
          Path patchFilePath = new File(Files.createTempDir(), "patch" + getDateTimeString() + ".patch").toPath();
          System.out.println("patch location: " + patchFilePath.toString());

          PatchWriter.writePatches(project, patchFilePath, basePath, patchesLib, (CommitContext) null, Charset.defaultCharset(), false);
          String patchBufferEncoded = "textdiff===" + base64EncodeFileContents(patchFilePath.toString());
          Map<String, String> data = Maps.newHashMap();
          data.put("diff_file", patchFilePath.toString());
          data.put("project", project.getName());
          data.put("project_dir", project.getBasePath());
          data.put("diff", patchBufferEncoded);
          PacoApplicationComponent.appendPacoEvent(PacoIntellijEventTypes.EventType.DIFF, data);
        }
      }
    } catch (VcsException e) {
      e.printStackTrace();
    } catch (IOException e) {
      e.printStackTrace();
    }

    LabelImpl newLabel = facade.putSystemLabel("pal_baseline_" + dateTimeString, project.getLocationHash(), -1);
    pacoApplicationComponent.store(project, newLabel);
  }

  private String base64EncodeFileContents(String patchFilePath) throws IOException {
    FileInputStream fi = new FileInputStream(new File(patchFilePath));
      ByteArrayOutputStream os = new ByteArrayOutputStream();
      byte[] buffer = new byte[0xFFFF];
      for (int len = fi.read(buffer); len != -1; len = fi.read(buffer)) {
        os.write(buffer, 0, len);
      }
    return Base64.getEncoder().encodeToString(os.toByteArray());
  }

  private String getDateTimeString() {
    return DateTime.now().toString(DateTimeFormat.forPattern(DATE_TIME_FORMAT));
  }

  @Override
  public void beforeActionPerformed(AnAction anAction, DataContext dataContext, AnActionEvent event) {
    if (isCopy(anAction)) {
      recordCopy(dataContext, event);
    } else if (isCut(anAction)) {
      cutInProgress = true;
    } else if (isPaste(anAction)) {
      pasteInProgress = true;
    } else if (isUndo(anAction)) {
      undoInProgress = true;
    } else if (isRedo(anAction)) {
      redoInProgress = true;
    } else {
      Class<? extends AnAction> actionType = anAction.getClass();
      if (cursorMovementAction(actionType)) {
        // TODO update programming heartbeat
        return;
      }
      log.info("Action type = " + actionType.getName());
      Editor editor = CommonDataKeys.EDITOR.getData(dataContext);

      VirtualFile file = null;
      String elementUnderCursor = null;
      if (editor != null) {
        file = getFile(editor);
        TargetElementUtil targetElementUtil = TargetElementUtil.getInstance();
        PsiElement targetElement = targetElementUtil.findTargetElement(editor, targetElementUtil.getAllAccepted());
        elementUnderCursor = targetElement != null ? targetElement.getText() : "no element";
      }

      String place = event.getPlace();
      Map<String, String> data = null;
      if (file != null) {
        data = FileListener.getDataMapWithFileAdded(file);
      } else {
        data = Maps.newHashMap();
      }
      //data.put("event", event.toString());
      data.put("action_label", anAction.toString());
      data.put("action_class", anAction.getClass().getName());
      data.put("place", place);
      if (!actionType.getClass().getName().equals("com.intellij.execution.ExecutorRegistryImpl$ExecutorAction")) {
        // with this action, it can put the whole file contents in element. that's too much.
        data.put("element", elementUnderCursor);
      }
      // TODO get the parent element so we can determine isDart library or isFlutter library symbol
//PsiTreeUtil.getNonStrictParentOfType(event.getData(LangDataKeys.PSI_FILE).findElementAt(editor.getCaretModel().getOffset()), PsiClass.class)
      addAnySelectionData(editor, data);
      pacoApplicationComponent.appendPacoEvent(PacoIntellijEventTypes.EventType.IDE_ACTION, data);
      if (!isActionFencePostForDiffing(anAction)) {
        return;
      } else {
        createProjectCodeDiff(event.getProject());
      }
    }
  }

  private void createProjectCodeDiff(Project project) {
    scheduleRevisionsUpdate(project, null);
  }

  private boolean isActionFencePostForDiffing(AnAction anAction) {
    return anAction.getClass().getName().equals("com.intellij.execution.ExecutorRegistryImpl$ExecutorAction") ||
            anAction.getClass().getName().equals("io.flutter.actions.ReloadFlutterAppRetarget");
  }

  private boolean cursorMovementAction(Class<? extends AnAction> actionClass) {
    return CURSOR_ACTIONS.contains(actionClass);
  }

  @Override
  public void afterActionPerformed(AnAction action, DataContext dataContext, AnActionEvent event) {
    if (isCut(action)) {
      cutInProgress = false;
      recordCut(dataContext, event);
    } else if (isPaste(action)) {
      pasteInProgress = false;
      recordPaste(dataContext, event);
    } else if (isUndo(action)) {
      undoInProgress = false;
      recordUndo(dataContext, event);
    } else if (isRedo(action)) {
      redoInProgress = false;
      recordRedo(dataContext, event);
    } else {
      //log.info("After Action: " + event.toString());
    }
  }

  @Override
  public void beforeEditorTyping(char c, DataContext dataContext) {

  }

  private boolean isCopy(AnAction action) {
    return action instanceof com.intellij.ide.actions.CopyAction
            || action instanceof com.intellij.openapi.editor.actions.CopyAction;
  }

  private boolean isCut(AnAction action) {
    return action instanceof com.intellij.ide.actions.CutAction
            || action instanceof com.intellij.openapi.editor.actions.CutAction;
  }

  private boolean isPaste(AnAction action) {
    return action instanceof com.intellij.ide.actions.PasteAction
            || action instanceof com.intellij.openapi.editor.actions.PasteAction
            || action instanceof com.intellij.openapi.editor.actions.SimplePasteAction
            || action instanceof com.intellij.openapi.editor.actions.MultiplePasteAction;
  }

  private boolean isUndo(AnAction action) {
    return action instanceof com.intellij.ide.actions.UndoAction;
  }

  private boolean isRedo(AnAction action) {
    return action instanceof com.intellij.ide.actions.RedoAction;
  }

  private void recordCopy(DataContext dataContext, AnActionEvent anActionEvent) {
    Editor editor = CommonDataKeys.EDITOR.getData(dataContext);
    if (editor == null || getFile(editor) == null) {
      return;
    }
    VirtualFile path = getFile(editor);
    HashMap<String, String> data = FileListener.getDataMapWithFileAdded(path);
    addAnySelectionData(editor, data);
    pacoApplicationComponent.appendPacoEvent(PacoIntellijEventTypes.EventType.COPY_ACTION, data);
  }

  private void addAnySelectionData(Editor editor, Map<String, String> data) {
    if (editor == null || editor.getSelectionModel() == null || !editor.getSelectionModel().hasSelection()) {
      return;
    }
    SelectionModel selection = editor.getSelectionModel();
    String selectedText = selection.getSelectedText();
    if (selectedText != null) {
      data.put("selection_chars", String.valueOf(selectedText.length()));
      data.put("selection_lines", String.valueOf(lineCount(selectedText)));
      data.put("selection_text", selectedText);
      data.put("selection_start", Integer.toString(selection.getSelectionStart()));
    }
  }

  private int lineCount(String selectedText) {
    if (selectedText == null) {
      return 0;
    }
    if (selectedText.indexOf('\n') == -1) {
      return 1;
    }
    String[] selectedTextLinesArr = selectedText.split("\n");

    int selectedTextLineCount = 0;
    for (int i = 0; i < selectedTextLinesArr.length; i++) {
      if (selectedTextLinesArr[i].length() > 0) {
        selectedTextLineCount++;
      }
    }
    return selectedTextLineCount;
  }

  private void recordCut(DataContext dataContext, AnActionEvent anActionEvent) {
    Editor editor = CommonDataKeys.EDITOR.getData(dataContext);
    if (editor == null || getFile(editor) == null) {
      return;
    }
    HashMap<String, String> data = FileListener.getDataMapWithFileAdded(getFile(editor));
    addAnySelectionData(editor, data);
    pacoApplicationComponent.appendPacoEvent(PacoIntellijEventTypes.EventType.CUT_ACTION, data);
  }

  private void recordPaste(DataContext dataContext, AnActionEvent anActionEvent) {
    Editor editor = CommonDataKeys.EDITOR.getData(dataContext);
    if (editor == null || getFile(editor) == null) {
      return;
    }
    HashMap<String, String> data = FileListener.getDataMapWithFileAdded(getFile(editor));
    addAnySelectionData(editor, data);
    pacoApplicationComponent.appendPacoEvent(PacoIntellijEventTypes.EventType.PASTE_ACTION, data);
  }

  private void recordUndo(DataContext dataContext, AnActionEvent anActionEvent) {
    Editor editor = CommonDataKeys.EDITOR.getData(dataContext);
    if (editor == null || getFile(editor) == null) {
      return;
    }
    HashMap<String, String> data = FileListener.getDataMapWithFileAdded(getFile(editor));
    addAnySelectionData(editor, data);
    pacoApplicationComponent.appendPacoEvent(PacoIntellijEventTypes.EventType.UNDO_ACTION, data);
  }

  private void recordRedo(DataContext dataContext, AnActionEvent anActionEvent) {
    Editor editor = CommonDataKeys.EDITOR.getData(dataContext);
    if (editor == null || getFile(editor) == null) {
      return;
    }
    HashMap<String, String> data = FileListener.getDataMapWithFileAdded(getFile(editor));
    addAnySelectionData(editor, data);
    pacoApplicationComponent.appendPacoEvent(PacoIntellijEventTypes.EventType.REDO_ACTION, data);
  }


  private VirtualFile getFile(Editor editor) {
    Document document = editor.getDocument();
    if (document == null) {
      return null;
    }
    return FileDocumentManager.getInstance().getFile(document);
  }

}
