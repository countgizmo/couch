package main

import "core:fmt"
import "core:strings"
import "base:intrinsics"
import "base:runtime"
import ns "core:sys/darwin/Foundation"

foreign import cf "system:CoreFoundation.framework"
@(require) foreign import "system:CoreBluetooth.framework"

msgSend :: intrinsics.objc_send

Data_bytes :: proc "c" (self: ^ns.Data) -> rawptr {
  return msgSend(rawptr, self, "bytes")
}

@(objc_class="CBPeer")
CBPeer:: struct { using _: ns.Object }

@(objc_type=CBPeer, objc_name="identifier")
CBPeer_identifier :: proc "c" (self: ^CBPeer) -> ^CBUUID {
  return msgSend(^CBUUID, self, "identifier")
}

@(objc_class="CBAttribute")
CBAttribute :: struct { using _: ns.Object }

@(objc_type=CBAttribute, objc_name="UUID")
CBAttribute_UUID :: proc "c" (self: ^CBAttribute) -> ^CBUUID {
  return msgSend(^CBUUID, self, "UUID")
}



// ---------------------------------------------------------------------------
// CBCentralManager

@(objc_class="CBCentralManager")
CBCentralManager :: struct { using _: ns.Object }

@(objc_type=CBCentralManager, objc_name="initWithDelegateQueue")
CBCentralManager_initWithDelegateQueue :: proc "c" (self: ^CBCentralManager, delegate: ns.id, queue: rawptr) -> ^CBCentralManager {
  return msgSend(^CBCentralManager, self, "initWithDelegate:queue:", delegate, queue)
}

@(objc_type=CBCentralManager, objc_name="state")
CBCentralManager_state :: proc "c" (self: ^CBCentralManager) -> CBManagerState {
  return msgSend(CBManagerState, self, "state")
}

CBManagerState :: enum ns.Integer {
  Unknown = 0,
  Resetting = 1,
  Unsupported = 2,
  Unauthorized = 3,
  PoweredOff = 4,
  PoweredOn = 5
}


@(objc_type=CBCentralManager, objc_name="stopScan")
CBCentralManager_stopScan :: proc "c" (self: ^CBCentralManager) {
  msgSend(nil, self, "stopScan")
}

@(objc_type=CBCentralManager, objc_name="scanForPeripheralsWithServices")
CBCentralManager_scanForPeripheralsWithServices :: proc "c" (self: ^CBCentralManager, services: rawptr, options: rawptr) {
  msgSend(nil, self, "scanForPeripheralsWithServices:options:", services, options)
}

@(objc_type=CBCentralManager, objc_name="connectPeripheral")
CBCentralManager_connectPeripheral :: proc "c" (self: ^CBCentralManager, peripheral: ^CBPeripheral, options: rawptr) {
  msgSend(nil, self, "connectPeripheral:options:", peripheral, options)
}


// ---------------------------------------------------------------------------
// CBPeripheral

@(objc_class="CBPeripheral")
CBPeripheral :: struct { using _: CBPeer }

@(objc_type=CBPeripheral, objc_name="name")
CBPeripheral_name :: proc "c" (self: ^CBPeripheral) -> ^ns.String {
  return msgSend(^ns.String, self, "name")
}

@(objc_type=CBPeripheral, objc_name="setDelegate")
CBPeripheral_setDelegate :: proc "c" (self: ^CBPeripheral, delegate: ns.id) {
  msgSend(nil, self, "setDelegate:", delegate)
}

@(objc_type=CBPeripheral, objc_name="discoverServices")
CBPeripheral_discoverServices :: proc "c" (self: ^CBPeripheral, services: ^ns.Array) {
  msgSend(nil, self, "discoverServices:", services)
}

@(objc_type=CBPeripheral, objc_name="services")
CBPeripheral_services :: proc "c" (self: ^CBPeripheral) -> ^ns.Array {
  return msgSend(^ns.Array, self, "services")
}

@(objc_type=CBPeripheral, objc_name="discoverCharacteristicsforService")
CBPeripheral_discoverCharacteristicsforService :: proc "c" (self: ^CBPeripheral, characteristics: ^ns.Array, service: ^CBService) {
  msgSend(nil, self, "discoverCharacteristics:forService:", characteristics, service)
}

@(objc_type=CBPeripheral, objc_name="readValueForCharacteristic")
CBPeripheral_readValueForCharacteristic :: proc "c" (self: ^CBPeripheral, characteristic: ^CBCharacteristic) {
  msgSend(nil, self, "readValueForCharacteristic:", characteristic)
}

