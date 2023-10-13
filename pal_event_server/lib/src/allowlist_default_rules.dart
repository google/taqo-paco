// Copyright 2023 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the 'License');
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an 'AS IS' BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// @dart=2.9

import 'allowlist.dart';

final chatRegex = RegExp(r'\bchat\b', caseSensitive: false);
final meetRegex = RegExp(r'\bmeet\b', caseSensitive: false);
final mailRegex = RegExp(r'\bmail\b', caseSensitive: false);
final calendarRegex = RegExp(r'\bcalendar\b', caseSensitive: false);
final slidesRegex = RegExp(r'\bslides\b', caseSensitive: false);
final sheetsRegex = RegExp(r'\bsheets\b', caseSensitive: false);
final googleDocsRegex = RegExp(r'\bGoogle Docs\b', caseSensitive: false);
final momaRegex = RegExp(r'\bMoma Search\b', caseSensitive: false);

AllowList createDefaultAllowList() {
  var list = AllowList();
  list.rules = createRules();
  return list;
}

List<AllowListRule> createRules() {
  var rules = <AllowListRule>[];
  rules.add(AllowListRule.ofAppUsed(r'Google-chrome'));
  rules.add(AllowListRule.ofAppUsed(r'Google Chrome'));
  rules.add(AllowListRule.ofAppUsed(r'Google Chat'));
  rules.add(AllowListRule.ofAppUsed(r'Taqo'));
  rules.add(AllowListRule.ofAppUsed(r'Gnome terminal'));
  rules.add(AllowListRule.ofAppUsed(r'Terminal'));
  rules.add(AllowListRule.ofAppUsed(r'Alacritty'));
  rules.add(AllowListRule.ofAppUsed(r'Gnome-terminal'));
  rules.add(AllowListRule.ofAppUsed(r'Zutty'));
  rules.add(AllowListRule.ofAppUsed(r'XTerm'));
  rules.add(AllowListRule.ofAppUsed(r'UXTerm'));
  rules.add(AllowListRule.ofAppUsed(r'URxvt'));
  rules.add(AllowListRule.ofAppUsed(r'iTerm2'));
  rules.add(AllowListRule.ofAppUsed(r'Emacs'));
  rules.add(AllowListRule.ofAppUsed(r'Code'));
  rules.add(AllowListRule.ofAppUsed(r'Gvim'));
  rules.add(AllowListRule.ofAppUsed(r'neovim'));
  rules.add(AllowListRule.ofAppUsed(r'TextEdit'));
  rules.add(AllowListRule.ofAppUsed(r'jetbrains-idea-ce'));
  rules.add(AllowListRule.ofAppUsed(r'jetbrains-idea-ue'));
  rules.add(AllowListRule.ofAppUsed(r'jetbrains-clion'));
  rules.add(AllowListRule.ofAppUsed(r'jetbrains-studio'));
  rules.add(AllowListRule.ofAppUsed(r'IntelliJ IDEA'));
  rules.add(AllowListRule.ofAppUsed(r'Thunar'));
  rules.add(AllowListRule.ofAppUsed(r'Finder'));
  rules.add(AllowListRule.ofAppUsed(r'Calculator'));
  rules.add(AllowListRule.ofAppUsed(r'org.gnome.Nautilus'));
  rules.add(AllowListRule.ofAppUsed(r'Firefox'));
  rules.add(AllowListRule.ofAppUsed(r'Firefox-esr'));
  rules.add(AllowListRule.ofAppUsed(r'Safari'));
  rules.add(AllowListRule.ofAppUsed(r'Opera'));
  rules.add(AllowListRule.ofAppUsed(r'Brave'));
  rules.add(AllowListRule.ofAppContent(r'Terminal', r'.*'));
  rules.add(AllowListRule.ofAppContent(r'Taqo', r'.*'));
  rules.add(AllowListRule.ofAppContent(r'.*', 'Mail'));
  rules.add(AllowListRule.ofAppContent(r'.*', 'Google Calendar'));
  rules.add(AllowListRule.ofAppContent(r'.*', 'Meet'));
  rules.add(AllowListRule.ofAppContent(r'.*', 'Chat'));
  rules.add(AllowListRule.ofAppContent(r'.*', 'Google Docs'));
  rules.add(AllowListRule.ofAppContent(r'.*', 'Google Slides'));
  rules.add(AllowListRule.ofAppContent(r'.*', 'Google Sheets'));
  rules.add(AllowListRule.ofAppContent(r'.*', 'Moma Search'));
  rules.add(AllowListRule.ofAppContent(r'Alacritty', r'.*'));
  rules.add(AllowListRule.ofAppContent(r'Gnome-terminal', r'.*'));
  rules.add(AllowListRule.ofAppContent(r'Zutty', r'.*'));
  rules.add(AllowListRule.ofAppContent(r'XTerm', r'.*'));
  rules.add(AllowListRule.ofAppContent(r'UXTerm', r'.*'));
  rules.add(AllowListRule.ofAppContent(r'URxvt', r'.*'));
  rules.add(AllowListRule.ofAppContent(r'iTerm2', r'.*'));
  rules.add(AllowListRule.ofAppContent(r'Emacs', r'.*'));
  rules.add(AllowListRule.ofAppContent(r'Code', r'.*'));
  rules.add(AllowListRule.ofAppContent(r'Gvim', r'.*'));
  rules.add(AllowListRule.ofAppContent(r'neovim', r'.*'));
  rules.add(AllowListRule.ofAppContent(r'TextEdit', r'.*'));
  rules.add(AllowListRule.ofAppContent(r'jetbrains-idea-ce', r'.*'));
  rules.add(AllowListRule.ofAppContent(r'jetbrains-idea-ue', r'.*'));
  rules.add(AllowListRule.ofAppContent(r'jetbrains-clion', r'.*'));
  rules.add(AllowListRule.ofAppContent(r'jetbrains-studio', r'.*'));
  rules.add(AllowListRule.ofAppContent(r'IntelliJ IDEA', r'.*'));
  rules.add(AllowListRule.ofAppContent(r'Thunar', r'.*'));
  rules.add(AllowListRule.ofAppContent(r'Finder', r'.*'));
  rules.add(AllowListRule.ofAppContent(r'org.gnome.Nautilus', r'.*'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bfuchsia\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bunix\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\blinux\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bdriver\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bdeveloper\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bandroid\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\btest\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\berror\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\brust\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bjava\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bjavascript\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\btypescript\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\blua\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'c\\+\\+'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bc\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bfidl\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bdart\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\brisc\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\barm\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bintel\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bnvidia\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bwear os\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bwearOS\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\brelease\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bcpp\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bllvm\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bDesign\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bDecision doc\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bRFC\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bRVOS\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bMeeting notes\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bprd\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bcuj\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bresearch\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bdecision\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bTurquoise\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\brust\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bcargo\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\btest\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bCider\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bGerrit Code Review\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bCritique\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bMonorail\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bgPaste\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bkeep-sorted\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bLUCI\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bYAQS\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bTaskFlow\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bBuganizer\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bYAQS eng\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bColaboratory\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bTaskFlow\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bOKRs\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\b- Stack Overflow\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bStack Exchange\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bSuper User\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bAsk Ubuntu\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bServer Fault\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bCross Validated\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bMathOverflow\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bCompiler Explorer\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bFuchsia\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bcppreference.com\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bdremel\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bgithub\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bgitter\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bpull request\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bpython\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bruby\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bdocumentation\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bruff\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bdjango\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bdocs.rs\b'));
  rules.add(AllowListRule.ofAppContent(r'.*', r'\bGN Reference\b'));
  return rules;
}
