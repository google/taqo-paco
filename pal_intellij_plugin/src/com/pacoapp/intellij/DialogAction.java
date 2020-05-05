package com.pacoapp.intellij;

import com.intellij.openapi.actionSystem.AnAction;
import com.intellij.openapi.actionSystem.AnActionEvent;
import com.intellij.openapi.actionSystem.PlatformDataKeys;
import com.intellij.openapi.project.Project;
import com.intellij.openapi.ui.Messages;
import com.intellij.openapi.vfs.VirtualFile;

public class DialogAction extends AnAction {

  public DialogAction() {
    super("Dialogs for the win!");
  }

  @Override
  public void actionPerformed(AnActionEvent event) {
    Project project = event.getData(PlatformDataKeys.PROJECT);
    VirtualFile projFile = project.getProjectFile();
    String projFilePath = projFile.getCanonicalPath();
    String txt = Messages.showInputDialog(project, "What is your name?", "Input your name", Messages.getQuestionIcon());
    Messages.showMessageDialog(project, "Hello, " + txt + "!\n I am glad to see you.", "Information about project: " + projFilePath, Messages.getInformationIcon());

  }
}