@(objc_type=CBPeripheral, objc_name="setNotifyValue")
CBPeripheral_setNotifyValue :: proc "c" (self: ^CBPeripheral, enabled: ns.BOOL,  characteristic: ^CBCharacteristic) {
  msgSend(nil, self, "setNotifyValue:forCharacteristic:", enabled, characteristic)
}


// ---------------------------------------------------------------------------
// CBService

@(objc_class="CBService")
CBService :: struct { using _: CBAttribute }

@(objc_type=CBService, objc_name="characteristics")
CBService_characteristics :: proc "c" (self: ^CBService) -> ^ns.Array {
  return msgSend(^ns.Array, self, "characteristics")
}


// ---------------------------------------------------------------------------
// CBCharacteristic

@(objc_class="CBCharacteristic")
CBCharacteristic :: struct { using _: ns.Object}

@(objc_type=CBCharacteristic, objc_name="value")
CBCharacteristic_value :: proc "c" (self: ^CBCharacteristic) -> ^ns.Data {
  return msgSend(^ns.Data, self, "value")
}


// ---------------------------------------------------------------------------
// CBUUID

@(objc_class="CBUUID")
CBUUID :: struct { using _: ns.Object }

@(objc_type=CBUUID, objc_name="UUIDString")
CBUUID_UUIDString :: proc "c" (self: ^CBUUID) -> ^ns.String {
  return msgSend(^ns.String, self, "UUIDString")
}

@(objc_type=CBUUID, objc_name="UUIDWithString", objc_is_class_method=true)
CBUUID_UUIDWithString :: proc "c" (s: ^ns.String) -> ^CBUUID {
  return msgSend(^CBUUID, CBUUID, "UUIDWithString:", s)
}

@(objc_type=CBUUID, objc_name="UUIDWithData", objc_is_class_method=true)
CBUUID_UUIDWithData :: proc "c" (d: ^ns.Data) -> ^CBUUID {
  return msgSend(^CBUUID, CBUUID, "UUIDWithData:", d)
}



// Delegate Callbacks

on_state_change :: proc "c" (self: ns.id, cmd: ns.SEL, central: ns.id) {
  context = runtime.default_context()
  mgr := cast(^CBCentralManager)central
  state := mgr->state()

  fmt.println("state =", mgr->state())

  if mgr->state() == .PoweredOn {
    mgr->scanForPeripheralsWithServices(nil, nil)
  }
}

on_peripheral_discover :: proc "c" (self: ns.id, cmd: ns.SEL, central: ns.id, peripheral: ns.id, advData: ns.id, rssi: ns.id) {
  context = runtime.default_context()
  mgr := cast(^CBCentralManager)central
  per := cast(^CBPeripheral) peripheral
  per_name := per->name()

  if per_name != nil {
    per_name_str := per_name->odinString()
    per_name_uuid := per->identifier()->UUIDString()

    if whoop == nil && strings.equal_fold(per_name_str, "GIZMOWHOOP 5") {
      whoop = per
      whoop->retain()
      mgr->stopScan()
    }
  }
}

on_connect :: proc "c" (self: ns.id, cmd: ns.SEL, central: ns.id, peripheral: ns.id) {
  context = runtime.default_context()
  mgr := cast(^CBCentralManager)central
  per := cast(^CBPeripheral) peripheral
  per_name := per->name()
  fmt.println(">>> CONNECTED TO: ", per_name->odinString())
  per->setDelegate(self)


  // Looking for HR service

  hr_data := ns.Data_alloc()->initWithBytes([]byte{0x18, 0x0d})
  heart_rate_uuid := CBUUID_UUIDWithData(hr_data)
  hr_data->release()

  uuids := []^ns.Object{ cast(^ns.Object) heart_rate_uuid }
  services := ns.Array_alloc()->initWithObjects(raw_data(uuids), ns.UInteger(len(uuids)))
  per->discoverServices(services)
  services->release()
}

on_disconnect :: proc "c" (self: ns.id, cmd: ns.SEL, central: ns.id, peripheral: ns.id, error: ns.id) {
  context = runtime.default_context()
  mgr := cast(^CBCentralManager)central
  per := cast(^CBPeripheral) peripheral

  if error == nil {
    fmt.println("disconnected cleanly (no error)")
    return
  }
  err := cast(^ns.Error) error
  fmt.println("disconnect error:", err->localizedDescription()->odinString(), "code:", err->code())

  mgr->connectPeripheral(whoop, nil)
}

