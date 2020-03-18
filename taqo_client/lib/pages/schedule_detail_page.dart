import 'package:flutter/material.dart';

import '../model/experiment.dart';
import '../model/schedule.dart';
import '../model/signal_time.dart';
import '../util/date_time_util.dart';

typedef SetTimeFunction = void Function(int newTime);

class ScheduleDetailArguments {
  final Experiment experiment;
  final Schedule schedule;

  ScheduleDetailArguments(this.experiment, this.schedule);
}

class ScheduleDetailPage extends StatefulWidget {
  static const routeName = '/schedule_details';

  ScheduleDetailPage({Key key}) : super(key: key);

  @override
  _ScheduleDetailPageState createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<ScheduleDetailPage> {
  bool _pendingChanges;

  @override
  void initState() {
    super.initState();
    _pendingChanges = false;
  }

  Future<bool> _onWillPop() {
    Navigator.pop(context, _pendingChanges);
    return Future.value(false);
  }

  void _setStateAndMarkChanged(VoidCallback setFn) {
    setState(() {
      _pendingChanges = true;
      setFn();
    });
  }

  Widget build(BuildContext context) {
    final ScheduleDetailArguments args = ModalRoute.of(context).settings.arguments;
    return WillPopScope(onWillPop: _onWillPop,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Schedule Details"),
            backgroundColor: Colors.indigo,
          ),
          body: Container(
            padding: EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildScheduleDetail(context, args),
            ),
          ),
        )
    );
  }

  List<Widget> _buildScheduleDetail(BuildContext context, ScheduleDetailArguments args) {
    switch (args.schedule.scheduleType) {
      case Schedule.DAILY:
      case Schedule.WEEKDAY:
        return _buildDailyScheduleDetail(context, args);
      case Schedule.WEEKLY:
        return _buildWeeklyScheduleDetail(context, args);
      case Schedule.MONTHLY:
        return _buildMonthlyScheduleDetail(context, args);
      case Schedule.ESM:
        return _buildESMScheduleDetail(context, args);
    }
    return [];
  }

  Widget _buildTitleWidget(String when, String title) {
    return Text("$when scheduled time for $title", style: TextStyle(fontSize: 24),);
  }

  Widget _buildTimeWidget(String label, int msFromMidnight, SetTimeFunction set,
      {double labelWidth = 72}) {
    final time = TimeOfDay.fromDateTime(DateTime(0).add(Duration(milliseconds: msFromMidnight)));
    return Row(children: <Widget>[
      SizedBox(width: labelWidth, child: Text("$label: ")),
      RaisedButton(onPressed: () async {
        final newTime = await showTimePicker(context: context, initialTime: time);
        if (newTime != null) {
          _setStateAndMarkChanged(() => set(getMsFromMidnight(newTime)));
        }
      },
        child: Text(getHourOffsetAsTimeString(msFromMidnight))),
    ]);
  }

  List<Widget> _buildDailyScheduleDetail(BuildContext context, ScheduleDetailArguments args) {
    final Experiment experiment = args.experiment;
    final Schedule schedule = args.schedule;
    List<Widget> widgets = [_buildTitleWidget("Daily", experiment.title)];

    if (schedule.scheduleType == Schedule.DAILY) {
      widgets += _buildRepeatRow(experiment, schedule, "days", 30);
    }
    widgets += _buildSignalTimeList(context, schedule.signalTimes);
    return widgets;
  }

  List<Widget> _buildWeeklyScheduleDetail(BuildContext context, ScheduleDetailArguments args) {
    final Experiment experiment = args.experiment;
    final Schedule schedule = args.schedule;
    List<Widget> widgets = [_buildTitleWidget("Weekly", experiment.title)];

    widgets += _buildRepeatRow(experiment, schedule, "weeks", 5);
    widgets += _buildDaysOfWeekRow(schedule);
    widgets += _buildSignalTimeList(context, schedule.signalTimes);
    return widgets;
  }

  List<Widget> _buildMonthlyScheduleDetail(BuildContext context, ScheduleDetailArguments args) {
    final Experiment experiment = args.experiment;
    final Schedule schedule = args.schedule;
    List<Widget> widgets = [_buildTitleWidget("Monthly", experiment.title)];

    widgets.add(Wrap(spacing: 8.0, runSpacing: 4.0, children: <Widget>[
      RadioListTile(title: const Text('By day of month'),
        groupValue: schedule.byDayOfMonth,
        value: true,
        onChanged: (bool newValue) =>
            _setStateAndMarkChanged(() => schedule.byDayOfMonth = newValue)
      ),
      RadioListTile(title: const Text('By week of month'),
        groupValue: schedule.byDayOfMonth,
        value: false,
        onChanged: (bool newValue) => _setStateAndMarkChanged(() => schedule.byDayOfMonth = newValue)
      ),
    ]));

    if (schedule.byDayOfMonth) {
      widgets.add(Row(children: <Widget>[
        const Text("Day of month: "),
        DropdownButton(value: schedule.dayOfMonth,
          items: List.generate(31, (i) => i + 1).map((int j) =>
              DropdownMenuItem(value: j, child: Text("$j"))).toList(),
          onChanged: (int newValue) => _setStateAndMarkChanged(() => schedule.dayOfMonth = newValue)
        )
      ]));
    } else {
      widgets.add(Row(children: <Widget>[
        const Text("Week of month: "),
        DropdownButton(value: ORDINAL_NUMBERS[schedule.nthOfMonth],
          items: List.generate(ORDINAL_NUMBERS.length - 1, (i) => i + 1).map((int j) =>
              DropdownMenuItem(value: ORDINAL_NUMBERS[j], child: Text(ORDINAL_NUMBERS[j]))).toList(),
          onChanged: (String newValue) =>
              _setStateAndMarkChanged(() => schedule.nthOfMonth = ORDINAL_NUMBERS.indexOf(newValue)),
        ),
      ]));
      widgets += _buildDaysOfWeekRow(schedule);
    }

    widgets += _buildRepeatRow(experiment, schedule, "months", 12);
    widgets += _buildSignalTimeList(context, schedule.signalTimes);
    return widgets;
  }

  List<Widget> _buildESMScheduleDetail(BuildContext context, ScheduleDetailArguments args) {
    final Experiment experiment = args.experiment;
    final Schedule schedule = args.schedule;
    List<Widget> widgets = [_buildTitleWidget("Randomly", experiment.title)];

    // TODO incorporate esmPeriodDays
    var min = (schedule.esmFrequency - 1) * schedule.minimumBuffer;
    final hours = min ~/ 60;
    min %= 60;
    final errMsg = Text("Start time must be before end time and total time must be at least"
        "${hours > 0 ? " $hours hours and" : ""} $min minutes long");

    widgets.add(Text("Suggested signaling schedule"));
    widgets.add(Builder(builder: (context) =>
        _buildTimeWidget("Start hour", schedule.esmStartHour, (int newStartTime) {
          if (schedule.validateESMSchedule(startHour: newStartTime)) {
            schedule.esmStartHour = newStartTime;
          } else {
            Scaffold.of(context).showSnackBar(SnackBar(content: errMsg));
          }
        })
    ));
    widgets.add(Builder(builder: (context) =>
        _buildTimeWidget("End hour", schedule.esmEndHour, (int newEndTime) {
          if (schedule.validateESMSchedule(endHour: newEndTime)) {
            schedule.esmEndHour = newEndTime;
          } else {
            Scaffold.of(context).showSnackBar(SnackBar(content: errMsg));
          }
        })
    ));
    return widgets;
  }

  List<Widget> _buildRepeatRow(Experiment experiment, Schedule schedule, String when, int num) {
    return <Widget>[
      Row(children: <Widget>[
        const Text("Repeat every "),
        DropdownButton(value: schedule.repeatRate,
          items: List.generate(num, (i) => i + 1).map((int j) =>
              DropdownMenuItem(value: j, child: Text("$j"))).toList(),
          onChanged: (int newValue) => _setStateAndMarkChanged(() => schedule.repeatRate = newValue),
        ),
        Text(" $when"),
      ]),
    ];
  }

  List<Widget> _buildDaysOfWeekRow(Schedule schedule) {
    final children = List<Widget>();
    var i = 0;
    for (var day = 1; day < 1 << 7; day <<= 1) {
      children.add(Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Checkbox(value: schedule.weekDaysScheduled & day != 0,
            onChanged: (bool newValue) => _setStateAndMarkChanged(() =>
              newValue ?
              schedule.weekDaysScheduled |= day :
              schedule.weekDaysScheduled &= ~day)),
        Text(DAYS_SHORT_NAMES[i])
      ]));
      i += 1;
    }
    return <Widget>[
      Wrap(spacing: 8.0, runSpacing: 4.0, children: children),
    ];
  }

  List<Widget> _buildSignalTimeList(BuildContext context, List<SignalTime> signalTimes) {
    final children = <Widget>[Divider(height: 8,)];
    for (var i = 0; i < signalTimes.length; i++) {
      final time = signalTimes[i];
      String label = "Time $i";
      if (time.label != null && time.label.isNotEmpty && time.label != "null") {
        label = time.label;
      }
      children.add(_buildTimeWidget(label, time.fixedTimeMillisFromMidnight,
              (int ms) => time.fixedTimeMillisFromMidnight = ms));
    }
    return children;
  }
}
