/*
 *  Copyright (C) 2020 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#pragma once

#include "peripherals/PeripheralTypes.h"
#include "peripherals/bus/PeripheralBus.h"
#include "threads/CriticalSection.h"

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
  
  bool PerformDeviceScan(PeripheralScanResults &results) override;
  PeripheralScanResults GetInputDevices();

private:

  bool setPeripheralScanResult(const void* inputDevice, PeripheralScanResult& peripheralScanResult);

  PeripheralBusDarwinEmbeddedWrapper* m_peripheralDarwinEmbedded;

  PeripheralScanResults m_scanResults;
  CCriticalSection m_critSectionStates;
  CCriticalSection m_critSectionResults;

};
using PeripheralBusDarwinEmbeddedPtr = std::shared_ptr<CPeripheralBusDarwinEmbedded>;
}
