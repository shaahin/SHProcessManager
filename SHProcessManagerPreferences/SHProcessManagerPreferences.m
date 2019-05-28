//
//  SHProcessManagerPreferences.m
//  SHProcessManagerPreferences
//
//  Created by Shahin Katebi on 2/13/19.
//

#import "SHProcessManagerPreferences.h"

@implementation SHProcessManagerPreferences
@synthesize onlyMineProcesses;
@synthesize refreshRate;

#define AppID CFSTR("us.shaahin.SHProcessManager")

NSUserDefaults *userDefaults;
- (void)mainViewDidLoad
{
    CFPropertyListRef value = CFPreferencesCopyAppValue( CFSTR("mine_only"), AppID);
    if (value && CFGetTypeID(value) == CFBooleanGetTypeID()) {
        [onlyMineProcesses setState:CFBooleanGetValue(value)];
    } else {
        [onlyMineProcesses setState:NO];
    }
    if (value) CFRelease(value);
    
    
    value = CFPreferencesCopyAppValue(CFSTR("refresh_rate"),AppID);
    if (value && CFGetTypeID(value) == CFStringGetTypeID()) {
        
        [self.refreshRate selectItemWithTag: (NSInteger)value];
    } else {
        [self.refreshRate selectItemWithTag: 3];
    }
    if (value) CFRelease(value);
    
}
- (IBAction)onlyMineChanged:(NSButton *)sender {
    if ([sender state])
    {
        CFPreferencesSetAppValue( CFSTR("mine_only"), kCFBooleanTrue, AppID );
    }
    else
    {
        CFPreferencesSetAppValue( CFSTR("mine_only"), kCFBooleanFalse, AppID );
    }
}
- (IBAction)refreshRateChanged:(NSPopUpButton *)sender {
    long tagInt = sender.selectedTag;
    CFNumberRef tag = CFNumberCreate(kCFAllocatorDefault, kCFNumberLongType, &tagInt);
    CFPreferencesSetAppValue( CFSTR("refresh_rate"), tag, AppID );
    
}

@end
