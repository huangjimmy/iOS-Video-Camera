//
//  PDInputDomain.h
//  PonyDebugger
//
//  Created by HUANG,Shaojun on 7/16/16.
//  Copyright © 2016 yidian. All rights reserved.
//

#import "PDDynamicDebuggerDomain.h"

@class PDInputDomain;

@protocol PDInputCommandDelegate <PDCommandDelegate>
@optional


/// Dispatches a key event to the page.
// Param type: Type of the key event.
// Param modifiers: Bit field representing pressed modifier keys. Alt=1, Ctrl=2, Meta/Command=4, Shift=8 (default: 0).
// Param timestamp: Time at which the event occurred. Measured in UTC time in seconds since January 1, 1970 (default: current time).
// Param text: Text as generated by processing a virtual key code with a keyboard layout. Not needed for for <code>keyUp</code> and <code>rawKeyDown</code> events (default: "")
// Param unmodifiedText: Text that would have been generated by the keyboard if no modifiers were pressed (except for shift). Useful for shortcut (accelerator) key handling (default: "").
// Param keyIdentifier: Unique key identifier (e.g., 'U+0041') (default: "").
// Param code: Unique DOM defined string value for each physical key (e.g., 'KeyA') (default: "").
// Param key: Unique DOM defined string value describing the meaning of the key in the context of active modifiers, keyboard layout, etc (e.g., 'AltGr') (default: "").
// Param windowsVirtualKeyCode: Windows virtual key code (default: 0).
// Param nativeVirtualKeyCode: Native virtual key code (default: 0).
// Param autoRepeat: Whether the event was generated from auto repeat (default: false).
// Param isKeypad: Whether the event was generated from the keypad (default: false).
// Param isSystemKey: Whether the event was a system key event (default: false).
- (void)domain:(PDInputDomain *)domain dispatchKeyEventWithType:(NSString *)type modifiers:(NSNumber *)modifiers timestamp:(NSNumber *)timestamp text:(NSString *)text unmodifiedText:(NSString *)unmodifiedText keyIdentifier:(NSString *)keyIdentifier code:(NSString *)code key:(NSString *)key windowsVirtualKeyCode:(NSNumber *)windowsVirtualKeyCode nativeVirtualKeyCode:(NSNumber *)nativeVirtualKeyCode autoRepeat:(NSNumber *)autoRepeat isKeypad:(NSNumber *)isKeypad isSystemKey:(NSNumber *)isSystemKey callback:(void (^)(id error))callback;

/// Dispatches a mouse event to the page.
// Param type: Type of the mouse event.
// Param x: X coordinate of the event relative to the main frame's viewport.
// Param y: Y coordinate of the event relative to the main frame's viewport. 0 refers to the top of the viewport and Y increases as it proceeds towards the bottom of the viewport.
// Param modifiers: Bit field representing pressed modifier keys. Alt=1, Ctrl=2, Meta/Command=4, Shift=8 (default: 0).
// Param timestamp: Time at which the event occurred. Measured in UTC time in seconds since January 1, 1970 (default: current time).
// Param button: Mouse button (default: "none").
// Param clickCount: Number of times the mouse button was clicked (default: 0).
- (void)domain:(PDInputDomain *)domain dispatchMouseEventWithType:(NSString *)type x:(NSNumber *)x y:(NSNumber *)y modifiers:(NSNumber *)modifiers timestamp:(NSNumber *)timestamp button:(NSString *)button clickCount:(NSNumber *)clickCount callback:(void (^)(id error))callback;

/// Dispatches a touch event to the page.
// Param type: Type of the touch event.
// Param touchPoints: Touch points.
// Param modifiers: Bit field representing pressed modifier keys. Alt=1, Ctrl=2, Meta/Command=4, Shift=8 (default: 0).
// Param timestamp: Time at which the event occurred. Measured in UTC time in seconds since January 1, 1970 (default: current time).
- (void)domain:(PDInputDomain *)domain dispatchTouchEventWithType:(NSString *)type touchPoints:(NSArray *)touchPoints modifiers:(NSNumber *)modifiers timestamp:(NSNumber *)timestamp callback:(void (^)(id error))callback;

