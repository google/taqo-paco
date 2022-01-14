#import "AppDelegate.h"
#import "NotificationWithState.h"
#import <objc/runtime.h>

NSString * const NotificationCenterUIBundleID = @"com.apple.notificationcenterui";
NSString * const DefaultsSuiteName = @"com.taqo.survey.taqoClient.alerter.removed";

// Set OS Params
#define NSAppKitVersionNumber10_8 1187
#define NSAppKitVersionNumber10_9 1265

#define contains(str1, str2) ([str1 rangeOfString: str2 ].location != NSNotFound)

static BOOL
isMavericks()
{
  if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_8) {
    /* On a 10.8 - 10.8.x system */
    return NO;
  } else {
    /* 10.9 or later system */
    return YES;
  }
}

@implementation NSUserDefaults (SubscriptAndUnescape)
- (id)objectForKeyedSubscript:(id)key;
{
  id obj = [self objectForKey:key];
  if ([obj isKindOfClass:[NSString class]] && [(NSString *)obj hasPrefix:@"\\"]) {
    obj = [(NSString *)obj substringFromIndex:1];
  }
  return obj;
}
@end

@interface AppDelegate ()
@property NSString *outputType;
@end

@implementation AppDelegate



+(void)initializeUserDefaults
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  // initialize the dictionary with default values depending on OS level
  NSDictionary *appDefaults;

  if (isMavericks()) {
    //10.9
    appDefaults = @{@"sender": @"com.apple.Terminal"};
  } else {
    //10.8
    appDefaults = @{@"": @"message"};
  }

  // and set them appropriately
  [defaults registerDefaults:appDefaults];
}



- (void)printHelpBanner;
{
  const char *appName = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"] UTF8String];
  const char *appVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] UTF8String];
  printf("%s (%s) is a command-line tool to send OS X User Notifications.   \n" \
         "\n" \
         "Usage: %s -[message|list|remove] [VALUE|ID|ID] [options]\n" \
         "\n" \
         "   Either of these is required (unless message data is piped to the tool):\n" \
         "\n" \
         "       -help              Display this help banner.\n" \
         "       -message VALUE     The notification message.\n" \
         "       -remove ID         Removes a notification with the specified ‘group’ ID.\n" \
         "\n" \
         "   Optional:\n" \
         "\n" \
         "       -title VALUE       The notification title. Defaults to ‘Terminal’.\n" \
         "       -subtitle VALUE    The notification subtitle.\n" \
         "       -sound NAME        The name of a sound to play when the notification appears. The names are listed\n" \
         "                          in Sound Preferences. Use 'default' for the default notification sound.\n" \
         "       -group ID          A string which identifies the group the notifications belong to.\n" \
         "                          Old notifications with the same ID will be removed.\n" \
         "       -json       Write only event or value to stdout \n" \
         "       -timeout NUMBER    Close the notification after NUMBER seconds.\n" \
         "\n" \
         "When the user activates or close a notification, the results are logged to stdout as a json struct.\n" \
         "\n" \
         "Note that in some circumstances the first character of a message has to be escaped in order to be recognized.\n" \
         "An example of this is when using an open bracket, which has to be escaped like so: ‘\\[’.\n" \
         "\n" \
         "For more information see https://github.com/vjeantet/alerter.\n",
         appName, appVersion, appName);
}