on_peripheral_services_discover :: proc "c" (self: ns.id, cmd: ns.SEL, peripheral: ns.id, error: rawptr) {
  context = runtime.default_context()
  per := cast(^CBPeripheral) peripheral

  per_services := per->services()
  services_count := per_services->count()

  // We asked for one service, sowe we get the first one
  service := per_services->objectAs(0, ^CBService)

  fmt.println("Heart Rate Service discovered = ", service->UUID()->UUIDString()->odinString())


  //Heart Rate Measurement - 0x2A37
  hr_measure := ns.Data_alloc()->initWithBytes([]byte{0x2A, 0x37})
  hr_measure_uuid := CBUUID_UUIDWithData(hr_measure)
  hr_measure->release()
  uuids := []^ns.Object{ cast(^ns.Object) hr_measure_uuid}
  characteristics := ns.Array_alloc()->initWithObjects(raw_data(uuids), ns.UInteger(len(uuids)))

  per->discoverCharacteristicsforService(characteristics, service)
}

on_characteristics_discover :: proc "c" (self: ns.id, cmd: ns.SEL, peripheral: ns.id, service: ns.id, error: rawptr) {
  context = runtime.default_context()
  per := cast(^CBPeripheral) peripheral
  the_service := cast(^CBService) service

  characteristics := the_service->characteristics()
  hr_characteristic := characteristics->objectAs(0, ^CBCharacteristic)

  per->setNotifyValue(true, hr_characteristic)
}

on_hr_value_update :: proc "c" (self: ns.id, cmd: ns.SEL, peripheral: ns.id, characteristic: ns.id, error: rawptr) {
  context = runtime.default_context()
  per := cast(^CBPeripheral) peripheral
  hr_characteristic := cast(^CBCharacteristic) characteristic

  hr_data := hr_characteristic->value()
  hr_data_len := hr_data->length()
  hr_data_buf := (cast([^]u8) Data_bytes(hr_data))[:int(hr_data_len)]
  heart_rate = hr_data_buf[1]


  fmt.println("HR Data =", hr_data_buf, "HR = ", hr_data_buf[1])
}

// I don't have neverending loop here, so... this!

CFStringRef :: distinct rawptr

@(default_calling_convention="c")
foreign cf {
  CFRunLoopRunInMode :: proc(mode: CFStringRef, seconds: f64, return_after_source_handled: bool) -> i32 ---
  kCFRunLoopDefaultMode: CFStringRef
}

whoop: ^CBPeripheral
heart_rate: u8

gizmowhoop :: "8B8083C3-6488-C38B-B486-BE0706A13D44"

init_whoop_reading :: proc() -> ^CBCentralManager {
  my_central_manager := ns.alloc(CBCentralManager)
  fmt.println("================== Starting Bluetooth Probe ====================================")

  // Delegate Class
  NSObject := ns.objc_lookUpClass("NSObject")
  cls := ns.objc_allocateClassPair(NSObject, "MyCBDelegate", 0)

  // Delegate Methods
  sel := ns.sel_registerName("centralManagerDidUpdateState:")
  if !ns.class_addMethod(cls, sel, auto_cast on_state_change, "v@:@") {
    fmt.println("ERROR: failed to register state change callback")
  }

  sel = ns.sel_registerName("centralManager:didDiscoverPeripheral:advertisementData:RSSI:")
  if !ns.class_addMethod(cls, sel, auto_cast on_peripheral_discover, "v@:@@@@") {
    fmt.println("ERROR: failed to register peripheral discover callback")
  }

  sel = ns.sel_registerName("centralManager:didConnectPeripheral:")
  if !ns.class_addMethod(cls, sel, auto_cast on_connect, "v@:@@") {
    fmt.println("ERROR: failed to register connect callback")
  }

  sel = ns.sel_registerName("centralManager:didDisconnectPeripheral:error:")
  if !ns.class_addMethod(cls, sel, auto_cast on_disconnect, "v@:@@@") {
    fmt.println("ERROR: failed to register disconnect callback")
  }

  sel = ns.sel_registerName("peripheral:didDiscoverServices:")
  if !ns.class_addMethod(cls, sel, auto_cast on_peripheral_services_discover, "v@:@@") {
    fmt.println("ERROR: failed to register peripheral services discover callback")
  }

  sel = ns.sel_registerName("peripheral:didDiscoverCharacteristicsForService:error:")
  if !ns.class_addMethod(cls, sel, auto_cast on_characteristics_discover, "v@:@@@") {
    fmt.println("ERROR: failed to register characteristics discover callback")
  }

  sel = ns.sel_registerName("peripheral:didUpdateValueForCharacteristic:error:")
  if !ns.class_addMethod(cls, sel, auto_cast on_hr_value_update, "v@:@@@") {
    fmt.println("ERROR: failed to register hr value update callback")
  }

  // Create instance
  ns.objc_registerClassPair(cls)
  inst := ns.class_createInstance(cls, 0)

  my_central_manager = my_central_manager->initWithDelegateQueue(inst, nil)

  return my_central_manager
}
