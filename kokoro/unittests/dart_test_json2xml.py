#!/usr/bin/env python3
# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Convert json output of Dart tests into XML format

The script will read a stream of jsons from stdin or a log file and output
converted XML into stdout. If read from stdin, it will use the time of the first
line as the test start time. If read from file, it will use "ctime" of the file
as the test start time.

Usage:
  "<script_name>" or "<script_name> -" will read from stdin
  "<script_name> <file_name>" will read from the file <file_name>
"""

from collections import defaultdict
from datetime import datetime, timedelta, timezone
from enum import IntEnum
import fileinput
import json
from typing import Iterable
from lxml import etree
import os
import sys


class TestElement:
  """ Abstract and base class for test elements in the XML output

  Classes corresponding to "testsuites", "testsuite", and "testcase" XML
  elements should inherit this class.
  """
  _ISO8601_FORMAT = '%Y-%m-%dT%H:%M:%SZ'

  def __init__(self, info: dict) -> None:
    self._attrs = {}
    self._properties = {}
    self._unprocessed = info
    self._end_time = 0  # ms since start

  def pop_info(self, key: str, default=None):
    return self._unprocessed.pop(key, default)

  def update_properties_with_unprocessed(self) -> None:
    self._properties.update(
        (k, v) for k, v in self._unprocessed.items() if v is not None)
    self._unprocessed = {}

  def update_end_time(self, new_time):
    self._end_time = max(self._end_time, new_time)

  def compute_timings(self, time_zero):
    ms_since_start = self.pop_info('time')
    assert ms_since_start is not None
    start_time = time_zero + timedelta(milliseconds=ms_since_start)
    self._attrs['timestamp'] = start_time.strftime(self._ISO8601_FORMAT)
    self._attrs['time'] = f'{(self._end_time - ms_since_start) / 1000:.3f}'

  def convert_attrs_to_str(self) -> None:
    for key, value in self._attrs.items():
      self._attrs[key] = str(value)

  def _create_xml_element(self):
    raise NotImplementedError

  def create_xml_element(self):
    xml_element = self._create_xml_element()
    if len(self._properties) > 0:
      properties_element = etree.SubElement(xml_element, 'properties')
      for name, value in self._properties.items():
        etree.SubElement(
            properties_element,
            'property',
            attrib={
                'name': name,
                'value': str(value)
            })
    return xml_element

  @property
  def name(self):
    return self._attrs.get('name', '')

  @name.setter
  def name(self, name) -> None:
    self._attrs['name'] = name

  @property
  def end_time(self):
    return self._end_time


class TestSuite(TestElement):
  """An XML element of type testsuiteT"""

  def __init__(self, info: dict) -> None:
    super().__init__(info)
    self._attrs['tests'] = 0
    self._attrs['errors'] = 0
    self._attrs['failures'] = 0

  def _create_xml_element(self):
    return etree.Element('testsuite', attrib=self._attrs)

  def increase_tests(self) -> None:
    self._attrs['tests'] += 1

  def increase_errors(self) -> None:
    self._attrs['errors'] += 1

  def increase_failures(self) -> None:
    self._attrs['failures'] += 1


class TestSuites(TestSuite):
  """"testsuites" element"""

  def _create_xml_element(self):
    return etree.Element('testsuites', attrib=self._attrs)


class DartTestSuite(TestSuite):
  """A Dart test suite translates to a "testsuite" element"""

  def __init__(self, info: dict) -> None:
    super().__init__(info)
    self.name = self.pop_info('path')


class DartTestGroup(TestSuite):
  """A Dart test group translates to a "testsuite" element"""

  def __init__(self, info: dict) -> None:
    super().__init__(info)
    self.name = self.pop_info('name')
    # Drop inaccurate/deprecated info
    self.pop_info('testCount')
    self.pop_info('metadata')


class TestStatus(IntEnum):
  UNKNOWN = -1
  SUCCESS = 0
  FAILURE = 1
  ERROR = 2


class TestCase(TestElement):
  """"testcase" element"""

  def __init__(self, info: dict) -> None:
    super().__init__(info)
    self._messages = []
    self._errors = []
    self.status: TestStatus = TestStatus.UNKNOWN

    self.name = self.pop_info('name')
    # Drop deprecated info
    self.pop_info('metadata')

  def _create_xml_element(self):
    return etree.Element('testcase', attrib=self._attrs)

  def _add_error(self, error: dict) -> None:
    self._errors.append(error)
    if self.status != TestStatus.UNKNOWN:
      self.update_end_time(error['time'])
      is_failure = error['isFailure']
      if is_failure:
        self.status = max(self.status, TestStatus.FAILURE)
      else:
        self.status = max(self.status, TestStatus.ERROR)

  def _add_test_done(self, test_done: dict) -> None:
    result = test_done.pop('result')
    if result == 'success':
      self.status = TestStatus.SUCCESS
    elif result == 'failure':
      self.status = TestStatus.FAILURE
    elif result == 'error':
      self.status = TestStatus.ERROR
    self._properties['hidden'] = str(test_done.pop('hidden'))
    self._properties['skipped'] = str(test_done.pop('skipped'))
    self.update_end_time(test_done.pop('time'))

  def add_test_event(self, event: dict) -> None:
    event_type = event.pop('type')
    if event_type == 'print':  # MessageEvent
      self._messages.append(event)
    elif event_type == 'error':
      self._add_error(event)
    elif event_type == 'testDone':
      self._add_test_done(event)

  def create_xml_element(self):
    xml_element = super().create_xml_element()
    for error in self._errors:
      if error['isFailure']:
        error_type = 'failure'
      else:
        error_type = 'error'
      error_element = etree.SubElement(
          xml_element, error_type, attrib={'message': error['error']})
      error_element.text = etree.CDATA(error['stackTrace'])
    if len(self._messages) > 0:
      properties_element = xml_element.find('properties')
      if properties_element is None:
        properties_element = etree.SubElement(xml_element, 'properties')
      etree.SubElement(
          properties_element,
          'property',
          attrib={
              'name': 'messages',
              'value': json.dumps(self._messages)
          })
    return xml_element


class TestTree:
  """Tree of test elements"""
  _ROOT = None

  def __init__(self) -> None:
    self._children = defaultdict(
        list)  # map from parent id to list of children id
    self._test_elements = {}  # map from node id to TestElement's

  @property
  def root_id(self):
    return self._ROOT

  def traverse_with_parents(self, visit):
    parents = []

    def _traverse(node_id):
      visit(node_id, parents)
      parents.append(node_id)
      for child_id in self._children[node_id]:
        _traverse(child_id)
      parents.pop()

    _traverse(self._ROOT)

  def traverse(self, visit):

    def _traverse(node_id):
      visit(node_id)
      for child_id in self._children[node_id]:
        _traverse(child_id)

    _traverse(self._ROOT)

  def start_tests(self, start_event):
    start_event.pop('type')
    protocol_version = start_event.pop('protocolVersion')
    assert protocol_version.startswith('0.'), (
        'The tool only supports JSON reporter protocol version 0.x, '
        f'not {protocol_version}')
    self._test_elements[self._ROOT] = TestSuites(start_event)

  def add_suite(self, suite_event: dict) -> None:
    info = suite_event.pop('suite')
    info['time'] = suite_event['time']
    suite = DartTestSuite(info)
    suite_id = suite.pop_info('id')
    self._children[self._ROOT].append(suite_id)
    self._test_elements[suite_id] = suite

  def add_group(self, group_event: dict) -> None:
    info = group_event.pop('group')
    info['time'] = group_event['time']
    group = DartTestGroup(info)
    group_id = group.pop_info('id')
    suite_id = group.pop_info('suiteID')
    parent_group = group.pop_info('parentID', None)
    if parent_group is None:
      self._children[suite_id].append(group_id)
    else:
      self._children[parent_group].append(group_id)

    self._test_elements[group_id] = group

  def add_test(self, test_start_event: dict) -> None:
    info = test_start_event.pop('test')
    info['time'] = test_start_event['time']
    test = TestCase(info)
    test_id = test.pop_info('id')
    suite_id = test.pop_info('suiteID')
    group_ids = test.pop_info('groupIDs', [])
    assert group_ids is not None

    if len(group_ids) > 0:
      self._children[group_ids[-1]].append(test_id)
    else:
      self._children[suite_id].append(test_id)

    self._test_elements[test_id] = test

  def add_test_event(self, event: dict) -> None:
    test_id = event.pop('testID')
    self._test_elements[test_id].add_test_event(event)

  def get_test_element(self, node_id: int) -> TestElement:
    return self._test_elements[node_id]


def _get_creation_time(f: fileinput.FileInput):
  if f.isstdin():
    return datetime.now(tz=timezone.utc)
  else:
    creation_timestamp = os.fstat(f.fileno()).st_ctime
    return datetime.fromtimestamp(creation_timestamp, tz=timezone.utc)


# Pass 0
def generate_event_stream(f: fileinput.FileInput):
  for line in f:
    if f.isfirstline():
      # Generate one extra information before the stream of events
      yield _get_creation_time(f)
    try:
      event = json.loads(line)
    except json.JSONDecodeError:
      continue
    if isinstance(event, dict):
      yield event


# Pass 1
def build_test_tree(event_stream: Iterable) -> TestTree:
  test_tree = TestTree()
  for event in event_stream:
    event_type = event['type']
    if event_type == 'start':  # StartEvent
      test_tree.start_tests(event)
    elif event_type == 'suite':  # SuiteEvent
      test_tree.add_suite(event)
    elif event_type == 'group':  # GroupEvent
      test_tree.add_group(event)
    elif event_type == 'testStart':  # TestStartEvent
      test_tree.add_test(event)
    elif event_type in set(['print', 'error', 'testDone'
                           ]):  # MessageEvent, ErrorEvent, TestDoneEvent
      test_tree.add_test_event(event)
    else:  # ignored event, including AllSuitesEvent, DebugEvent, DoneEvent
      pass
  return test_tree


# Pass 2
def compute_counts_and_end_time(test_tree: TestTree) -> None:

  def visit(node_id, parents):
    test_element = test_tree.get_test_element(node_id)
    if isinstance(test_element, TestCase):
      for parent in parents:
        parent_element = test_tree.get_test_element(parent)
        assert isinstance(parent_element, TestSuite)

        # update counts
        parent_element.increase_tests()
        if test_element.status == TestStatus.ERROR:
          parent_element.increase_errors()
        elif test_element.status == TestStatus.FAILURE:
          parent_element.increase_failures()

        # update end time
        parent_element.update_end_time(test_element.end_time)

  test_tree.traverse_with_parents(visit)


# Pass 3
def compute_timings_and_finalize(test_tree: TestTree,
                                 time_zero: datetime) -> None:

  def visit(node_id):
    test_element = test_tree.get_test_element(node_id)
    test_element.compute_timings(time_zero)
    test_element.update_properties_with_unprocessed()
    test_element.convert_attrs_to_str()

  test_tree.traverse(visit)


# Pass 4
def generate_xml(test_tree: TestTree):
  xml_elements = {}

  def visit(node_id, parents):
    test_element = test_tree.get_test_element(node_id)
    xml_element = test_element.create_xml_element()
    xml_elements[node_id] = xml_element
    if len(parents) > 0:
      xml_elements[parents[-1]].append(xml_element)

  test_tree.traverse_with_parents(visit)
  root = xml_elements[test_tree.root_id]
  return root


def print_xml(root):
  print(etree.tostring(root, encoding=str, pretty_print=True))


def main() -> None:
  if len(sys.argv) > 2:
    print(
        f'Usage: {sys.argv[0]} [-|file_name]\n'
        f'"{sys.argv[0]}" or "{sys.argv[0]}" - will read from stdin\n'
        'Otherwise, it read from file_name.',
        file=sys.stderr)

  with fileinput.input() as f:
    event_stream = generate_event_stream(f)
    time_zero = next(event_stream)
    test_tree = build_test_tree(event_stream)

  compute_counts_and_end_time(test_tree)
  assert isinstance(time_zero, datetime)
  compute_timings_and_finalize(test_tree, time_zero)
  xml = generate_xml(test_tree)
  print_xml(xml)


if __name__ == '__main__':
  main()
