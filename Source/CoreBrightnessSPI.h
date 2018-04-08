@interface CBBlueLightClient : NSObject

+ (BOOL)supportsBlueLightReduction; 

- (instancetype) init;

- (BOOL) setCCT:(float)temperature commit:(BOOL)commit;
- (BOOL) getCCT:(float *)temperature;

- (BOOL) setEnabled:(BOOL)yn;
- (BOOL) setActive:(BOOL)yn;

@end
