/*
 *  Copyright (C) 2012-2018 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "platform/darwin/ios-common/IOSKeyboard.h"

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ShowKeyboardState) {
  KEYBOARD_NOT_SHOW,
  KEYBOARD_WILL_SHOW,
  KEYBOARD_SHOWING
};

@interface KeyboardView : UIView <UITextFieldDelegate>
{
  bool* m_canceled;
  BOOL m_deactivated;
  UITextField* m_textField;
  UITextField* m_heading;
  ShowKeyboardState m_keyboardIsShowing;
  CGRect m_kbRect;
}

@property(nonatomic, strong) NSMutableString* text;
@property(getter=isConfirmed) BOOL confirmed;
@property(assign) CIOSKeyboard* iosKeyboard;

- (void)setHeading:(NSString*)heading;
- (void)setHidden:(BOOL)hidden;
- (void)activate;
- (void)deactivate;
- (void)setKeyboardText:(NSString*)aText closeKeyboard:(BOOL)closeKeyboard;
- (void)textChanged:(NSNotification*)aNotification;
- (void)setCancelFlag:(bool*)cancelFlag;
- (void)doDeactivate:(NSDictionary*)dict;
@end
