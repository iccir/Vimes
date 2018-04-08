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

#import "HueManager.h"

@implementation HueManager {
    NSURLSession *_session;
    CFAbsoluteTime _lastUpdate;
    double _temperature;
}


- (void) _sendUpdate
{
    if (!_temperature) return;

    NSURL *baseURL = [self baseURL];
    if (!baseURL) return;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:baseURL];
    if (!request) return;

    NSInteger ct = (NSInteger)floor(1000000 / _temperature);

    NSError *error = nil;
    NSData *body = [NSJSONSerialization dataWithJSONObject:@{
        @"ct": @(ct),
        @"transitiontime": @10
    } options:0 error:&error];
    
    if (error || !body) return;
    
    [request setHTTPMethod:@"PUT"];
    [request setHTTPBody:body];

    __weak id weakSelf = self;

    if (!_session) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:configuration];
    }

    [[_session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            [weakSelf _sendIfReady];
        }
    }] resume];
    
    _lastUpdate = CFAbsoluteTimeGetCurrent();
}


- (void) _sendIfReady
{
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    CFTimeInterval delay = 1.0 - (now - _lastUpdate);
    
    if (delay < 0) {
        [self _sendUpdate];
    } else {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:_cmd object:nil];
        [self performSelector:_cmd withObject:nil afterDelay:delay];
    }
}


- (void) updateWhitePoint:(double)temperature
{
    if (_temperature != temperature) {
        _temperature = temperature;
        [self _sendIfReady];
    }
}


@end
