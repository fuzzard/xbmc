/*
 *  Copyright (C) 2012-2018 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import "IOSKeyboardView.h"

#include "Application.h"
#include "guilib/GUIKeyboardFactory.h"
#include "threads/Event.h"
#include "utils/log.h"

#import "platform/darwin/ios/IOSScreenManager.h"
#import "platform/darwin/ios/XBMCController.h"

static CEvent keyboardFinishedEvent;

static const int INPUT_BOX_HEIGHT = 30;
static const int SPACE_BETWEEN_INPUT_AND_KEYBOARD = 0;

@implementation KeyboardView

@synthesize confirmed = m_confirmed;
@synthesize iosKeyboard = m_iosKeyboard;
@synthesize text = m_text;

- (instancetype)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (!self)
    return nil;

  m_keyboardIsShowing = KEYBOARD_NOT_SHOW;
  m_confirmed = NO;
  m_canceled = NULL;
  m_deactivated = NO;

  m_text = [NSMutableString string];

  // default input box position above the half screen.
  CGRect textFieldFrame =
      CGRectMake(frame.size.width / 2,
                 frame.size.height / 2 - INPUT_BOX_HEIGHT - SPACE_BETWEEN_INPUT_AND_KEYBOARD,
                 frame.size.width / 2, INPUT_BOX_HEIGHT);
  m_textField = [[UITextField alloc] initWithFrame:textFieldFrame];
  m_textField.clearButtonMode = UITextFieldViewModeAlways;
  m_textField.borderStyle = UITextBorderStyleNone;
  m_textField.returnKeyType = UIReturnKeyDone;
  m_textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
  m_textField.backgroundColor = [UIColor whiteColor];
  m_textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
  m_textField.delegate = self;

  CGRect labelFrame = textFieldFrame;
  labelFrame.origin.x = 0;
  m_heading = [[UITextField alloc] initWithFrame:labelFrame];
  m_heading.borderStyle = UITextBorderStyleNone;
  m_heading.backgroundColor = [UIColor whiteColor];
  m_heading.adjustsFontSizeToFitWidth = YES;
  m_heading.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
  m_heading.enabled = NO;

  [self addSubview:m_heading];
  [self addSubview:m_textField];

  self.userInteractionEnabled = YES;

  [self setAlpha:0.9];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(textChanged:)
                                               name:UITextFieldTextDidChangeNotification
                                             object:m_textField];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardDidHide:)
                                               name:UIKeyboardDidHideNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardDidChangeFrame:)
                                               name:UIKeyboardDidChangeFrameNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardDidShow:)
                                               name:UIKeyboardDidShowNotification
                                             object:nil];
  return self;
}

- (void)layoutSubviews
{
  CGFloat headingW = 0;
  if (m_heading.text && m_heading.text.length > 0)
  {
    CGSize headingSize = [m_heading.text sizeWithAttributes:@{
      NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]]
    }];

    headingW = MIN(self.bounds.size.width / 2, headingSize.width + 30);
  }

  CGFloat y = m_kbRect.origin.y - INPUT_BOX_HEIGHT - SPACE_BETWEEN_INPUT_AND_KEYBOARD;

  m_heading.frame = CGRectMake(0, y, headingW, INPUT_BOX_HEIGHT);
  m_textField.frame = CGRectMake(headingW, y, self.bounds.size.width - headingW, INPUT_BOX_HEIGHT);
}

- (void)keyboardWillShow:(NSNotification*)notification
{
  NSDictionary* info = [notification userInfo];
  CGRect kbRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
  CLog::Log(LOGDEBUG, "keyboardWillShow: keyboard frame: {}", NSStringFromCGRect(kbRect).UTF8String);
  m_kbRect = kbRect;
  [self setNeedsLayout];
  m_keyboardIsShowing = KEYBOARD_WILL_SHOW;
}

- (void)keyboardDidShow:(NSNotification*)notification
{
  CLog::Log(LOGDEBUG, "keyboardDidShow: deactivated: {}", m_deactivated);
  m_keyboardIsShowing = KEYBOARD_SHOWING;
  if (m_deactivated)
    [self doDeactivate:nil];
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
  [m_textField resignFirstResponder];
}

- (BOOL)textFieldShouldEndEditing:(UITextField*)textField
{
  CLog::Log(LOGDEBUG, "{}: keyboard IsShowing {}", __PRETTY_FUNCTION__, m_keyboardIsShowing);
  // Do not break the keyboard show up process, else we will lose
  // keyboard did hide notification.
  return m_keyboardIsShowing != KEYBOARD_WILL_SHOW;
}

- (void)textFieldDidEndEditing:(UITextField*)textField
{
  [self deactivate];
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
  m_confirmed = YES;
  [m_textField resignFirstResponder];

  return YES;
}

- (void)keyboardDidChangeFrame:(id)sender
{
}

- (void)keyboardDidHide:(id)sender
{
  m_keyboardIsShowing = KEYBOARD_NOT_SHOW;

  if (m_textField.editing)
  {
    CLog::Log(LOGDEBUG, "kb hide when editing, it could be a language switch");
    return;
  }

  [self deactivate];
}

- (void)doActivate:(NSDictionary*)dict
{
  [g_xbmcController activateKeyboard:self];
  [m_textField becomeFirstResponder];
  [self setNeedsLayout];
  keyboardFinishedEvent.Reset();
}

- (void)activate
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    dispatch_sync(dispatch_get_main_queue(), ^{
      [self doActivate:nil];
    });
  }
  else
  {
    // this would be fatal! We never should be called from the ios mainthread
    return;
  }

  // we are waiting on the user finishing the keyboard
  while (!keyboardFinishedEvent.WaitMSec(500))
  {
    if (nullptr != m_canceled && *m_canceled)
    {
      [self deactivate];
      m_canceled = nullptr;
    }
  }
}

- (void)doDeactivate:(NSDictionary*)dict
{

  CLog::Log(LOGDEBUG, "{}: keyboard IsShowing {}", __PRETTY_FUNCTION__, m_keyboardIsShowing);
  m_deactivated = YES;

  // Do not break keyboard show up process, if so there's a bug of ios4 will not
  // notify us keyboard hide.
  if (m_keyboardIsShowing == KEYBOARD_WILL_SHOW)
    return;

  // invalidate our callback object
  if (m_iosKeyboard)
  {
    m_iosKeyboard->invalidateCallback();
    m_iosKeyboard = nil;
  }
  // give back the control to whoever
  [m_textField resignFirstResponder];

  // delay closing view until text field finishes resigning first responder
  dispatch_async(dispatch_get_main_queue(), ^{
    // always called in the mainloop context
    // detach the keyboard view from our main controller
    [g_xbmcController deactivateKeyboard:self];

    // no more notification we want to receive.
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    keyboardFinishedEvent.Set();
  });
}

- (void)deactivate
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    dispatch_sync(dispatch_get_main_queue(), ^{
      [self doDeactivate:nil];
    });
  }
  else
    [self doDeactivate:nil];
}

- (void)setKeyboardText:(NSString*)aText closeKeyboard:(BOOL)closeKeyboard
{
  CLog::Log(LOGDEBUG, "{}: {}, {}", __PRETTY_FUNCTION__, aText.UTF8String, closeKeyboard);
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    dispatch_sync(dispatch_get_main_queue(), ^{
      [self setDefault:aText];
    });
  }
  else
    [self setDefault:aText];

  if (closeKeyboard)
  {
    m_confirmed = YES;
    [self deactivate];
  }
}

- (void)setHeading:(NSString*)heading
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    dispatch_sync(dispatch_get_main_queue(), ^{
      [self setHeadingInternal:heading];
    });
  }
  else
  {
    [self setHeadingInternal:heading];
  }
}

- (void)setHeadingInternal:(NSString*)heading
{
  if (heading && heading.length > 0)
    m_heading.text = [NSString stringWithFormat:@" %@:", heading];
  else
    m_heading.text = nil;
}

- (void)setDefault:(NSString*)defaultText
{
  m_textField.text = defaultText;
  [self textChanged:nil];
}

- (void)setHiddenInternal:(NSNumber*)hidden
{
  BOOL hiddenBool = hidden.boolValue;
  m_textField.secureTextEntry = hiddenBool;
}

- (void)setHidden:(BOOL)hidden
{
  NSNumber* passedValue = @(hidden);

  if ([NSThread currentThread] != [NSThread mainThread])
  {
    dispatch_sync(dispatch_get_main_queue(), ^{
      [self setHiddenInternal:passedValue];
    });
  }
  else
  {
    [self setHiddenInternal:passedValue];
  }
}

- (void)textChanged:(NSNotification*)aNotification
{
  if (![self.text isEqualToString:m_textField.text])
  {
    [self.text setString:m_textField.text];
    if (m_iosKeyboard)
      m_iosKeyboard->fireCallback([self text].UTF8String);
  }
}

- (void)setCancelFlag:(bool*)cancelFlag
{
  m_canceled = cancelFlag;
}

@end
