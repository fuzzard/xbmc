/*
 *  Copyright (C) 2020 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import "Input_Gamecontroller.h"

#include "addons/kodi-addon-dev-kit/include/kodi/addon-instance/PeripheralUtils.h"
#include "threads/CriticalSection.h"
#include "threads/SingleLock.h"
#include "utils/log.h"

#import "platform/darwin/ios-common/peripherals/InputKey.h"
#import "platform/darwin/ios-common/peripherals/PeripheralBusDarwinEmbeddedManager.h"

#import <Foundation/Foundation.h>
#import <GameController/GCController.h>

@implementation Input_IOSGamecontroller

#pragma mark - Notificaton Observer

- (void)addModeSwitchObserver
{
  // notifications for controller (dis)connect
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(controllerWasConnected:)
                                               name:GCControllerDidConnectNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(controllerWasDisconnected:)
                                               name:GCControllerDidDisconnectNotification
                                             object:nil];
}

#pragma mark - Controller connection

- (void)controllerWasConnected:(NSNotification*)notification
{
  GCController* controller = (GCController*)notification.object;

  [self controllerConnection:controller];
}

- (void)controllerConnection:(GCController*)controller
{
  for (id controlObj in controllerArray)
  {
    if ([controlObj isEqual:controller])
    {
      CLog::Log(LOGINFO,
                "CPeripheralBusDarwinEmbedded: ignoring input device with ID {} already known",
                [controller.vendorName UTF8String]);
      return;
    }
  }

  // ToDo: Manage multiple player controllers
  // Assign playerIndex - GCControllerPlayerIndex1 - GCControllerPlayerIndex4

  controller.playerIndex = GCControllerPlayerIndex1;

  // set microgamepad to absolute values for dpad (ie center touchpad is 0,0)
  if (controller.microGamepad != nil)
    controller.microGamepad.reportsAbsoluteDpadValues = YES;

  CLog::Log(LOGDEBUG, "CPeripheralBusDarwinEmbedded: input device with ID {} playerIndex {} added ",
            [controller.vendorName UTF8String], (unsigned long)controller.playerIndex);
  [controllerArray addObject:controller];

  [cbmanager DeviceAdded:static_cast<int>(controller.playerIndex)];

  [self registerChangeHandler:controller];
}

- (void)registerChangeHandler:(GCController*)controller
{
  if (controller.extendedGamepad)
  {
    CLog::Log(LOGDEBUG, "INPUT - GAMECONTROLLER: extendedGamepad changehandler added");
    // register block for input change detection
    [self extendedValueChangeHandler:controller];
  }
  else if (controller.microGamepad)
  {
    CLog::Log(LOGDEBUG, "INPUT - GAMECONTROLLER: microGamepad changehandler added");
    [self microValueChangeHandler:controller];
  }
}

#pragma mark - Controller disconnection

- (void)controllerWasDisconnected:(NSNotification*)notification
{
  // a controller was disconnected
  GCController* controller = (GCController*)notification.object;

  // remove the device from the Controller Array
  for (NSInteger i = 0; i < controllerArray.count; ++i)
  {
    if (![controllerArray[i] isEqual:controller])
      continue;

    CLog::Log(LOGINFO, "CPeripheralBusDarwinEmbedded: input device \"{}\" removed",
              [controller.vendorName UTF8String]);
    controller.playerIndex = GCControllerPlayerIndexUnset;
    [controllerArray removeObjectAtIndex:i];

    [cbmanager DeviceAdded:static_cast<int>(controller.playerIndex)];

    return;
  }

  CLog::Log(LOGWARNING, "CPeripheralBusDarwinEmbedded: failed to remove input device {} Not Found ",
            [controller.vendorName UTF8String]);
}

#pragma mark - GCMicroGamepad valueChangeHandler

- (void)microValueChangeHandler:(GCController*)controller
{
  GCMicroGamepad* profile = controller.microGamepad;
  profile.valueChangedHandler = ^(GCMicroGamepad* gamepad, GCControllerElement* element) {
    NSString* message = @"";

    kodi::addon::PeripheralEvent newEvent = {};
    newEvent.SetPeripheralIndex(static_cast<int>(controller.playerIndex));

    CSingleLock lock(m_GCMutex);

    // A button
    if (gamepad.buttonA == element)
    {
      message = [self setButtonState:gamepad.buttonA
                           withEvent:&newEvent
                         withMessage:@"A Button"
                       withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::MICRO,
                                                    GCCONTROLLER_MICRO_GAMEPAD_BUTTON::A}];
    }
    // X button
    if (gamepad.buttonX == element)
    {
      message = [self setButtonState:gamepad.buttonX
                           withEvent:&newEvent
                         withMessage:@"X Button"
                       withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::MICRO,
                                                    GCCONTROLLER_MICRO_GAMEPAD_BUTTON::X}];
    }
#if __TV_OS_VERSION_MAX_ALLOWED >= 130000 || __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    // buttonMenu
    if (@available(iOS 13.0, tvOS 13.0, *))
    {
      if (gamepad.buttonMenu == element)
      {
        message = [self setButtonState:gamepad.buttonMenu
                             withEvent:&newEvent
                           withMessage:@"Menu Button"
                         withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::MICRO,
                                                      GCCONTROLLER_MICRO_GAMEPAD_BUTTON::MENU}];
      }
    }
#endif
    // d-pad
    if (gamepad.dpad == element)
    {
      if ((gamepad.dpad.up.isPressed && !dpadUpPressed) ||
          (!gamepad.dpad.up.isPressed && dpadUpPressed))
      {
        message = @"D-Pad Up";
        if (!dpadUpPressed)
        {
          // Button Down event
          message = [self setButtonState:gamepad.dpad.up
                               withEvent:&newEvent
                             withMessage:message
                           withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::MICRO,
                                                        GCCONTROLLER_MICRO_GAMEPAD_BUTTON::UP}];
        }
        else
        {
          // Button Up event
          kodi::addon::PeripheralEvent newReleaseEvent = {};
          newReleaseEvent.SetPeripheralIndex(static_cast<unsigned int>(controller.playerIndex));
          message = [self setButtonState:gamepad.dpad.up
                               withEvent:&newReleaseEvent
                             withMessage:message
                           withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::MICRO,
                                                        GCCONTROLLER_MICRO_GAMEPAD_BUTTON::UP}];
          [cbmanager SetDigitalEvent:newReleaseEvent];
        }
        dpadUpPressed = !dpadUpPressed;
      }
      if ((gamepad.dpad.down.isPressed && !dpadDownPressed) ||
          (!gamepad.dpad.down.isPressed && dpadDownPressed))
      {
        message = @"D-Pad Down";
        if (!dpadDownPressed)
        {
          // Button Down event
          message = [self setButtonState:gamepad.dpad.down
                               withEvent:&newEvent
                             withMessage:message
                           withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::MICRO,
                                                        GCCONTROLLER_MICRO_GAMEPAD_BUTTON::DOWN}];
        }
        else
        {
          // Button Up event
          kodi::addon::PeripheralEvent newReleaseEvent = {};
          newReleaseEvent.SetPeripheralIndex(static_cast<unsigned int>(controller.playerIndex));
          message = [self setButtonState:gamepad.dpad.down
                               withEvent:&newReleaseEvent
                             withMessage:message
                           withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::MICRO,
                                                        GCCONTROLLER_MICRO_GAMEPAD_BUTTON::DOWN}];
          [cbmanager SetDigitalEvent:newReleaseEvent];
        }
        dpadDownPressed = !dpadDownPressed;
      }
      if ((gamepad.dpad.left.isPressed && !dpadLeftPressed) ||
          (!gamepad.dpad.left.isPressed && dpadLeftPressed))
      {
        message = @"D-Pad Left";
        if (!dpadLeftPressed)
        {
          // Button Down event
          message = [self setButtonState:gamepad.dpad.left
                               withEvent:&newEvent
                             withMessage:message
                           withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::MICRO,
                                                        GCCONTROLLER_MICRO_GAMEPAD_BUTTON::LEFT}];
        }
        else
        {
          // Button Up event
          kodi::addon::PeripheralEvent newReleaseEvent = {};
          newReleaseEvent.SetPeripheralIndex(static_cast<unsigned int>(controller.playerIndex));
          message = [self setButtonState:gamepad.dpad.left
                               withEvent:&newReleaseEvent
                             withMessage:message
                           withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::MICRO,
                                                        GCCONTROLLER_MICRO_GAMEPAD_BUTTON::LEFT}];
          [cbmanager SetDigitalEvent:newReleaseEvent];
        }
        dpadLeftPressed = !dpadLeftPressed;
      }
      if ((gamepad.dpad.right.isPressed && !dpadRightPressed) ||
          (!gamepad.dpad.right.isPressed && dpadRightPressed))
      {
        message = @"D-Pad Right";
        if (!dpadRightPressed)
        {
          // Button Down event
          message = [self setButtonState:gamepad.dpad.right
                               withEvent:&newEvent
                             withMessage:message
                           withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::MICRO,
                                                        GCCONTROLLER_MICRO_GAMEPAD_BUTTON::RIGHT}];
        }
        else
        {
          // Button Up event
          kodi::addon::PeripheralEvent newReleaseEvent = {};
          newReleaseEvent.SetPeripheralIndex(static_cast<unsigned int>(controller.playerIndex));
          message = [self setButtonState:gamepad.dpad.right
                               withEvent:&newReleaseEvent
                             withMessage:message
                           withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::MICRO,
                                                        GCCONTROLLER_MICRO_GAMEPAD_BUTTON::RIGHT}];
          [cbmanager SetDigitalEvent:newReleaseEvent];
        }
        dpadRightPressed = !dpadRightPressed;
      }
    }

    [cbmanager SetDigitalEvent:newEvent];
    // ToDo: Debug Purposes only - excessive log spam
    // utilise spdlog for input compononent logging
    // [cbmanager displayMessage:message controllerID:static_cast<int>(controller.playerIndex)];
  };
}

#pragma mark - GCExtendedGamepad valueChangeHandler

- (void)extendedValueChangeHandler:(GCController*)controller
{
  auto profile = controller.extendedGamepad;
  profile.valueChangedHandler = ^(GCExtendedGamepad* gamepad, GCControllerElement* element) {
    NSString* message = @"";

    kodi::addon::PeripheralEvent newEvent = {};
    kodi::addon::PeripheralEvent axisEvent = {};
    newEvent.SetPeripheralIndex(static_cast<int>(controller.playerIndex));
    axisEvent.SetPeripheralIndex(static_cast<int>(controller.playerIndex));

    CSingleLock lock(m_GCMutex);

    // left trigger
    if (gamepad.leftTrigger == element)
    {
      message =
          [self setButtonState:gamepad.leftTrigger
                     withEvent:&newEvent
                   withMessage:@"Left Trigger"
                 withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                              GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::LEFTTRIGGER}];
    }
    // right trigger
    if (gamepad.rightTrigger == element)
    {
      message =
          [self setButtonState:gamepad.rightTrigger
                     withEvent:&newEvent
                   withMessage:@"Right Trigger"
                 withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                              GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::RIGHTTRIGGER}];
    }
    // left shoulder button
    if (gamepad.leftShoulder == element)
    {
      message =
          [self setButtonState:gamepad.leftShoulder
                     withEvent:&newEvent
                   withMessage:@"Left Shoulder Button"
                 withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                              GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::LEFTSHOULDER}];
    }
    // right shoulder button
    if (gamepad.rightShoulder == element)
    {
      message =
          [self setButtonState:gamepad.rightShoulder
                     withEvent:&newEvent
                   withMessage:@"Right Shoulder Button"
                 withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                              GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::RIGHTSHOULDER}];
    }
    // A button
    if (gamepad.buttonA == element)
    {
      message = [self setButtonState:gamepad.buttonA
                           withEvent:&newEvent
                         withMessage:@"A Button"
                       withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                    GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::A}];
    }
    // B button
    if (gamepad.buttonB == element)
    {
      message = [self setButtonState:gamepad.buttonB
                           withEvent:&newEvent
                         withMessage:@"B Button"
                       withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                    GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::B}];
    }
    // X button
    if (gamepad.buttonX == element)
    {
      message = [self setButtonState:gamepad.buttonX
                           withEvent:&newEvent
                         withMessage:@"X Button"
                       withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                    GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::X}];
    }
    // Y button
    if (gamepad.buttonY == element)
    {
      message = [self setButtonState:gamepad.buttonY
                           withEvent:&newEvent
                         withMessage:@"Y Button"
                       withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                    GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::Y}];
    }
    // buttonMenu
#if __TV_OS_VERSION_MAX_ALLOWED >= 130000 || __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    if (@available(iOS 13.0, tvOS 13.0, *))
    {
      if (gamepad.buttonMenu == element)
      {
        message = [self setButtonState:gamepad.buttonMenu
                             withEvent:&newEvent
                           withMessage:@"Menu Button"
                         withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                      GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::MENU}];
      }
      // buttonOptions
      if (gamepad.buttonOptions == element)
      {
        message =
            [self setButtonState:gamepad.buttonOptions
                       withEvent:&newEvent
                     withMessage:@"Option Button"
                   withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::OPTION}];
      }
    }
#endif
    // d-pad
    if (gamepad.dpad == element)
    {
      if ((gamepad.dpad.up.isPressed && !dpadUpPressed) ||
          (!gamepad.dpad.up.isPressed && dpadUpPressed))
      {
        message = @"D-Pad Up";
        if (!dpadUpPressed)
        {
          // Button Down event
          message = [self setButtonState:gamepad.dpad.up
                               withEvent:&newEvent
                             withMessage:message
                           withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                        GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::UP}];
        }
        else
        {
          // Button Up event
          kodi::addon::PeripheralEvent newReleaseEvent = {};
          newReleaseEvent.SetPeripheralIndex(static_cast<unsigned int>(controller.playerIndex));
          message = [self setButtonState:gamepad.dpad.up
                               withEvent:&newReleaseEvent
                             withMessage:message
                           withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                        GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::UP}];
          [cbmanager SetDigitalEvent:newReleaseEvent];
        }
        dpadUpPressed = !dpadUpPressed;
      }
      if ((gamepad.dpad.down.isPressed && !dpadDownPressed) ||
          (!gamepad.dpad.down.isPressed && dpadDownPressed))
      {
        message = @"D-Pad Down";
        if (!dpadDownPressed)
        {
          // Button Down event
          message =
              [self setButtonState:gamepad.dpad.down
                         withEvent:&newEvent
                       withMessage:message
                     withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                  GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::DOWN}];
        }
        else
        {
          // Button Up event
          kodi::addon::PeripheralEvent newReleaseEvent = {};
          newReleaseEvent.SetPeripheralIndex(static_cast<unsigned int>(controller.playerIndex));
          message =
              [self setButtonState:gamepad.dpad.down
                         withEvent:&newReleaseEvent
                       withMessage:message
                     withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                  GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::DOWN}];
          [cbmanager SetDigitalEvent:newReleaseEvent];
        }
        dpadDownPressed = !dpadDownPressed;
      }
      if ((gamepad.dpad.left.isPressed && !dpadLeftPressed) ||
          (!gamepad.dpad.left.isPressed && dpadLeftPressed))
      {
        message = @"D-Pad Left";
        if (!dpadLeftPressed)
        {
          // Button Down event
          message =
              [self setButtonState:gamepad.dpad.left
                         withEvent:&newEvent
                       withMessage:message
                     withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                  GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::LEFT}];
        }
        else
        {
          // Button Up event
          kodi::addon::PeripheralEvent newReleaseEvent = {};
          newReleaseEvent.SetPeripheralIndex(static_cast<unsigned int>(controller.playerIndex));
          message =
              [self setButtonState:gamepad.dpad.left
                         withEvent:&newReleaseEvent
                       withMessage:message
                     withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                  GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::LEFT}];
          [cbmanager SetDigitalEvent:newReleaseEvent];
        }
        dpadLeftPressed = !dpadLeftPressed;
      }
      if ((gamepad.dpad.right.isPressed && !dpadRightPressed) ||
          (!gamepad.dpad.right.isPressed && dpadRightPressed))
      {
        message = @"D-Pad Right";
        if (!dpadRightPressed)
        {
          // Button Down event
          message =
              [self setButtonState:gamepad.dpad.right
                         withEvent:&newEvent
                       withMessage:message
                     withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                  GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::RIGHT}];
        }
        else
        {
          // Button Up event
          kodi::addon::PeripheralEvent newReleaseEvent = {};
          newReleaseEvent.SetPeripheralIndex(static_cast<unsigned int>(controller.playerIndex));
          message =
              [self setButtonState:gamepad.dpad.right
                         withEvent:&newReleaseEvent
                       withMessage:message
                     withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                                  GCCONTROLLER_EXTENDED_GAMEPAD_BUTTON::RIGHT}];
          [cbmanager SetDigitalEvent:newReleaseEvent];
        }
        dpadRightPressed = !dpadRightPressed;
      }
    }
    // left stick
    if (gamepad.leftThumbstick == element)
    {
      if (gamepad.leftThumbstick.up.isPressed && (gamepad.leftThumbstick.yAxis.value != 0))
      {
        message =
            [self setAxisValue:gamepad.leftThumbstick.yAxis
                     withEvent:&axisEvent
                   withMessage:[NSString stringWithFormat:@"Left Stick Up %f",
                                                          gamepad.leftThumbstick.yAxis.value]
                 withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                              GCCONTROLLER_EXTENDED_GAMEPAD_AXIS::LEFTTHUMB_Y}];
        [cbmanager SetAxisEvent:axisEvent];
      }
      if (gamepad.leftThumbstick.down.isPressed && (gamepad.leftThumbstick.yAxis.value != 0))
      {
        message =
            [self setAxisValue:gamepad.leftThumbstick.yAxis
                     withEvent:&axisEvent
                   withMessage:[NSString stringWithFormat:@"Left Stick Down %f",
                                                          gamepad.leftThumbstick.yAxis.value]
                 withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                              GCCONTROLLER_EXTENDED_GAMEPAD_AXIS::LEFTTHUMB_Y}];
        [cbmanager SetAxisEvent:axisEvent];
      }
      if (gamepad.leftThumbstick.left.isPressed && (gamepad.leftThumbstick.xAxis.value != 0))
      {
        message =
            [self setAxisValue:gamepad.leftThumbstick.xAxis
                     withEvent:&axisEvent
                   withMessage:[NSString stringWithFormat:@"Left Stick Left %f",
                                                          gamepad.leftThumbstick.xAxis.value]
                 withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                              GCCONTROLLER_EXTENDED_GAMEPAD_AXIS::LEFTTHUMB_X}];
        [cbmanager SetAxisEvent:axisEvent];
      }
      if (gamepad.leftThumbstick.right.isPressed && (gamepad.leftThumbstick.xAxis.value != 0))
      {
        message =
            [self setAxisValue:gamepad.leftThumbstick.xAxis
                     withEvent:&axisEvent
                   withMessage:[NSString stringWithFormat:@"Left Stick Right %f",
                                                          gamepad.leftThumbstick.xAxis.value]
                 withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                              GCCONTROLLER_EXTENDED_GAMEPAD_AXIS::LEFTTHUMB_X}];
        [cbmanager SetAxisEvent:axisEvent];
      }
    }
    // right stick
    if (gamepad.rightThumbstick == element && (gamepad.rightThumbstick.yAxis.value != 0))
    {
      if (gamepad.rightThumbstick.up.isPressed)
      {
        message =
            [self setAxisValue:gamepad.rightThumbstick.yAxis
                     withEvent:&axisEvent
                   withMessage:[NSString stringWithFormat:@"Right Stick Up %f",
                                                          gamepad.rightThumbstick.yAxis.value]
                 withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                              GCCONTROLLER_EXTENDED_GAMEPAD_AXIS::RIGHTTHUMB_Y}];
        [cbmanager SetAxisEvent:axisEvent];
      }
      if (gamepad.rightThumbstick.down.isPressed && (gamepad.rightThumbstick.yAxis.value != 0))
      {
        message =
            [self setAxisValue:gamepad.rightThumbstick.yAxis
                     withEvent:&axisEvent
                   withMessage:[NSString stringWithFormat:@"Right Stick Down %f",
                                                          gamepad.rightThumbstick.yAxis.value]
                 withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                              GCCONTROLLER_EXTENDED_GAMEPAD_AXIS::RIGHTTHUMB_Y}];
        [cbmanager SetAxisEvent:axisEvent];
      }
      if (gamepad.rightThumbstick.left.isPressed && (gamepad.rightThumbstick.xAxis.value != 0))
      {
        message =
            [self setAxisValue:gamepad.rightThumbstick.xAxis
                     withEvent:&axisEvent
                   withMessage:[NSString stringWithFormat:@"Right Stick Left %f",
                                                          gamepad.rightThumbstick.xAxis.value]
                 withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                              GCCONTROLLER_EXTENDED_GAMEPAD_AXIS::RIGHTTHUMB_X}];
        [cbmanager SetAxisEvent:axisEvent];
      }
      if (gamepad.rightThumbstick.right.isPressed && (gamepad.rightThumbstick.xAxis.value != 0))
      {
        message =
            [self setAxisValue:gamepad.rightThumbstick.xAxis
                     withEvent:&axisEvent
                   withMessage:[NSString stringWithFormat:@"Right Stick Right %f",
                                                          gamepad.rightThumbstick.xAxis.value]
                 withInputInfo:InputValueInfo{GCCONTROLLER_TYPE::EXTENDED,
                                              GCCONTROLLER_EXTENDED_GAMEPAD_AXIS::RIGHTTHUMB_X}];
        [cbmanager SetAxisEvent:axisEvent];
      }
    }
    [cbmanager SetDigitalEvent:newEvent];

    //    m_digitalEvents.emplace_back(newEvent);
    // ToDo: Debug Purposes only - excessive log spam
    // utilise spdlog for input compononent logging
    //[cbmanager displayMessage:message controllerID:static_cast<int>(controller.playerIndex)];
  };
}

#pragma mark - valuechangehandler event state change

- (NSString*)setButtonState:(GCControllerButtonInput*)button
                  withEvent:(kodi::addon::PeripheralEvent*)event
                withMessage:(NSString*)message
              withInputInfo:(InputValueInfo)inputInfo
{
  event->SetType(PERIPHERAL_EVENT_TYPE_DRIVER_BUTTON);

  switch (inputInfo.controllerType)
  {
    case GCCONTROLLER_TYPE::EXTENDED:
      event->SetDriverIndex(static_cast<unsigned int>(inputInfo.extendedButton));
      break;
    case GCCONTROLLER_TYPE::MICRO:
      event->SetDriverIndex(static_cast<unsigned int>(inputInfo.microButton));
      break;
    case GCCONTROLLER_TYPE::UNKNOWN:
    case GCCONTROLLER_TYPE::NOTFOUND:
    case GCCONTROLLER_TYPE::UNUSED:
      return [message
          stringByAppendingFormat:@" ERROR:: CONTROLLER_TYPE %d", inputInfo.controllerType];
      break;
  }

  if (button.isPressed)
  {
    event->SetButtonState(JOYSTICK_STATE_BUTTON_PRESSED);
    return [message stringByAppendingString:@" Pressed"];
  }
  else
  {
    event->SetButtonState(JOYSTICK_STATE_BUTTON_UNPRESSED);
    return [message stringByAppendingString:@" Released"];
  }
}

- (NSString*)setAxisValue:(GCControllerAxisInput*)axisValue
                withEvent:(kodi::addon::PeripheralEvent*)event
              withMessage:(NSString*)message
            withInputInfo:(InputValueInfo)inputInfo
{
  event->SetType(PERIPHERAL_EVENT_TYPE_DRIVER_AXIS);
  event->SetDriverIndex(static_cast<unsigned int>(inputInfo.extendedAxis));
  event->SetAxisState(axisValue.value);
  return message;
}

- (PERIPHERALS::PeripheralScanResults)GetGCDevices
{

  PERIPHERALS::PeripheralScanResults scanresults;

  if ([controllerArray count] == 0)
    return scanresults;

  for (GCController* controller in controllerArray)
  {
    PERIPHERALS::PeripheralScanResult peripheralScanResult;
    peripheralScanResult.m_type = PERIPHERALS::PERIPHERAL_JOYSTICK;
    peripheralScanResult.m_strLocation =
        [cbmanager GetDeviceLocation:static_cast<int>(controller.playerIndex)];
    peripheralScanResult.m_iVendorId = 0;
    peripheralScanResult.m_iProductId = 0;
    peripheralScanResult.m_mappedType = PERIPHERALS::PERIPHERAL_JOYSTICK;

    if (controller.extendedGamepad)
    {
      peripheralScanResult.m_strDeviceName = "Extended Gamepad";
    }
    else if (controller.microGamepad)
    {
      peripheralScanResult.m_strDeviceName = "Micro Gamepad";
    }

    peripheralScanResult.m_busType = PERIPHERALS::PERIPHERAL_BUS_DARWINEMBEDDED;
    peripheralScanResult.m_mappedBusType = PERIPHERALS::PERIPHERAL_BUS_DARWINEMBEDDED;
    peripheralScanResult.m_iSequence = 0;
    scanresults.m_results.push_back(peripheralScanResult);
  }

  return scanresults;
}

- (GCCONTROLLER_TYPE)GetGCControllerType:(int)deviceID
{
  for (GCController* controller in controllerArray)
  {
    if (controller.playerIndex == deviceID)
    {
      if (controller.extendedGamepad != nil)
        return GCCONTROLLER_TYPE::EXTENDED;
      else if (controller.microGamepad != nil)
        return GCCONTROLLER_TYPE::MICRO;
    }
  }
  return GCCONTROLLER_TYPE::NOTFOUND;
}

- (instancetype)initWithName:(CBPeripheralBusDarwinEmbeddedManager*)callbackManager
//- (instancetype)init
{
  self = [super init];
  if (!self)
    return nil;

  cbmanager = callbackManager;

  [self addModeSwitchObserver];

  controllerArray = [[NSMutableArray alloc] init];

  auto controllers = [GCController controllers];
  // Iterate through any pre-existing controller connections at startup to enable value handlers
  if ([controllers count] > 0)
  {
    for (GCController* controller in controllers)
    {
      [self controllerConnection:controller];
    }
  }

  return self;
}

@end
