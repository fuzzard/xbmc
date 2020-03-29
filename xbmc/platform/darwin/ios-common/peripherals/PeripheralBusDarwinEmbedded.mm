
#include "PeripheralBusDarwinEmbedded.h"

#include "addons/kodi-addon-dev-kit/include/kodi/addon-instance/PeripheralUtils.h"
#include "input/XBMC_keysym.h"
#include "peripherals/Peripherals.h"
#include "peripherals/PeripheralTypes.h"
#include "peripherals/bus/PeripheralBus.h"
#include "peripherals/devices/PeripheralJoystick.h"
#include "threads/SingleLock.h"
#include "utils/log.h"

#import <Foundation/Foundation.h>
#import <GameController/GCController.h>

//using namespace PERIPHERALS;

#pragma mark - objc interface

@interface CBPeripheralBusDarwinEmbedded : NSObject
{
  NSMutableArray* controllerArray;
  std::vector<kodi::addon::PeripheralEvent> m_digitalEvents;
}
- (PERIPHERALS::PeripheralScanResults)GetInputDevices;
- (void)removeModeSwitchObserver;
- (void)addModeSwitchObserver;
- (void)controllerWasConnected:(NSNotification*)notification;
- (void)controllerWasDisconnected:(NSNotification*)notification;
- (void)processEvents;
- (void)registerChangeHandler:(GCController*)controller;
- (void)displayMessage:(NSString*)message;
@end

#define JOYSTICK_PROVIDER_DARWINEMBEDDED  "darwinembedded"

struct PeripheralBusDarwinEmbeddedWrapper
{
  CBPeripheralBusDarwinEmbedded* callbackClass;
};

PERIPHERALS::CPeripheralBusDarwinEmbedded::CPeripheralBusDarwinEmbedded(CPeripherals& manager) :
    CPeripheralBus("PeripBusDarwinEmbedded", manager, PERIPHERAL_BUS_DARWINEMBEDDED)
{
  m_peripheralDarwinEmbedded = new PeripheralBusDarwinEmbeddedWrapper;
  m_peripheralDarwinEmbedded->callbackClass = [[CBPeripheralBusDarwinEmbedded alloc] init];
  m_bNeedsPolling = false;
  
  // get all currently connected input devices
  m_scanResults = GetInputDevices();
}

PERIPHERALS::CPeripheralBusDarwinEmbedded::~CPeripheralBusDarwinEmbedded()
{
  m_peripheralDarwinEmbedded->callbackClass = nil;
  delete m_peripheralDarwinEmbedded;
}

bool PERIPHERALS::CPeripheralBusDarwinEmbedded::InitializeProperties(CPeripheral& peripheral)
{

  // Returns true regardless, why is it necessary?
//  if (!CPeripheralBus::InitializeProperties(peripheral))
//    return false;

  if (peripheral.Type() != PERIPHERALS::PERIPHERAL_JOYSTICK)
  {
    CLog::Log(LOGWARNING, "CPeripheralBusDarwinEmbedded: invalid peripheral type: %s",
        PERIPHERALS::PeripheralTypeTranslator::TypeToString(peripheral.Type()));
    return false;
  }
  
  // need to map to a specific gamecontroller - strLocation = playerIndex
  CLog::Log(LOGDEBUG, "CPeripheralBusDarwinEmbedded: Initializing device \"%s\"", peripheral.DeviceName().c_str());
  
  CPeripheralJoystick& joystick = static_cast<CPeripheralJoystick&>(peripheral);
//  if (device.getControllerNumber() > 0)
//     joystick.SetRequestedPort(device.getControllerNumber() - 1);
  joystick.SetRequestedPort(0);
  joystick.SetProvider(JOYSTICK_PROVIDER_DARWINEMBEDDED);

  // fill in the number of buttons, hats and axes
  joystick.SetButtonCount(14); // 14 extended, 6 micro - check gamepad type, set button count to extended or micro
  joystick.SetAxisCount(2); // 2 for extended, 0 for micro
  
  CLog::Log(LOGDEBUG, "CPeripheralBusDarwinEmbedded: Device has %u buttons and %u axes",
            joystick.ButtonCount(), joystick.AxisCount());
/*
  int deviceId;
  if (!GetDeviceId(peripheral.Location(), deviceId))
  {
    CLog::Log(LOGWARNING, "CPeripheralBusDarwinEmbedded: failed to initialize properties for peripheral \"%s\"", peripheral.Location().c_str());
    return false;
  }


*/
  return true;
}

void PERIPHERALS::CPeripheralBusDarwinEmbedded::Initialise(void)
{
  CPeripheralBus::Initialise();
  TriggerDeviceScan();
}

bool PERIPHERALS::CPeripheralBusDarwinEmbedded::PerformDeviceScan(PeripheralScanResults& results)
{
  CSingleLock lock(m_critSectionResults);
  results = m_scanResults;

  return true;
}

void PERIPHERALS::CPeripheralBusDarwinEmbedded::ProcessEvents()
{
  //[m_peripheralDarwinEmbedded->callbackClass processEvents];
}

