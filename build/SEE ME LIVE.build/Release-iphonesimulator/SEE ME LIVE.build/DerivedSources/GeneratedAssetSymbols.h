#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"comedy.SEE-ME-LIVE";

/// The "AccentColor" asset catalog color resource.
static NSString * const ACColorNameAccentColor AC_SWIFT_PRIVATE = @"AccentColor";

/// The "AppBackground" asset catalog color resource.
static NSString * const ACColorNameAppBackground AC_SWIFT_PRIVATE = @"AppBackground";

/// The "CardBackground" asset catalog color resource.
static NSString * const ACColorNameCardBackground AC_SWIFT_PRIVATE = @"CardBackground";

/// The "SplashIcon" asset catalog image resource.
static NSString * const ACImageNameSplashIcon AC_SWIFT_PRIVATE = @"SplashIcon";

#undef AC_SWIFT_PRIVATE
