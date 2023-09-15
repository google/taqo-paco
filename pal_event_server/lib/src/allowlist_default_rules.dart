// Copyright 2023 Google LLC
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

// @dart=2.9

import 'allowlist.dart';

final chatRegex = RegExp(r'\bchat\b', caseSensitive: false);
final meetRegex = RegExp(r'\bmeet\b', caseSensitive: false);
final mailRegex = RegExp(r'\bmail\b', caseSensitive: false);
final calendarRegex = RegExp(r'\bcalendar\b', caseSensitive: false);
final googleDocsRegex = RegExp(r'\bGoogle Docs\b', caseSensitive: false);

AllowList createDefaultAllowList() {
  var list = AllowList();
  list.rules = createRules();
  return list;
}

List<AllowListRule> createRules() {
  var rules = <AllowListRule>[];
  rules.add(AllowListRule.ofAppUsed('Google-chrome'));
  rules.add(AllowListRule.ofAppUsed("Taqo"));
  rules.add(AllowListRule.ofAppUsed("Gnome terminal"));
  rules.add(AllowListRule.ofAppUsed("Terminal"));
  rules.add(AllowListRule.ofAppUsed("Alacritty"));
  rules.add(AllowListRule.ofAppUsed("Gnome-terminal"));
  rules.add(AllowListRule.ofAppUsed("Zutty"));
  rules.add(AllowListRule.ofAppUsed("XTerm"));
  rules.add(AllowListRule.ofAppUsed("UXTerm"));
  rules.add(AllowListRule.ofAppUsed("URxvt"));
  rules.add(AllowListRule.ofAppUsed("Emacs"));
  rules.add(AllowListRule.ofAppUsed("Code"));
  rules.add(AllowListRule.ofAppUsed("Gvim"));
  rules.add(AllowListRule.ofAppUsed("neovim"));
  rules.add(AllowListRule.ofAppUsed("jetbrains-idea-ce"));
  rules.add(AllowListRule.ofAppUsed("jetbrains-idea-ue"));
  rules.add(AllowListRule.ofAppUsed("jetbrains-clion"));
  rules.add(AllowListRule.ofAppUsed("jetbrains-studio"));
  rules.add(AllowListRule.ofAppUsed("Thunar"));
  rules.add(AllowListRule.ofAppUsed("org.gnome.Nautilus"));
  rules.add(AllowListRule.ofAppUsed("Firefox"));
  rules.add(AllowListRule.ofAppUsed("Firefox-esr"));
  rules.add(AllowListRule.ofAppUsed("Safari"));
  rules.add(AllowListRule.ofAppUsed("Opera"));
  rules.add(AllowListRule.ofAppUsed("Brave"));
  rules.add(AllowListRule.ofAppContent("Terminal", ".*"));
  rules.add(AllowListRule.ofAppContent("Taqo", ".*"));
  rules.add(AllowListRule.ofAppContent(".*", ".*search.*"));
  rules.add(AllowListRule.ofAppContent(".*", "Mail"));
  rules.add(AllowListRule.ofAppContent(".*", "Calendar"));
  rules.add(AllowListRule.ofAppContent(".*", "Meet"));
  rules.add(AllowListRule.ofAppContent(".*", "Chat"));
  rules.add(AllowListRule.ofAppContent(".*", "Google Docs"));
  rules.add(AllowListRule.ofAppContent("Alacritty", ".*"));
  rules.add(AllowListRule.ofAppContent("Gnome-terminal", ".*"));
  rules.add(AllowListRule.ofAppContent("Zutty", ".*"));
  rules.add(AllowListRule.ofAppContent("XTerm", ".*"));
  rules.add(AllowListRule.ofAppContent("UXTerm", ".*"));
  rules.add(AllowListRule.ofAppContent("URxvt", ".*"));
  rules.add(AllowListRule.ofAppContent("Emacs", ".*"));
  rules.add(AllowListRule.ofAppContent("Code", ".*"));
  rules.add(AllowListRule.ofAppContent("Gvim", ".*"));
  rules.add(AllowListRule.ofAppContent("neovim", ".*"));
  rules.add(AllowListRule.ofAppContent("jetbrains-idea-ce", ".*"));
  rules.add(AllowListRule.ofAppContent("jetbrains-idea-ue", ".*"));
  rules.add(AllowListRule.ofAppContent("jetbrains-clion", ".*"));
  rules.add(AllowListRule.ofAppContent("jetbrains-studio", ".*"));
  rules.add(AllowListRule.ofAppContent("Thunar", ".*"));
  rules.add(AllowListRule.ofAppContent("org.gnome.Nautilus", ".*"));
  rules.add(AllowListRule.ofAppContent(".*", "fuchsia"));
  rules.add(AllowListRule.ofAppContent(".*", "unix"));
  rules.add(AllowListRule.ofAppContent(".*", "linux"));
  rules.add(AllowListRule.ofAppContent(".*", "driver"));
  rules.add(AllowListRule.ofAppContent(".*", "android"));
  rules.add(AllowListRule.ofAppContent(".*", "android"));
  rules.add(AllowListRule.ofAppContent(".*", "test"));
  rules.add(AllowListRule.ofAppContent(".*", "error"));
  rules.add(AllowListRule.ofAppContent(".*", "rust"));
  rules.add(AllowListRule.ofAppContent(".*", "java"));
  rules.add(AllowListRule.ofAppContent(".*", "javascript"));
  rules.add(AllowListRule.ofAppContent(".*", "typescript"));
  rules.add(AllowListRule.ofAppContent(".*", "lua"));
  rules.add(AllowListRule.ofAppContent(".*", 'c\\+\\+'));
  rules.add(AllowListRule.ofAppContent(".*", "\bc\b"));
  rules.add(AllowListRule.ofAppContent(".*", "fidl"));
  rules.add(AllowListRule.ofAppContent(".*", "dart"));
  rules.add(AllowListRule.ofAppContent(".*", "risc"));
  rules.add(AllowListRule.ofAppContent(".*", "wear os"));
  rules.add(AllowListRule.ofAppContent(".*", "wearOS"));
  rules.add(AllowListRule.ofAppContent(".*", "release"));
  rules.add(AllowListRule.ofAppContent(".*", "cpp"));
  rules.add(AllowListRule.ofAppContent(".*", "llvm"));
  rules.add(AllowListRule.ofAppContent(".*", "Design"));
  rules.add(AllowListRule.ofAppContent(".*", "Decision doc"));
  rules.add(AllowListRule.ofAppContent(".*", "RFC"));
  rules.add(AllowListRule.ofAppContent(".*", "RVOS"));
  rules.add(AllowListRule.ofAppContent(".*", "Meeting notes"));
  rules.add(AllowListRule.ofAppContent(".*", "prd"));
  rules.add(AllowListRule.ofAppContent(".*", "cuj"));
  rules.add(AllowListRule.ofAppContent(".*", "research"));
  rules.add(AllowListRule.ofAppContent(".*", "decision"));
  rules.add(AllowListRule.ofAppContent(".*", "Turquoise"));
  rules.add(AllowListRule.ofAppContent(".*", "rust"));
  rules.add(AllowListRule.ofAppContent(".*", "cargo"));
  rules.add(AllowListRule.ofAppContent(".*", "test"));
  rules.add(AllowListRule.ofAppContent(".*", "Cider"));
  rules.add(AllowListRule.ofAppContent(".*", "Gerrit Code Review"));
  rules.add(AllowListRule.ofAppContent(".*", "Critique"));
  rules.add(AllowListRule.ofAppContent(".*", "Buganizer"));
  rules.add(AllowListRule.ofAppContent(".*", "YAQS eng"));
  rules.add(AllowListRule.ofAppContent(".*", "Colaboratory"));
  rules.add(AllowListRule.ofAppContent(".*", "TaskFlow"));
  rules.add(AllowListRule.ofAppContent(".*", "Eldar Assessment"));
  rules.add(AllowListRule.ofAppContent(".*", "OKRs"));
  rules.add(AllowListRule.ofAppContent(".*", "- Stack Overflow"));
  rules.add(AllowListRule.ofAppContent(".*", "Stack Exchange"));
  rules.add(AllowListRule.ofAppContent(".*", "Super User"));
  rules.add(AllowListRule.ofAppContent(".*", "Ask Ubuntu"));
  rules.add(AllowListRule.ofAppContent(".*", "Server Fault"));
  rules.add(AllowListRule.ofAppContent(".*", "Cross Validated"));
  rules.add(AllowListRule.ofAppContent(".*", "MathOverflow"));
  rules.add(AllowListRule.ofAppContent(".*", "Compiler Explorer"));
  rules.add(AllowListRule.ofAppContent(".*", "Fuchsia"));
  rules.add(AllowListRule.ofAppContent(".*", "cppreference.com"));
  rules.add(AllowListRule.ofAppContent(".*", "dremel"));
  rules.add(AllowListRule.ofAppContent(".*", "github"));
  rules.add(AllowListRule.ofAppContent(".*", "pull request"));
  rules.add(AllowListRule.ofAppContent(".*", "python"));
  rules.add(AllowListRule.ofAppContent(".*", "ruby"));
  rules.add(AllowListRule.ofAppContent(".*", "documentation"));
  return rules;
}