bool PERIPHERALS::CPeripheralBusDarwinEmbedded::setPeripheralScanResult(const void* inputDevice,
                                                                 PeripheralScanResult& peripheralScanResult)
{
  return true;
}

PERIPHERALS::PeripheralScanResults PERIPHERALS::CPeripheralBusDarwinEmbedded::GetInputDevices()
{
  CLog::Log(LOGINFO, "CPeripheralBusDarwinEmbedded: scanning for input devices...");

  return [m_peripheralDarwinEmbedded->callbackClass GetInputDevices];
}

void callOnDeviceAdded(const std::string strLocation)
{
//  OnDeviceAdded(strLocation);

}

void callOnDeviceRemoved(const std::string strLocation)
{
//  OnDeviceRemoved(strLocation);

}

#pragma mark - objc implementation

@implementation CBPeripheralBusDarwinEmbedded

- (bool)InitializeProperties:(PERIPHERALS::CPeripheral*)peripheral
{

}

- (PERIPHERALS::PeripheralScanResults)GetInputDevices
{
  PERIPHERALS::PeripheralScanResults scanresults;
  for (GCController* controller in [GCController controllers])
  {
    PERIPHERALS::PeripheralScanResult peripheralScanResult;
    peripheralScanResult.m_type = PERIPHERALS::PERIPHERAL_JOYSTICK;
    peripheralScanResult.m_strLocation = (unsigned long)controller.playerIndex;
    peripheralScanResult.m_iVendorId = 0;//[controller.vendorName UTF8String];
    peripheralScanResult.m_iProductId = 0;//[controller.vendorName UTF8String];
    peripheralScanResult.m_mappedType = PERIPHERALS::PERIPHERAL_JOYSTICK;
    peripheralScanResult.m_strDeviceName = std::string([controller.vendorName UTF8String]) + std::string("playerid") + std::to_string((unsigned long)controller.playerIndex);
    peripheralScanResult.m_busType = PERIPHERALS::PERIPHERAL_BUS_DARWINEMBEDDED;
    peripheralScanResult.m_mappedBusType = PERIPHERALS::PERIPHERAL_BUS_DARWINEMBEDDED;
    peripheralScanResult.m_iSequence = 0;
    scanresults.m_results.push_back(peripheralScanResult);
  }
  
  return scanresults;
}

- (void)dealloc
{
  [self removeModeSwitchObserver];
}

- (instancetype)init
{
  [self addModeSwitchObserver];
  
  return self;
}

#pragma mark - Notificaton Observer

- (void)removeModeSwitchObserver
{
  [[NSNotificationCenter defaultCenter]removeObserver:self
                                                 name:GCControllerDidConnectNotification
                                               object:nil];
  [[NSNotificationCenter defaultCenter]removeObserver:self
                                                 name:GCControllerDidDisconnectNotification
                                               object:nil];
}

- (void)addModeSwitchObserver
{
  // notifications for controller (dis)connect 
  [[NSNotificationCenter defaultCenter]addObserver:self
                                          selector:@selector(controllerWasConnected:)
                                              name:GCControllerDidConnectNotification
                                            object:nil];
  [[NSNotificationCenter defaultCenter]addObserver:self
                                          selector:@selector(controllerWasDisconnected:)
                                              name:GCControllerDidDisconnectNotification
                                            object:nil];
}

- (void)controllerWasConnected:(NSNotification*)notification
{
  GCController* controller = (GCController*)notification.object;
  {
//    CSingleLock lock(m_critSectionResults);
    // add the device to the cached result list
    for (id controlObj in controllerArray)
    {
      if ([controlObj isEqual:controller])
      {
        CLog::Log(LOGINFO, "CPeripheralBusDarwinEmbedded: ignoring added input device with ID {} because we already know it", [controller.vendorName UTF8String]);
        return;
      }
    }

/*    switch ([[GCController controllers] count])
    {
      case 1:
        controller.playerIndex = GCControllerPlayerIndex1;
        break;
      case 2:
        controller.playerIndex = GCControllerPlayerIndex2;
        break;
      case 3:
        controller.playerIndex = GCControllerPlayerIndex3;
        break;
      case 4:
        controller.playerIndex = GCControllerPlayerIndex4;
     }
 */
  
    CLog::Log(LOGDEBUG, "CPeripheralBusDarwinEmbedded: input device with ID {} playerIndex {} added ",
                                   [controller.vendorName UTF8String], (unsigned long)controller.playerIndex);
    [controllerArray addObject:controller];
  }

  const std::string deviceLocation = std::to_string((unsigned long)controller.playerIndex);
  callOnDeviceAdded(deviceLocation);
  //[self registerChangeHandler:controller];
}

