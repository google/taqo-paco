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
  rules.add(AllowListRule.ofAppContent(".*", "\bdriver\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bandroid\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bandroid\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\btest\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\berror\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\brust\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bjava\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bjavascript\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\btypescript\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\blua\b"));
  rules.add(AllowListRule.ofAppContent(".*", 'c\\+\\+'));
  rules.add(AllowListRule.ofAppContent(".*", "\bc\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bfidl\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bdart\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\brisc\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bwear os\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bwearOS\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\brelease\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bcpp\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bllvm\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bDesign\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bRFC\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bRVOS\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bMeeting notes\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bprd\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bcuj\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bresearch\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bdecision\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bTurquoise\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\brust\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bcargo\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\btest\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bCider\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bGerrit Code Review\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bCritique\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bBuganizer\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bYAQS eng\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bColaboratory\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bTaskFlow\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bEldar Assessment\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bOKRs\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\b- Stack Overflow\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bStack Exchange\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bSuper User\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bAsk Ubuntu\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bServer Fault\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bCross Validated\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bMathOverflow\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bCompiler Explorer\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bFuchsia\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bcppreference.com\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bdremel\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bgithub\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bpython\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bruby\b"));
  rules.add(AllowListRule.ofAppContent(".*", "\bdocumentation\b"));
  return rules;
}