- (void)askPermission;
{
  UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
  [center requestAuthorizationWithOptions: UNAuthorizationOptionBadge | UNAuthorizationOptionAlert | UNAuthorizationOptionSound completionHandler:^(BOOL granted, NSError * _Nullable error) {
    NSLog(@"askPermission: %@", granted ? @"YES" : @"NO");
    NSLog(@"askPermission: %@", error);
    dispatch_semaphore_signal(semaphore);
  }];
  dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification;
{
  if ([[[NSProcessInfo processInfo] arguments] indexOfObject:@"-help"] != NSNotFound) {
    [self printHelpBanner];
    [NSApp terminate:nil];;
  }

  NSArray *runningProcesses = [[[NSWorkspace sharedWorkspace] runningApplications] valueForKey:@"bundleIdentifier"];
  if ([runningProcesses indexOfObject:NotificationCenterUIBundleID] == NSNotFound) {
    NSLog(@"[!] Unable to post a notification for the current user (%@), as it has no running NotificationCenter instance.", NSUserName());
    exit(1);
  }


  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  // Assign delegate object to the UNUserNotificationCenter object before app finishes
  // launching, according to
  // https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate?language=objc
  UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
  center.delegate = self;

  if ([[[NSProcessInfo processInfo] arguments] indexOfObject:@"-permission"] != NSNotFound) {
    [self askPermission];
    [NSApp terminate:nil];
  }

  NSString *subtitle = defaults[@"subtitle"];
  NSString *message  = defaults[@"message"];
  NSString *remove   = defaults[@"remove"];
  NSString *sound    = defaults[@"sound"];


  // If there is no message and data is piped to the application, use that
  // instead.
  if (message == nil && !isatty(STDIN_FILENO)) {
    NSData *inputData = [NSData dataWithData:[[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile]];
    message = [[NSString alloc] initWithData:inputData encoding:NSUTF8StringEncoding];
  }

  if (message == nil && remove == nil) {
    [self printHelpBanner];
    exit(1);
  }


  if (remove) {
    [self removeNotificationWithGroupID:remove];
    if (message == nil) [NSApp terminate:nil];
  }


  if (message) {
    // Need to create and regiser a notification category in order to get called back when
    // the notification was dismissed by the user. See
    // https://developer.apple.com/documentation/usernotifications/unnotificationdismissactionidentifier?language=objc#discussion
    UNNotificationCategory *notificationCategory = [UNNotificationCategory categoryWithIdentifier:@"DEFAULT_CATEGORY" actions:@[] intentIdentifiers:@[] options:UNNotificationCategoryOptionCustomDismissAction];
    [center setNotificationCategories:[NSSet setWithArray: @[notificationCategory]]];

    NSMutableDictionary *options = [NSMutableDictionary dictionary];

    _outputType = @"outputEvent" ;
    if([[[NSProcessInfo processInfo] arguments] containsObject:@"-json"] == true) {
      _outputType = @"json" ;
    }

    if (defaults[@"group"])    options[@"groupID"]          = defaults[@"group"];

    options[@"timeout"] = @"0" ;
    if (defaults[@"timeout"])    options[@"timeout"]          = defaults[@"timeout"];

    options[@"uuid"] = [NSString stringWithFormat:@"%ld", self.hash] ;
    NSLog(@"Notification uuid is %@", options[@"uuid"]);

    [self deliverNotificationWithTitle:defaults[@"title"] ?: @"Terminal"
                              subtitle:subtitle
                               message:message
                               options:options
                                 sound:sound];
  }
}


- (void)deliverNotificationWithTitle:(NSString *)title
                            subtitle:(NSString *)subtitle
                             message:(NSString *)message
                             options:(NSDictionary *)options
                               sound:(NSString *)sound;
{
  if (options[@"groupID"] && [self notificationWithGroupIdExists:options[@"groupID"]]) {
    NSLog(@"Found notification with groupID %@.", options[@"groupID"]);
    [self removeNotificationWithGroupID:options[@"groupID"]];
  }

  UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
  content.title = title;

  content.title = title;
  content.subtitle = subtitle;
  content.body = message;
  content.userInfo = options;
  content.categoryIdentifier = @"DEFAULT_CATEGORY";



  if (sound != nil) {
    content.sound = [sound isEqualToString: @"default"] ? [UNNotificationSound defaultSound] : [UNNotificationSound soundNamed: sound] ;
  }
  NSString *UUID = [NSString stringWithFormat:@"%ld", self.hash];

  UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:UUID content:content trigger:nil];

  UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];

  [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {

    if (error != nil) {
      NSLog(@"Errors when adding notification request.");
      return;
    }
    if(options[@"groupID"] != nil) {
      // Periodically check whether the notification got removed by another alerter
      // process, because we will not receive messages/callbacks from the system when the
      // notification was removed by another process.
      dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                     ^{
        __block BOOL notificationStillPresent;
        do {
          notificationStillPresent = NO;
          UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
          dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
          [center getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> * _Nonnull notifications) {
            for(UNNotification *notification in notifications) {
              if ([notification.request.content.userInfo[@"uuid"]  isEqualToString:[NSString stringWithFormat:@"%ld", self.hash] ]) {
                notificationStillPresent = YES;
                break;
              }
            }
            dispatch_semaphore_signal(semaphore);
          }];
          dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
          if (notificationStillPresent) [NSThread sleepForTimeInterval:0.10f];
        } while (notificationStillPresent);


        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:DefaultsSuiteName];
        NSError *error = nil;
        NSData *data = [defaults objectForKey:options[@"uuid"]];
        NotificationWithState *notification = nil;
        if (data) {
          [defaults removeObjectForKey:options[@"uuid"]];
          notification = [NSKeyedUnarchiver unarchivedObjectOfClass:[NotificationWithState class] fromData:data error:&error];
        }
        if (data==nil || error!=nil || notification==nil) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [self Quit:@{@"activationType": @"unknown"} notification:nil];
            [NSApp terminate:nil];
          });
        } else {
          dispatch_async(dispatch_get_main_queue(), ^{
            [self Quit:@{@"activationType": notification.state} notification:notification.notification];
            [NSApp terminate:nil];
          });
        }
      });
    }

    if ([content.userInfo[@"timeout"] integerValue] > 0) {
      dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                     ^{
        [NSThread sleepForTimeInterval:[content.userInfo[@"timeout"] integerValue]];
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> * _Nonnull notifications) {

          NSDictionary *udict = @{@"activationType" : @"timeout"};
          for (UNNotification *userNotification in notifications) {
            if ([userNotification.request.content.userInfo[@"uuid"] isEqualToString: content.userInfo[@"uuid"]]) {
              [self Quit:udict notification:userNotification];
              [center removeDeliveredNotificationsWithIdentifiers: content.userInfo[@"uuid"]];
              break;
            }
          }
          [NSApp terminate:nil];
        }];
      });
    }
  }];
}

