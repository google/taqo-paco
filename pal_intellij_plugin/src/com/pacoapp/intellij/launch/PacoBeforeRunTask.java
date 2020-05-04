package com.pacoapp.intellij.launch;

import com.intellij.execution.BeforeRunTask;
import com.intellij.openapi.util.Key;
import org.jetbrains.annotations.NotNull;

/**
 * Inspired heavily by code from COPE: http://cope.eecs.oregonstate.edu/index.html
 */
public class PacoBeforeRunTask extends BeforeRunTask<PacoBeforeRunTask> {

  protected PacoBeforeRunTask(@NotNull Key<PacoBeforeRunTask> providerId) {
    super(providerId);
    setEnabled(true);
  }

}