- (void)controllerWasDisconnected:(NSNotification*)notification
{
  // controllerArray;
  // a controller was disconnected
  GCController* controller = (GCController*)notification.object;
  bool removed = false;
  {
//    CSingleLock lock(m_critSectionResults);
    // remove the device from the Controller Array
    for (id controlObj in controllerArray)
    {
      if ([controlObj isEqual:controller])
      {
        CLog::Log(LOGINFO, "CPeripheralBusDarwinEmbedded: input device \"{}\" removed", [controller.vendorName UTF8String]);
        controller.playerIndex = GCControllerPlayerIndexUnset;
        [controllerArray removeObject:controller];
        removed = true;
        break;
      }
    }
  }

  if (removed)
  {
    const std::string deviceLocation = std::to_string((unsigned long)controller.playerIndex);
    callOnDeviceRemoved(deviceLocation);
  }
  else
    CLog::Log(LOGWARNING, "CPeripheralBusDarwinEmbedded: failed to remove input device {} because it couldn't be found", [controller.vendorName UTF8String]);
}

- (void)processEvents
{

}

- (void)registerChangeHandler:(GCController*)controller
{
  if (controller.extendedGamepad != nil)
  {
    // register block for input change detection
    GCExtendedGamepad *profile = controller.extendedGamepad;
    profile.valueChangedHandler = ^(GCExtendedGamepad *gamepad, GCControllerElement *element)
    {
        NSString *message = @"";
        CGPoint position = CGPointMake(0, 0);
        
        // left trigger
        if (gamepad.leftTrigger == element && gamepad.leftTrigger.isPressed) {
            message = @"Left Trigger";
        }
        
        // right trigger
        if (gamepad.rightTrigger == element && gamepad.rightTrigger.isPressed) {
            message = @"Right Trigger";
        }
        
        // left shoulder button
        if (gamepad.leftShoulder == element && gamepad.leftShoulder.isPressed) {
            message = @"Left Shoulder Button";
        }
        
        // right shoulder button
        if (gamepad.rightShoulder == element && gamepad.rightShoulder.isPressed) {
            message = @"Right Shoulder Button";
        }
        
        // A button
        if (gamepad.buttonA == element && gamepad.buttonA.isPressed) {
            message = @"A Button";
        }
        
        // B button
        if (gamepad.buttonB == element && gamepad.buttonB.isPressed) {
            message = @"B Button";
        }
        
        // X button
        if (gamepad.buttonX == element && gamepad.buttonX.isPressed) {
            message = @"X Button";
        }
        
        // Y button
        if (gamepad.buttonY == element && gamepad.buttonY.isPressed) {
            message = @"Y Button";
        }
        
        // d-pad
        if (gamepad.dpad == element) {
            if (gamepad.dpad.up.isPressed) {
                message = @"D-Pad Up";
            }
            if (gamepad.dpad.down.isPressed) {
                message = @"D-Pad Down";
            }
            if (gamepad.dpad.left.isPressed) {
                message = @"D-Pad Left";
            }
            if (gamepad.dpad.right.isPressed) {
                message = @"D-Pad Right";
            }
        }
        
        // left stick
        if (gamepad.leftThumbstick == element) {
            if (gamepad.leftThumbstick.up.isPressed) {
                message = [NSString stringWithFormat:@"Left Stick %f", gamepad.leftThumbstick.yAxis.value];
            }
            if (gamepad.leftThumbstick.down.isPressed) {
                message = [NSString stringWithFormat:@"Left Stick %f", gamepad.leftThumbstick.yAxis.value];
            }
            if (gamepad.leftThumbstick.left.isPressed) {
                message = [NSString stringWithFormat:@"Left Stick %f", gamepad.leftThumbstick.xAxis.value];
            }
            if (gamepad.leftThumbstick.right.isPressed) {
                message = [NSString stringWithFormat:@"Left Stick %f", gamepad.leftThumbstick.xAxis.value];
            }
            position = CGPointMake(gamepad.leftThumbstick.xAxis.value, gamepad.leftThumbstick.yAxis.value);
        }
        
        // right stick
        if (gamepad.rightThumbstick == element) {
            if (gamepad.rightThumbstick.up.isPressed) {
                message = [NSString stringWithFormat:@"Right Stick %f", gamepad.rightThumbstick.yAxis.value];
            }
            if (gamepad.rightThumbstick.down.isPressed) {
                message = [NSString stringWithFormat:@"Right Stick %f", gamepad.rightThumbstick.yAxis.value];
            }
            if (gamepad.rightThumbstick.left.isPressed) {
                message = [NSString stringWithFormat:@"Right Stick %f", gamepad.rightThumbstick.xAxis.value];
            }
            if (gamepad.rightThumbstick.right.isPressed) {
                message = [NSString stringWithFormat:@"Right Stick %f", gamepad.rightThumbstick.xAxis.value];
            }
            position = CGPointMake(gamepad.rightThumbstick.xAxis.value, gamepad.rightThumbstick.yAxis.value);
        }

        [self displayMessage:message];
    };
  }
  else if (controller.microGamepad != nil)
  {
    CLog::Log(LOGDEBUG, "CBPeripheralBusDarwinEmbedded: microGamepad not supported currently");
  }
    
}

- (void)displayMessage:(NSString*)message
{    
  CLog::Log(LOGDEBUG, "CBPeripheralBusDarwinEmbedded: inputhandler - {}", [message UTF8String]);
}

@end