- (void)markNotification: (UNNotification *) notification withState: (NSString *) state;
{
  NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:DefaultsSuiteName];
  NSError *error = nil;
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[NotificationWithState notification:notification state:state] requiringSecureCoding:YES error:&error];
  if (error) {
    NSLog(@"Error when archiving a notification: %@", error);
    return;
  }

  [defaults setObject:data forKey:notification.request.content.userInfo[@"uuid"]];
}


- (void)removeNotificationWithGroupID:(NSString *)groupID;
{
  UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];

  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
  [center getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> * _Nonnull notifications) {
    for (UNNotification *userNotification in notifications) {
      if ([@"ALL" isEqualToString:groupID] || [userNotification.request.content.userInfo[@"groupID"] isEqualToString:groupID]) {
        [self markNotification:userNotification withState:@"removed"];
        [center removeDeliveredNotificationsWithIdentifiers:  @[userNotification.request.identifier]];
      }
    }
    dispatch_semaphore_signal(semaphore);
  }];
  dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

- (BOOL)notificationWithGroupIdExists:(NSString *)groupID;
{
  UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];

  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
  __block BOOL found = NO;
  [center getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> * _Nonnull notifications) {
    for (UNNotification *userNotification in notifications) {
      if ([userNotification.request.content.userInfo[@"groupID"] isEqualToString:groupID]) {
        found = YES;
        break;
      }
    }
    dispatch_semaphore_signal(semaphore);
  }];
  dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

  if (found) return YES;
  return NO;
}

// Callback to handle user actions (clicked/dismissed)
// See https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate/1649501-usernotificationcenter?language=objc
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)(void))completionHandler {
  NSLog(@"Received notification response for uuid %@.", response.notification.request.content.userInfo[@"uuid"]);
  NSString *notificationState;

  if ([response.actionIdentifier isEqualToString: UNNotificationDefaultActionIdentifier]) {
    notificationState = @"contentsClicked";
  } else if ([response.actionIdentifier isEqualToString: UNNotificationDismissActionIdentifier]) {
    notificationState = @"closed";
  } else {
    NSLog(@"Unexpected action identifier (%@) received.", response.actionIdentifier);
  }

  completionHandler();
  [self markNotification:response.notification withState:notificationState];
  NSLog(@"Marked notification %@ with state %@", response.notification.request.content.userInfo[@"uuid"], notificationState);
}

- (BOOL)Quit:(NSDictionary *)udict notification:(UNNotification *)notification;
{
  if ([_outputType isEqualToString:@"outputEvent"]) {
    if ([udict[@"activationType"] isEqualToString:@"closed"]) {

      printf("%s", "@CLOSED" );

    } else  if ([udict[@"activationType"] isEqualToString:@"timeout"]) {
      printf("%s", "@TIMEOUT" );
    } else  if ([udict[@"activationType"] isEqualToString:@"contentsClicked"]) {
      printf("%s", "@CONTENTCLICKED" );
    } else  if ([udict[@"activationType"] isEqualToString:@"removed"]) {
      printf("%s", "@REMOVED" );
    } else  if ([udict[@"activationType"] isEqualToString:@"unknown"]) {
      printf("%s", "@UNKNOWN" );
    } else {
      NSLog(@"Unexpected quit information: %@", [udict description]);
    }

    return YES;
  }


  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss Z";


  // Dictionary with several key/value pairs and the above array of arrays
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  [dict addEntriesFromDictionary:udict] ;
  if (notification) {
    [dict setValue:[dateFormatter stringFromDate:notification.date] forKey:@"deliveredAt"];
  }
  [dict setValue:[dateFormatter stringFromDate:[NSDate new]] forKey:@"activationAt"];
  
  NSError *error = nil;
  NSData *json;

  // Dictionary convertable to JSON ?
  if ([NSJSONSerialization isValidJSONObject:dict])
  {
    // Serialize the dictionary
    json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];

    // If no errors, let's view the JSON
    if (json != nil && error == nil)
    {
      NSString *jsonString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
      printf("%s", [jsonString cStringUsingEncoding:NSUTF8StringEncoding]);
    }
  }

  return YES ;
}

- (void) bye; {
  NSString *UUID = [NSString stringWithFormat:@"%ld", self.hash];
  UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
  [center removeDeliveredNotificationsWithIdentifiers:  @[UUID]];
}

@end
