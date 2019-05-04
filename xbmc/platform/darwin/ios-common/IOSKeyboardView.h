/*
 *  Copyright (C) 2012-2018 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "platform/darwin/ios-common/IOSKeyboard.h"

#import <UIKit/UIKit.h>

@interface KeyboardView : UIView <UITextFieldDelegate>
{
  bool *_canceled;
  BOOL _deactivated;
  UITextField *_textField;
  UITextField *_heading;
#if defined(TARGET_DARWIN_IOS)
  int _keyboardIsShowing; // 0: not, 1: will show, 2: showing
#endif
  CGRect _kbRect;
}

@property (nonatomic, strong) NSMutableString* text;
@property (getter = isConfirmed) BOOL confirmed;
@property (assign) CIOSKeyboard* iosKeyboard;

- (void) setHeading:(NSString *)heading;
- (void) setHidden:(BOOL)hidden;
- (void) activate;
- (void) deactivate;
- (void) setKeyboardText:(NSString*)aText closeKeyboard:(BOOL)closeKeyboard;
- (void) textChanged:(NSNotification*)aNotification;
- (void) setCancelFlag:(bool *)cancelFlag;
- (void) doDeactivate:(NSDictionary *)dict;
@end
