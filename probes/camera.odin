package probecamera

import "core:fmt"
import "base:intrinsics"
import "base:runtime"
import ns "core:sys/darwin/Foundation"

@(require) foreign import av "system:AVFoundation.framework"
foreign av { AVMediaTypeVideo: ^ns.String }

foreign import dispatch "system:System.framework"
@(default_calling_convention="c")
foreign dispatch {
  dispatch_queue_create :: proc(label: cstring, attr: rawptr) -> rawptr ---
}

foreign import media "system:CoreMedia.framework"
@(default_calling_convention="c")
foreign media {
  CMSampleBufferGetImageBuffer :: proc(sample_buffer: rawptr) -> rawptr ---
  kCVPixelBufferPixelFormatTypeKey : ^ns.String
}

foreign import video "system:CoreVideo.framework"

@(default_calling_convention="c")
foreign video {
  CVPixelBufferGetWidth :: proc(pixel_buffer: rawptr) -> uint ---
  CVPixelBufferGetHeight :: proc(pixel_buffer: rawptr) -> uint ---
  CVPixelBufferGetPlaneCount :: proc(pixel_buffer: rawptr) -> uint ---
  CVPixelBufferLockBaseAddress :: proc(pixel_buffer: rawptr, flags: u64) -> i32 ---
  CVPixelBufferUnlockBaseAddress :: proc(pixel_buffer: rawptr, flags: u64) -> i32 ---
  CVPixelBufferGetBaseAddressOfPlane :: proc(pixel_buffer: rawptr, plane: i32) -> rawptr ---
  CVPixelBufferGetBytesPerRowOfPlane :: proc(pixel_buffer: rawptr, plane: i32) -> uint ---
}

// for the neverending loop
foreign import cf "system:CoreFoundation.framework"

CFStringRef :: distinct rawptr

@(default_calling_convention="c")
foreign cf {
  CFRunLoopRunInMode :: proc(mode: CFStringRef, seconds: f64, return_after_source_handled: bool) -> i32 ---
  kCFRunLoopDefaultMode: CFStringRef
}


msgSend :: intrinsics.objc_send

//
// AVCaptureSession
//

@(objc_class="AVCaptureSession")
AVCaptureSession :: struct { using _: ns.Object }

@(objc_type=AVCaptureSession, objc_name="startRunning")
AVCaptureSession_startRunning :: proc "c" (self: ^AVCaptureSession) {
  msgSend(nil, self, "startRunning")
}

@(objc_type=AVCaptureSession, objc_name="isRunning")
AVCaptureSession_running :: proc "c" (self: ^AVCaptureSession) -> ns.BOOL {
  return msgSend(ns.BOOL, self, "isRunning")
}

@(objc_type=AVCaptureSession, objc_name="init")
AVCaptureSession_init :: proc "c" (self: ^AVCaptureSession) -> ^AVCaptureSession {
  return msgSend(^AVCaptureSession, self, "init")
}

@(objc_type=AVCaptureSession, objc_name="canAddInput")
AVCaptureSession_canAddInput :: proc "c" (self: ^AVCaptureSession, input: ^AVCaptureDeviceInput) -> ns.BOOL {
  return msgSend(ns.BOOL, self, "canAddInput:", input)
}

@(objc_type=AVCaptureSession, objc_name="addInput")
AVCaptureSession_addInput :: proc "c" (self: ^AVCaptureSession, input: ^AVCaptureDeviceInput) {
  msgSend(nil, self, "addInput:", input)
}

@(objc_type=AVCaptureSession, objc_name="canAddOutput")
AVCaptureSession_canAddOutput :: proc "c" (self: ^AVCaptureSession, output: ^AVCaptureVideoDataOutput) -> ns.BOOL {
  return msgSend(ns.BOOL, self, "canAddOutput:", output)
}

@(objc_type=AVCaptureSession, objc_name="addOutput")
AVCaptureSession_addOutput :: proc "c" (self: ^AVCaptureSession, output: ^AVCaptureVideoDataOutput) {
  msgSend(nil, self, "addOutput:", output)
}


//
// AVCaptureDevice
//

@(objc_class="AVCaptureDevice")
AVCaptureDevice :: struct { using _: ns.Object }

@(objc_type=AVCaptureDevice, objc_name="authorizationStatusForMediaType", objc_is_class_method=true)
AVCaptureDevice_authorizationStatusForMediaType :: proc "c" (media_type: ^ns.String) -> AVAuthStatus {
  return msgSend(AVAuthStatus, AVCaptureDevice, "authorizationStatusForMediaType:", media_type)
}

@(objc_type=AVCaptureDevice, objc_name="defaultDeviceWithMediaType", objc_is_class_method=true)
AVCaptureDevice_defaultDeviceWithMediaType :: proc "c" (media_type: ^ns.String) -> ^AVCaptureDevice {
  return msgSend(^AVCaptureDevice, AVCaptureDevice, "defaultDeviceWithMediaType:", media_type)
}

AVAuthStatus :: enum int { NotDetermined, Restricted, Denied, Authorized }

