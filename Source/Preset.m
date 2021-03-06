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

#import "Preset.h"


@implementation Preset

- (instancetype) initWithDictionary:(NSDictionary *)dictionary
{
    if ((self = [super init])) {
        id XYArray   = [dictionary objectForKey:@"xy"];
        id CCTNumber = [dictionary objectForKey:@"cct"];
        id hueNumber = [dictionary objectForKey:@"hue"];
        
        _name = [dictionary objectForKey:@"name"];

        if ([XYArray isKindOfClass:[NSArray class]]) {
            _usesXYWhitePoint = YES;
            
            _XYWhitePoint = CGPointMake(
                [[XYArray firstObject] doubleValue],
                [[XYArray lastObject]  doubleValue]
            );
        }

        if ([CCTNumber isKindOfClass:[NSNumber class]]) {
            _usesCCTWhitePoint = YES;
            _CCTWhitePoint = [CCTNumber doubleValue];
        }

        if ([hueNumber isKindOfClass:[NSNumber class]]) {
            _usesHueWhitePoint = YES;
            _hueWhitePoint = [hueNumber doubleValue];
        }    
    }
    
    return self;
}

@end
