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
