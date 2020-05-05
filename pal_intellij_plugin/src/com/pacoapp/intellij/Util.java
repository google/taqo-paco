package com.pacoapp.intellij;

import com.intellij.openapi.actionSystem.DataContext;
import com.intellij.openapi.actionSystem.DataKeys;
import com.intellij.openapi.project.Project;
import com.intellij.openapi.vcs.changes.ChangeListManager;
import com.intellij.openapi.vfs.VirtualFile;
import com.intellij.psi.PsiElement;
import org.apache.commons.lang.StringUtils;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import java.io.File;
import java.util.List;

public class Util {

  public String truncateAbsolutePath(Project project, String path) {

    String basePath = project.getBasePath();
    String difference = StringUtils.difference(basePath, path);
    String relativeToProject = File.separator + project.getName() + difference;

    return relativeToProject;
  }

  @NotNull
  public static List<VirtualFile> getAllModifiedFiles(@NotNull final DataContext dataContext) {
    final Project project = getProject(dataContext);
    final ChangeListManager changeListManager = ChangeListManager.getInstance(project);
    return changeListManager.getAffectedFiles();
  }


  @Nullable
  public static Project getProject(@NotNull final DataContext dataContext) {
    return DataKeys.PROJECT.getData(dataContext);
  }


  public static Project getProject(final PsiElement psiElement) {
    return psiElement.getProject();
  }


}
