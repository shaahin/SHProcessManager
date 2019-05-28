//
//  SHProcessManagerPreferences.h
//  SHProcessManagerPreferences
//
//  Created by Shahin Katebi on 2/13/19.
//

#import <PreferencePanes/PreferencePanes.h>

@interface SHProcessManagerPreferences : NSPreferencePane
@property (weak) IBOutlet NSButton *onlyMineProcesses;
@property (weak) IBOutlet NSPopUpButton *refreshRate;

- (void)mainViewDidLoad;

@end
