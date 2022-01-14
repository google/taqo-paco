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

#import "NotificationWithState.h"

@implementation NotificationWithState


- (void)encodeWithCoder:(nonnull NSCoder *)coder {
  [coder encodeObject:_state forKey:@"state"];
  [coder encodeObject:_notification forKey:@"notification"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
  self = [super init];
  if (self) {
    _state = [coder decodeObjectOfClass:[NSString class] forKey:@"state"];
    _notification = [coder decodeObjectOfClass:[UNNotification class] forKey:@"notification"];
  }
  return self;
}

- (nullable instancetype) initWithNotification:(UNNotification *) notification state: (NSString *) state;
{
  self = [super init];
  if (self) {
    _state = state;
    _notification = notification;
  }
  return self;
}

+ (instancetype) notification: (UNNotification *) notification state: (NSString *) state {
  return [[[self class] alloc] initWithNotification:notification state:state];
}

+ (BOOL) supportsSecureCoding {
  return YES;
}


@end
