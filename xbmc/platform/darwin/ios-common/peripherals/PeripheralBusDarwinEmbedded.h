/*
 *  Copyright (C) 2020 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#pragma once

#include "addons/kodi-addon-dev-kit/include/kodi/addon-instance/PeripheralUtils.h"
#include "peripherals/PeripheralTypes.h"
#include "peripherals/bus/PeripheralBus.h"
#include "threads/CriticalSection.h"
#include "threads/SingleLock.h"

#include <memory>
#include <string>
#include <utility>
#include <vector>

struct PeripheralBusDarwinEmbeddedWrapper;

namespace PERIPHERALS
{
class CPeripheralBusDarwinEmbedded : public CPeripheralBus
{
public:
  explicit CPeripheralBusDarwinEmbedded(CPeripherals& manager);
  ~CPeripheralBusDarwinEmbedded() override;

  // specialisation of CPeripheralBus
  bool InitializeProperties(CPeripheral& peripheral) override;
  void Initialise(void) override;
  void ProcessEvents() override;

  bool PerformDeviceScan(PeripheralScanResults& results) override;
  PeripheralScanResults GetInputDevices();

  void callOnDeviceAdded(const std::string strLocation);
  void callOnDeviceRemoved(const std::string strLocation);

  void SetScanResults(const PeripheralScanResults resScanResults);

private:
  void GetEvents(std::vector<kodi::addon::PeripheralEvent>& events);
  PeripheralBusDarwinEmbeddedWrapper* m_peripheralDarwinEmbedded;
  std::string GetDeviceLocation(int deviceId);
  bool GetDeviceId(const std::string& deviceLocation, int& deviceId);

  PeripheralScanResults m_scanResults;
  CCriticalSection m_critSectionStates;
  CCriticalSection m_critSectionResults;
};
using PeripheralBusDarwinEmbeddedPtr = std::shared_ptr<CPeripheralBusDarwinEmbedded>;
} // namespace PERIPHERALS
