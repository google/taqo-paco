package com.intellij.history.integration;

import com.intellij.history.core.LabelImpl;
import com.intellij.history.core.revisions.ChangeRevision;
import com.intellij.history.core.revisions.Revision;
import com.intellij.history.integration.ui.models.HistoryDialogModel;
import com.intellij.history.integration.ui.models.RevisionItem;
import com.intellij.util.containers.ContainerUtil;
import org.jetbrains.annotations.NotNull;

import java.util.List;

public class LocalHistoryUtilSubclass {
  public static int findRevisionIndexToRevert(@NotNull HistoryDialogModel dirHistoryModel, @NotNull LabelImpl label) {
    if (dirHistoryModel == null) {
      throw new IllegalArgumentException("null dirHistoryModel");
    }

    if (label == null) {
      throw new IllegalArgumentException("null label");
    }

    List<RevisionItem> revs = dirHistoryModel.getRevisions();

    for(int i = 0; i < revs.size(); ++i) {
      RevisionItem rev = (RevisionItem)revs.get(i);
      if (isLabelRevision(rev, label)) {
        return i;
      }

      if (isChangeWithId(rev.revision, label.getLabelChangeId())) {
        return i;
      }
    }

    return -1;
  }


  static boolean isLabelRevision(@NotNull RevisionItem rev, @NotNull LabelImpl label) {
    if (rev == null) {
      throw new IllegalArgumentException("rev null");
    }

    if (label == null) {
      throw new IllegalArgumentException("label null");
    }

    long targetChangeId = label.getLabelChangeId();
    return ContainerUtil.exists(rev.labels, (revision) -> {
      return isChangeWithId(revision, targetChangeId);
    });
  }

  private static boolean isChangeWithId(@NotNull Revision revision, long targetChangeId) {
    if (revision == null) {
      throw new IllegalArgumentException("revision null");
    }

    return revision instanceof ChangeRevision && ((ChangeRevision)revision).containsChangeWithId(targetChangeId);
  }

}
