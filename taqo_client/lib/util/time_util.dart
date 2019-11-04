import 'package:intl/intl.dart';

class TimeUtil {

  static const DATETIME_FORMAT = 'yyyy/MM/dd HH:mm:ssZ';

  static final dateTimeFormat = DateFormat(DATETIME_FORMAT);

  static DateTime dateTimeFromString(String string) =>
      string == null ? null : dateTimeFormat.parse(string);

  static String dateTimeToString(DateTime dateTime) =>
      dateTime == null ? null : dateTimeFormat.format(dateTime);



//  static DateTimeFormatter timeFormatter = ISODateTimeFormat.time();
//
//  static final String DATETIME_FORMAT = "yyyy/MM/dd HH:mm:ssZ";
//  static DateTimeFormatter dateTimeFormatter = DateTimeFormat.forPattern(DATETIME_FORMAT);
//
//  static final String DATE_LONG_FORMAT = "MMMM dd, yyyy";
//  static DateTimeFormatter dateLongFormatter = DateTimeFormat.forPattern(DATE_LONG_FORMAT);
//
//  static final String DATETIME_NOZONE_FORMAT = "yyyy/MM/dd hh:mm:ssa";
//  static DateTimeFormatter dateTimeNoZoneFormatter = DateTimeFormat.forPattern(DATETIME_NOZONE_FORMAT);
//
//  static final String DATETIME_NOZONE_SHORT_FORMAT = "yy/MM/dd HH:mm";
//  static DateTimeFormatter dateTimeNoZoneShortFormatter = DateTimeFormat.forPattern(DATETIME_NOZONE_SHORT_FORMAT);
//
//  static final String DATE_FORMAT = "yyyy/MM/dd";
//  static DateTimeFormatter dateFormatter = DateTimeFormat.forPattern(DATE_FORMAT);
//
//  static final String DATE_WITH_ZONE_FORMAT = "yyyy/MM/ddZ";
//  static DateTimeFormatter dateZoneFormatter = DateTimeFormat.forPattern(DATE_WITH_ZONE_FORMAT);
//
//  static final String DATE_TIME_WITH_NO_TZ = "yyyy/MM/dd HH:mm:ss";
//  static DateTimeFormatter dateTimeWithNoTzFormatter = DateTimeFormat.forPattern(DATE_TIME_WITH_NO_TZ);
//  static SimpleDateFormat localFormatter = new SimpleDateFormat (DATE_TIME_WITH_NO_TZ);
//
//  static final DateTimeFormatter hourFormatter = DateTimeFormat.forPattern("hh:mma");
//  static final Logger log = Logger.getLogger(TimeUtil.class.getName());
//
//  TimeUtil() {
//  }
//
//  static String formatTime(int dateTimeMillis) {
//    return new DateTime(dateTimeMillis).toString(timeFormatter);
//  }
//
//  static String formatDateTime(int dateTimeMillis) {
//    return new DateTime(dateTimeMillis).toString(dateTimeFormatter);
//  }
//
//  static String formatDateTime(DateTime dateTime) {
//    return dateTime.toString(dateTimeFormatter);
//  }
//
//  static String formatDateLong(DateTime dateTime) {
//    return dateTime.toString(dateLongFormatter);
//  }
//
//  static String formatDateTimeShortNoZone(DateTime dateTime) {
//    return dateTime.toString(dateTimeNoZoneShortFormatter);
//  }
//
//  static DateTime parseDateTime(String dateTimeStr) {
//    return dateTimeFormatter.parseDateTime(dateTimeStr);
//  }
//
//  static int convertDateToLong(String dateTimeStr) {
//    DateTime dt = dateTimeWithNoTzFormatter.parseDateTime(dateTimeStr);
//    return dt.getMillis();
//  }
//
//  static DateTime parseDateWithZone(String dateTimeStr) {
//    return dateZoneFormatter.parseDateTime(dateTimeStr);
//  }
//
//  static String formatDate(int dateTimeMillis) {
//    return new DateTime(dateTimeMillis).toString(dateFormatter);
//  }
//
//  static DateTime unformatDate(String dateStr) {
//    return dateFormatter.parseDateTime(dateStr);
//  }
//
//  static String formatDateWithZone(DateTime dateTime) {
//    return dateTime.toString(dateZoneFormatter);
//  }
//
//  static String formatDateWithZone(int dateTimeMillis) {
//    return new DateTime(dateTimeMillis).toString(dateZoneFormatter);
//  }
//
//  static DateTime unformatDateWithZone(String dateStr) {
//    return dateZoneFormatter.parseDateTime(dateStr);
//
//  }
//
//  static DateMidnight getMondayOfWeek(DateTime now) {
//    DateMidnight mondayOfWeek = now.toDateMidnight();
//    int dow = mondayOfWeek.getDayOfWeek();
//    if (dow != DateTimeConstants.MONDAY) {
//      mondayOfWeek = mondayOfWeek.minusDays(dow - 1);
//    }
//    return mondayOfWeek;
//  }
//
//  static bool isWeekend(int dayOfWeek) {
//    return dayOfWeek == DateTimeConstants.SATURDAY ||
//        dayOfWeek == DateTimeConstants.SUNDAY;
//  }
//
//  static bool isWeekend(DateTime dateTime) {
//    return isWeekend(dateTime.getDayOfWeek());
//  }
//
//  static DateTime skipWeekends(DateTime plusDays) {
//    if (plusDays.getDayOfWeek() == DateTimeConstants.SATURDAY) {
//      return plusDays.plusDays(2);
//    } else if (plusDays.getDayOfWeek() == DateTimeConstants.SUNDAY) {
//      return plusDays.plusDays(1);
//    }
//    return plusDays;
//  }
//
//  static DateTime parseDateWithoutZone(String dateParam) {
//    if (Strings.isNullOrEmpty(dateParam)) {
//      return null;
//    }
//    try {
//      return dateFormatter.parseDateTime(dateParam);
//    } catch (Exception e) {
//    return null;
//    }
//  }
//
//  static Date convertToUTC(Date dt, DateTimeZone clientTz) throws ParseException{
//  if (dt == null) {
//  return null;
//  }
//  int eventMillsInUTCTimeZone = clientTz.convertLocalToUTC(dt.getTime(), false);
//  DateTime evenDateTimeInUTCTimeZone = new DateTime(eventMillsInUTCTimeZone);
//  return evenDateTimeInUTCTimeZone.toDate();
//}
//
//static DateTime convertToLocal(Date dt, String clientTz) throws ParseException{
//if (dt == null) {
//return null;
//}
//DateTimeZone dtz= DateTimeZone.forID(clientTz);
//int eventMillsInLocalTimeZone = dtz.convertUTCToLocal(dt.getTime());
//DateTime evenDateTimeInlocalTimeZone = new DateTime(eventMillsInLocalTimeZone);
//return evenDateTimeInlocalTimeZone;
//}
//
//
}