/// Emulates touch event from the mouse event parameters.
// Param type: Type of the mouse event.
// Param x: X coordinate of the mouse pointer in DIP.
// Param y: Y coordinate of the mouse pointer in DIP.
// Param timestamp: Time at which the event occurred. Measured in UTC time in seconds since January 1, 1970.
// Param button: Mouse button.
// Param deltaX: X delta in DIP for mouse wheel event (default: 0).
// Param deltaY: Y delta in DIP for mouse wheel event (default: 0).
// Param modifiers: Bit field representing pressed modifier keys. Alt=1, Ctrl=2, Meta/Command=4, Shift=8 (default: 0).
// Param clickCount: Number of times the mouse button was clicked (default: 0).
- (void)domain:(PDInputDomain *)domain emulateTouchFromMouseEventWithType:(NSString *)type x:(NSNumber *)x y:(NSNumber *)y timestamp:(NSNumber *)timestamp button:(NSString *)button deltaX:(NSNumber *)deltaX deltaY:(NSNumber *)deltaY modifiers:(NSNumber *)modifiers clickCount:(NSNumber *)clickCount callback:(void (^)(id error))callback;

/// Synthesizes a pinch gesture over a time period by issuing appropriate touch events.
// Param x: X coordinate of the start of the gesture in CSS pixels.
// Param y: Y coordinate of the start of the gesture in CSS pixels.
// Param scaleFactor: Relative scale factor after zooming (>1.0 zooms in, <1.0 zooms out).
// Param relativeSpeed: Relative pointer speed in pixels per second (default: 800).
// Param gestureSourceType: Which type of input events to be generated (default: 'default', which queries the platform for the preferred input type).
- (void)domain:(PDInputDomain *)domain synthesizePinchGestureWithX:(NSNumber *)x y:(NSNumber *)y scaleFactor:(NSNumber *)scaleFactor relativeSpeed:(NSNumber *)relativeSpeed gestureSourceType:(NSString *)gestureSourceType callback:(void (^)(id error))callback;

/// Synthesizes a scroll gesture over a time period by issuing appropriate touch events.
// Param x: X coordinate of the start of the gesture in CSS pixels.
// Param y: Y coordinate of the start of the gesture in CSS pixels.
// Param xDistance: The distance to scroll along the X axis (positive to scroll left).
// Param yDistance: The distance to scroll along the Y axis (positive to scroll up).
// Param xOverscroll: The number of additional pixels to scroll back along the X axis, in addition to the given distance.
// Param yOverscroll: The number of additional pixels to scroll back along the Y axis, in addition to the given distance.
// Param preventFling: Prevent fling (default: true).
// Param speed: Swipe speed in pixels per second (default: 800).
// Param gestureSourceType: Which type of input events to be generated (default: 'default', which queries the platform for the preferred input type).
- (void)domain:(PDInputDomain *)domain synthesizeScrollGestureWithX:(NSNumber *)x y:(NSNumber *)y xDistance:(NSNumber *)xDistance yDistance:(NSNumber *)yDistance xOverscroll:(NSNumber *)xOverscroll yOverscroll:(NSNumber *)yOverscroll preventFling:(NSNumber *)preventFling speed:(NSNumber *)speed gestureSourceType:(NSString *)gestureSourceType callback:(void (^)(id error))callback;

/// Synthesizes a tap gesture over a time period by issuing appropriate touch events.
// Param x: X coordinate of the start of the gesture in CSS pixels.
// Param y: Y coordinate of the start of the gesture in CSS pixels.
// Param duration: Duration between touchdown and touchup events in ms (default: 50).
// Param tapCount: Number of times to perform the tap (e.g. 2 for double tap, default: 1).
// Param gestureSourceType: Which type of input events to be generated (default: 'default', which queries the platform for the preferred input type).
- (void)domain:(PDInputDomain *)domain synthesizeTapGestureWithX:(NSNumber *)x y:(NSNumber *)y duration:(NSNumber *)duration tapCount:(NSNumber *)tapCount gestureSourceType:(NSString *)gestureSourceType callback:(void (^)(id error))callback;

@end

@interface PDInputDomain : PDDynamicDebuggerDomain

@property (nonatomic, assign) id <PDInputCommandDelegate, PDCommandDelegate> delegate;

@end