//
// AVCaptureDeviceInput
//

@(objc_class="AVCaptureDeviceInput")
AVCaptureDeviceInput :: struct { using _: ns.Object }

@(objc_type=AVCaptureDeviceInput, objc_name="deviceInputWithDeviceError", objc_is_class_method=true)
AVCaptureDeviceInput_deviceInputWithDeviceError :: proc "c" (device: ^AVCaptureDevice, error: rawptr) -> ^AVCaptureDeviceInput {
  return msgSend(^AVCaptureDeviceInput, AVCaptureDeviceInput, "deviceInputWithDevice:error:", device, error)
}

//
// AVCaptureDeviceOutput
//

@(objc_class="AVCaptureVideoDataOutput")
AVCaptureVideoDataOutput :: struct { using _: ns.Object }

@(objc_type=AVCaptureVideoDataOutput, objc_name="init")
AVCaptureVideoDataOutput_init :: proc "c" (self: ^AVCaptureVideoDataOutput) -> ^AVCaptureVideoDataOutput {
  return msgSend(^AVCaptureVideoDataOutput, self, "init")
}

@(objc_type=AVCaptureVideoDataOutput, objc_name="setSampleBufferDelegateQueue")
AVCaptureVideoDataOutput_setSampleBufferDelegateQueue :: proc "c" (self: ^AVCaptureVideoDataOutput, delegate: ns.id, queue: rawptr) {
  msgSend(nil, self, "setSampleBufferDelegate:queue:", delegate, queue)
}

@(objc_type=AVCaptureVideoDataOutput, objc_name="setVideoSettings")
AVCaptureSession_setVideoSettings :: proc "c" (self: ^AVCaptureVideoDataOutput, settings: ^ns.Dictionary) {
  msgSend(nil, self, "setVideoSettings:", settings)
}


// Delegate callbacks
on_output_capture :: proc "c" (self: ns.id, cmd: ns.SEL, output: ns.id, sampleBuffer: ns.id, fromConnection: ns.id) {
  context = runtime.default_context()
  imageBuffer := CMSampleBufferGetImageBuffer(sampleBuffer)
  imageWidth := CVPixelBufferGetWidth(imageBuffer)
  imageHeight := CVPixelBufferGetHeight(imageBuffer)
  stride := CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0)


  // Lock the buffer
  CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly)
  defer CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly)

  // Now it's safe to read from it
  data := cast([^]u8)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
  center_pixel := data[(imageHeight/2) * stride + (imageWidth/2)]
  fmt.printfln("Width = %d  Height = %d  Stride = %d Center Pixel Brightness = %d", imageWidth, imageHeight, stride, center_pixel)

}

///////
/// Constants

// 420v (aka, we don't care about the color, so use the least memory consuming format)
kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange ::
    (u32('4') << 24) | (u32('2') << 16) | (u32('0') << 8) | u32('v')

// Only reading the video buffer
kCVPixelBufferLock_ReadOnly :: 1

//
// Let Us Rock!!!!
//

main :: proc() {
  result := AVCaptureDevice_authorizationStatusForMediaType(AVMediaTypeVideo)
  fmt.println("Authorization = ", result)

  session := ns.alloc(AVCaptureSession)
  session = session->init()
  defer session->release()

  session->startRunning()
  fmt.println("AVCaptureSession running = ", session->isRunning())

  device := AVCaptureDevice_defaultDeviceWithMediaType(AVMediaTypeVideo)
  input := AVCaptureDeviceInput_deviceInputWithDeviceError(device, nil)

  if input == nil {
    fmt.println("ERROR: could not get AV Capture Device Input")
  }

  if session->canAddInput(input) {
    session->addInput(input)
  } else {
    fmt.println("ERROR: could not add AV Capture Device Input to the session")
  }

  output := ns.alloc(AVCaptureVideoDataOutput)
  output = output->init()

  // specify output settings
  chroma_subsampling := ns.Number_numberWithU32(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
  output_settings := ns.Dictionary_dictionaryWithObject(chroma_subsampling, kCVPixelBufferPixelFormatTypeKey)
  output->setVideoSettings(output_settings)

  if session->canAddOutput(output) {
    session->addOutput(output)
  } else {
    fmt.println("ERROR: could not add output to the session")
  }


  // Delegate Class
  NSObject := ns.objc_lookUpClass("NSObject")
  cls := ns.objc_allocateClassPair(NSObject, "VideoCaptureDelegate", 0)

  // Delegate Methods
  sel := ns.sel_registerName("captureOutput:didOutputSampleBuffer:fromConnection:")
  if !ns.class_addMethod(cls, sel, auto_cast on_output_capture, "v@:@@@") {
    fmt.println("ERROR: failed to register capture output delegate")
  }

  ns.objc_registerClassPair(cls)
  output_delegate := ns.class_createInstance(cls, 0)

  queue := dispatch_queue_create("camera.frames", nil)
  output->setSampleBufferDelegateQueue(output_delegate, queue)


  for {
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.5, false)
  }

}
