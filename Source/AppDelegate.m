/*
    Copyright (c) 2018 Ricci Adams

    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
    LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
    OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
    WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#import "AppDelegate.h"
#import "HueManager.h"
#import "AppleSPI.h"
#import "Preset.h"

@interface AppDelegate ()
@property (weak) IBOutlet NSSlider *slider; 
@property (weak) IBOutlet NSMenu *statusMenu;
@property (weak) IBOutlet NSTextField *nameLabel;

@property (weak) IBOutlet NSMenuItem *revealSeparator;
@property (weak) IBOutlet NSMenuItem *revealMenuItem;
@property (weak) IBOutlet NSMenuItem *reloadMenuItem;

@end




static NSString *sFindOrCreateDirectory(
    NSSearchPathDirectory searchPathDirectory,
    NSSearchPathDomainMask domainMask,
    NSString *appendComponent,
    NSError **outError
) {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(searchPathDirectory, domainMask, YES);
    if (![paths count]) return nil;

    NSString *resolvedPath = [paths firstObject];
    if (appendComponent) {
        resolvedPath = [resolvedPath stringByAppendingPathComponent:appendComponent];
    }

    NSError *error;
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:resolvedPath withIntermediateDirectories:YES attributes:nil error:&error];

    if (!success) {
        if (outError) *outError = error;
        return nil;
    }

    if (outError) *outError = nil;

    return resolvedPath;
}


NSString *sGetApplicationSupportDirectory()
{
    NSString *name = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
    return sFindOrCreateDirectory(NSApplicationSupportDirectory, NSUserDomainMask, name, NULL);
}



@implementation AppDelegate {
    NSStatusItem      *_statusItem;
    HueManager        *_hueManager;
    CBBlueLightClient *_blueLightClient;
    NSArray<Preset *> *_presets;
    Preset            *_currentPreset;
}


- (NSURL *) _settingsURLFile
{
    NSString *appSupport = sGetApplicationSupportDirectory();
    NSString *settingsJson = [appSupport stringByAppendingPathComponent:@"settings.json"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:settingsJson]) {
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"settings" ofType:@"json"];
        [[NSFileManager defaultManager] copyItemAtPath:bundlePath toPath:settingsJson error:NULL];
    }

    return [NSURL fileURLWithPath:settingsJson];
}


- (BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
    SEL action = [menuItem action];

    if (action == @selector(revealSettings:) || action == @selector(reloadSettings:)) {
        NSUInteger modifierFlags = [NSEvent modifierFlags];
        
        NSUInteger mask = NSEventModifierFlagOption;
        BOOL visible = ((modifierFlags & mask) == mask);
    
        [[self revealSeparator] setHidden:!visible];
        [[self revealMenuItem]  setHidden:!visible];
        [[self reloadMenuItem]  setHidden:!visible];

        return YES;
    }

    return YES;
}

- (void) _readSettings
{
    NSData *data = [NSData dataWithContentsOfURL:[self _settingsURLFile]];
    
    NSError *error = nil;
    id settingsDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

    // Read presets
    {
        NSMutableArray *presets = [NSMutableArray array];

        for (NSDictionary *dictionary in [settingsDictionary objectForKey:@"presets"]) {
            Preset *preset = [[Preset alloc] initWithDictionary:dictionary];
            if (preset) [presets addObject:preset];
        }

        _presets = presets;
    }
    
    // Read Hue URL
    {
        NSString *hueURLString = [settingsDictionary objectForKey:@"hue-url"];
        NSURL    *hueURL       = hueURLString ? [NSURL URLWithString:hueURLString] : nil;
        
        [_hueManager setBaseURL:hueURL];
    }
    
    NSUInteger presetsCount = [_presets count];

    NSSlider *slider = [self slider];
    [slider setMinValue:0];
    [slider setMaxValue:(presetsCount - 1)];
}


- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _hueManager = [[HueManager alloc] init];
    _blueLightClient = [[CBBlueLightClient alloc] init];
    
    NSStatusItem *statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:28];
    [statusItem setVisible:YES];
    [statusItem setBehavior:NSStatusItemBehaviorTerminationOnRemoval];
    _statusItem = statusItem;

    [_statusItem setMenu:[self statusMenu]];
    [_statusItem setImage:[NSImage imageNamed:@"DaylightIcon"]];

    [self _readSettings];

    float currentCCT = 0;
    if ([_blueLightClient getCCT:&currentCCT]) {
        [self _updateWithPresetNearestWhitePoint:currentCCT];
    }
}


- (void) _updateWithPresetNearestWhitePoint:(double)temperature
{
    double maxDistance = INFINITY;
    Preset *closetPreset;
    for (Preset *preset in _presets) {
        double distance = fabs([preset CCTWhitePoint] - temperature);

        if (distance < maxDistance) {
            maxDistance = distance;
            closetPreset = preset;
        }
    }
    
    [self _updateWithPreset:closetPreset];
}


- (void) _updateWithPreset:(Preset *)preset
{
    if (preset == _currentPreset) return;

    if ([preset usesHueWhitePoint] && [_hueManager baseURL]) {
        [_hueManager updateWhitePoint:[preset hueWhitePoint]];
    }

    if ([preset usesCCTWhitePoint]) {
        [_blueLightClient setCCT:[preset CCTWhitePoint] commit:YES];
        [_blueLightClient setEnabled:YES];
    } else {
        [_blueLightClient setEnabled:NO];
    }
    
    if ([preset usesXYWhitePoint]) {
        CGPoint whitePoint = [preset XYWhitePoint];
        CoreDisplay_SetWhitePointWithDuration(whitePoint.x, whitePoint.y, 0.5);
    }
    
    NSString *name = [preset name];
    [[self nameLabel] setStringValue:name ? name : @""];

    [[self slider] setIntegerValue:[_presets indexOfObject:preset]];
    
    _currentPreset = preset;
}

- (IBAction) revealSettings:(id)sender
{
    [[NSWorkspace sharedWorkspace] selectFile:[[self _settingsURLFile] path] inFileViewerRootedAtPath:sGetApplicationSupportDirectory()];
}



- (IBAction) reloadSettings:(id)sender
{
    [self _readSettings];
}


- (IBAction) handleSlider:(id)sender
{
    NSInteger index = lround([[self slider] doubleValue]);
    
    if (index >= 0 && index < [_presets count]) {
        Preset *preset = [_presets objectAtIndex:index];
        [self _updateWithPreset:preset];

        [[self slider] setIntegerValue:[_presets indexOfObject:preset]];

    
    }
}


@end
