#!/usr/bin/env python3
# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Testing dart_test_json2xml.py"""

from datetime import datetime, timezone
import fileinput
import unittest
from unittest import mock

from dart_test_json2xml import generate_event_stream,\
  build_test_tree,\
  compute_counts_and_end_time,\
  compute_timings_and_finalize,\
  generate_xml
from dart_test_json2xml_test_data import sample_file, expected_stream, EventGenerator


def generate_xml_from_event_stream(events):
  tree = build_test_tree(events)
  compute_counts_and_end_time(tree)
  compute_timings_and_finalize(tree, datetime.fromtimestamp(0, timezone.utc))
  return generate_xml(tree)


class JsonToXmlTest(unittest.TestCase):

  def test_stream_generation(self):
    with mock.patch('builtins.open', mock.mock_open(read_data=sample_file)):
      stream = generate_event_stream(fileinput.input('dummy'))
      self.assertIsInstance(next(stream), datetime)
      self.assertEqual(list(stream), expected_stream)

  def test_tree_building(self):
    eg = EventGenerator()
    events = [
        eg.start(),
        eg.suite(0),
        eg.test(1, parent_id=0),
        eg.test_done(test_id=1, result='success'),
        eg.group(2, parent_id=0),
        eg.test(3, parent_id=2),
        eg.test_done(test_id=3, result='success'),
        eg.group(4, parent_id=2),
        eg.test(5, parent_id=4),
        eg.error(test_id=5, is_failure=True),
        eg.test_done(test_id=5, result='failure'),
        eg.test(6, parent_id=4),
        eg.error(test_id=6, is_failure=False),
        eg.test_done(test_id=6, result='error'),
        eg.group(7, parent_id=2),
        eg.test(8, parent_id=7),
        eg.test_done(test_id=8, result='success'),
        eg.test(9, parent_id=7),
        eg.test_done(test_id=9, result='error'),
        eg.test(10, parent_id=7),
        eg.test_done(test_id=10, result='failure'),
        eg.suite(11),
        eg.group(12, parent_id=11),
        eg.test(13, parent_id=12),
        eg.test_done(test_id=13, result='success'),
        eg.test(14, parent_id=12),
        eg.test_done(test_id=14, result='failure'),
        eg.done(False)
    ]
    xml = generate_xml_from_event_stream(events)
    # Check test/error/failure counts and duration
    self.assertEqual(len(xml.findall('.//testcase')), 9)
    self.assertEqual(xml.get('tests'), '9')
    self.assertEqual(xml.get('errors'), '2')
    self.assertEqual(xml.get('failures'), '3')
    self.assertEqual(xml.get('time'), '0.260')
    test_suites = xml.findall('.//testsuite')
    test_counts = [e.get('tests') for e in test_suites]
    self.assertListEqual(test_counts, ['7', '6', '2', '3', '2', '2'])
    error_counts = [e.get('errors') for e in test_suites]
    self.assertListEqual(error_counts, ['2', '2', '1', '1', '0', '0'])
    failure_counts = [e.get('failures') for e in test_suites]
    self.assertListEqual(failure_counts, ['2', '2', '1', '1', '1', '1'])
    durations = [e.get('time') for e in test_suites]
    self.assertListEqual(durations,
                         ['0.190', '0.160', '0.060', '0.060', '0.050', '0.040'])

  def test_interleaving_events(self):
    """ Test interleaving events.
    
    Dart test json reporter can only guarantee that any event will be emitted
    after its parent event. There are no other guarantees on order of events. It
    is even possible that an error event could happen after the corresponding
    test is done. Our converter need to take care of those cases."""
    eg = EventGenerator()
    events = [
        eg.start(),
        eg.suite(0),
        eg.group(1, parent_id=0),
        eg.group(2, parent_id=1),
        eg.group(3, parent_id=1),
        eg.suite(4),
        eg.group(5, parent_id=4),
        eg.test(6, parent_id=3),
        eg.test(7, parent_id=2),
        eg.test(8, parent_id=3),
        eg.test(9, parent_id=2),
        eg.test(10, parent_id=3),
        eg.test(11, parent_id=1),
        eg.test(12, parent_id=5),
        eg.test(13, parent_id=0),
        eg.test(14, parent_id=5),
        eg.test_done(test_id=14, result='failure'),
        eg.test_done(test_id=13, result='success'),
        eg.test_done(test_id=11, result='success'),
        eg.test_done(test_id=7, result='success'),
        eg.test_done(test_id=6, result='success'),
        eg.test_done(test_id=9, result='success'),
        eg.error(test_id=9, is_failure=True),
        eg.error(test_id=7, is_failure=False),
        eg.test_done(test_id=10, result='failure'),
        eg.test_done(test_id=12, result='success'),
        eg.test_done(test_id=8, result='error'),
        eg.done(False)
    ]
    xml = generate_xml_from_event_stream(events)
    # Check test/error/failure counts and duration
    self.assertEqual(len(xml.findall('.//testcase')), 9)
    self.assertEqual(xml.get('tests'), '9')
    self.assertEqual(xml.get('errors'), '2')
    self.assertEqual(xml.get('failures'), '3')
    self.assertEqual(xml.get('time'), '0.260')
    test_suites = xml.findall('.//testsuite')
    test_counts = [e.get('tests') for e in test_suites]
    self.assertListEqual(test_counts, ['7', '6', '2', '3', '2', '2'])
    error_counts = [e.get('errors') for e in test_suites]
    self.assertListEqual(error_counts, ['2', '2', '1', '1', '0', '0'])
    failure_counts = [e.get('failures') for e in test_suites]
    self.assertListEqual(failure_counts, ['2', '2', '1', '1', '1', '1'])
    durations = [e.get('time') for e in test_suites]
    self.assertListEqual(durations,
                         ['0.250', '0.240', '0.200', '0.220', '0.200', '0.190'])


if __name__ == '__main__':
  unittest.main()
