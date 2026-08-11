package main

import (
	"runtime"
	"unsafe"
)

// Import the Android EGL loader rather than a vendor implementation directly.
// The emulator boot's GuestAngle setting determines which driver it selects.
//go:cgo_import_dynamic guest_eglGetDisplay eglGetDisplay "libEGL.so"
//go:cgo_import_dynamic guest_eglInitialize eglInitialize "libEGL.so"
//go:cgo_import_dynamic guest_eglBindAPI eglBindAPI "libEGL.so"
//go:cgo_import_dynamic guest_eglChooseConfig eglChooseConfig "libEGL.so"
//go:cgo_import_dynamic guest_eglCreatePbufferSurface eglCreatePbufferSurface "libEGL.so"
//go:cgo_import_dynamic guest_eglCreateContext eglCreateContext "libEGL.so"
//go:cgo_import_dynamic guest_eglMakeCurrent eglMakeCurrent "libEGL.so"
//go:cgo_import_dynamic guest_eglGetProcAddress eglGetProcAddress "libEGL.so"
//go:cgo_import_dynamic guest_eglQueryString eglQueryString "libEGL.so"
//go:cgo_import_dynamic guest_eglGetError eglGetError "libEGL.so"
//go:cgo_import_dynamic guest_glGetString glGetString "libGLESv2.so"
//go:cgo_import_dynamic guest_glGetIntegerv glGetIntegerv "libGLESv2.so"

//go:linkname asmcgocall runtime.asmcgocall
func asmcgocall(function, argument unsafe.Pointer) int32

func eglGetDisplayAddress() uintptr
func eglInitializeAddress() uintptr
func eglBindAPIAddress() uintptr
func eglChooseConfigAddress() uintptr
func eglCreatePbufferSurfaceAddress() uintptr
func eglCreateContextAddress() uintptr
func eglMakeCurrentAddress() uintptr
func eglGetProcAddressAddress() uintptr
func eglQueryStringAddress() uintptr
func eglGetErrorAddress() uintptr
func glGetStringAddress() uintptr
func glGetIntegervAddress() uintptr

func cCall(function, a1, a2, a3, a4, a5, a6 uintptr) uintptr {
	arguments := [7]uintptr{a1, a2, a3, a4, a5, a6, 0}
	asmcgocall(unsafe.Pointer(function), unsafe.Pointer(&arguments[0]))
	return arguments[6]
}

func eglGetDisplayCall(display uintptr) uintptr {
	return cCall(eglGetDisplayAddress(), display, 0, 0, 0, 0, 0)
}
func eglInitializeCall(display, major, minor uintptr) uintptr {
	return cCall(eglInitializeAddress(), display, major, minor, 0, 0, 0)
}
func eglBindAPICall(api uintptr) uintptr {
	return cCall(eglBindAPIAddress(), api, 0, 0, 0, 0, 0)
}
func eglChooseConfigCall(display, attrs, config, size, count uintptr) uintptr {
	return cCall(eglChooseConfigAddress(), display, attrs, config, size, count, 0)
}
func eglCreatePbufferSurfaceCall(display, config, attrs uintptr) uintptr {
	return cCall(eglCreatePbufferSurfaceAddress(), display, config, attrs, 0, 0, 0)
}
func eglCreateContextCall(display, config, share, attrs uintptr) uintptr {
	return cCall(eglCreateContextAddress(), display, config, share, attrs, 0, 0)
}
func eglMakeCurrentCall(display, draw, read, context uintptr) uintptr {
	return cCall(eglMakeCurrentAddress(), display, draw, read, context, 0, 0)
}
func eglGetProcAddressCall(name uintptr) uintptr {
	return cCall(eglGetProcAddressAddress(), name, 0, 0, 0, 0, 0)
}
func eglQueryStringCall(display, name uintptr) uintptr {
	return cCall(eglQueryStringAddress(), display, name, 0, 0, 0, 0)
}
func eglGetErrorCall() uintptr {
	return cCall(eglGetErrorAddress(), 0, 0, 0, 0, 0, 0)
}
func glGetStringCall(name uintptr) uintptr {
	return cCall(glGetStringAddress(), name, 0, 0, 0, 0, 0)
}
func glGetIntegervCall(name, value uintptr) {
	cCall(glGetIntegervAddress(), name, value, 0, 0, 0, 0)
}

const (
	eglNone                = 0x3038
	eglOpenGLESAPI         = 0x30a0
	eglSurfaceType         = 0x3033
	eglPbufferBit          = 0x0001
	eglRenderableType      = 0x3040
	eglOpenGLES3Bit        = 0x0040
	eglRedSize             = 0x3024
	eglGreenSize           = 0x3023
	eglBlueSize            = 0x3022
	eglAlphaSize           = 0x3021
	eglWidth               = 0x3057
	eglHeight              = 0x3056
	eglContextMajorVersion = 0x3098
	eglContextMinorVersion = 0x30fb
	glVersion              = 0x1f02
	glRenderer             = 0x1f01
	glShadingLanguage      = 0x8b8c
	glMajorVersion         = 0x821b
	glMinorVersion         = 0x821c
	glMaxGeometryOutput    = 0x8de0
	glMaxPatchVertices     = 0x8e7d
	glMaxTessGenLevel      = 0x8e7e
)

func pointer(value any) uintptr {
	switch typed := value.(type) {
	case *int32:
		return uintptr(unsafe.Pointer(typed))
	case *uintptr:
		return uintptr(unsafe.Pointer(typed))
	case []int32:
		return uintptr(unsafe.Pointer(&typed[0]))
	default:
		panic("unsupported pointer type")
	}
}

func cString(value string) ([]byte, uintptr) {
	bytes := append([]byte(value), 0)
	return bytes, uintptr(unsafe.Pointer(&bytes[0]))
}

func goString(address uintptr) string {
	if address == 0 {
		return "<null>"
	}
	const maximum = 1 << 20
	bytes := unsafe.Slice((*byte)(unsafe.Pointer(address)), maximum)
	length := 0
	for length < len(bytes) && bytes[length] != 0 {
		length++
	}
	return string(bytes[:length])
}

func probeProc(name string) bool {
	bytes, address := cString(name)
	result := eglGetProcAddressCall(address) != 0
	runtime.KeepAlive(bytes)
	return result
}

func main() {
	// EGL current state is thread-local. Without this, a Go scheduler migration
	// between create-context and make-current makes the native driver crash.
	runtime.LockOSThread()
	defer runtime.UnlockOSThread()

	println("stage", "start")
	display := eglGetDisplayCall(0)
	println("stage", "display", display)
	var eglMajor, eglMinor int32
	initialized := eglInitializeCall(display, pointer(&eglMajor), pointer(&eglMinor))
	println("egl_display", display, "initialize", initialized)
	if display == 0 || initialized == 0 {
		println("eglInitialize=fail", "error", eglGetErrorCall())
		return
	}
	println("egl", eglMajor, eglMinor)
	if eglBindAPICall(eglOpenGLESAPI) == 0 {
		println("eglBindAPI=fail", "error", eglGetErrorCall())
		return
	}
	configAttrs := []int32{
		eglSurfaceType, eglPbufferBit,
		eglRenderableType, eglOpenGLES3Bit,
		eglRedSize, 8, eglGreenSize, 8, eglBlueSize, 8, eglAlphaSize, 8,
		eglNone,
	}
	var config uintptr
	var configCount int32
	chooseConfigResult := eglChooseConfigCall(
		display, pointer(configAttrs), pointer(&config), 1, pointer(&configCount),
	)
	runtime.KeepAlive(configAttrs)
	if chooseConfigResult == 0 || configCount == 0 {
		println("eglChooseConfig=fail", "error", eglGetErrorCall())
		return
	}
	surfaceAttrs := []int32{eglWidth, 1, eglHeight, 1, eglNone}
	surface := eglCreatePbufferSurfaceCall(display, config, pointer(surfaceAttrs))
	runtime.KeepAlive(surfaceAttrs)
	if surface == 0 {
		println("eglCreatePbufferSurface=fail", "error", eglGetErrorCall())
		return
	}
	contextAttrs := []int32{eglContextMajorVersion, 3, eglNone}
	context := eglCreateContextCall(display, config, 0, pointer(contextAttrs))
	runtime.KeepAlive(contextAttrs)
	if context == 0 {
		println("request", 3, 0, "create=fail", "error", eglGetErrorCall())
		return
	}
	if eglMakeCurrentCall(display, surface, surface, context) == 0 {
		println("request", 3, 0, "makeCurrent=fail", "error", eglGetErrorCall())
		return
	}
	var major, minor, geometry, patch, tess int32
	glGetIntegervCall(glMajorVersion, pointer(&major))
	glGetIntegervCall(glMinorVersion, pointer(&minor))
	glGetIntegervCall(glMaxGeometryOutput, pointer(&geometry))
	glGetIntegervCall(glMaxPatchVertices, pointer(&patch))
	glGetIntegervCall(glMaxTessGenLevel, pointer(&tess))
	println("request", 3, 0, "actual", major, minor)
	println("version", goString(glGetStringCall(glVersion)))
	println("glsl", goString(glGetStringCall(glShadingLanguage)))
	println("renderer", goString(glGetStringCall(glRenderer)))
	println("limits", "geometry", geometry, "patch", patch, "tess", tess)

	for _, name := range []string{
		"eglClientWaitSyncKHR", "eglCreateImageKHR", "eglCreateSyncKHR",
		"eglDestroyImageKHR", "eglDestroySyncKHR",
		"eglGetCompositorTimingANDROID", "eglGetCompositorTimingSupportedANDROID",
		"eglGetFrameTimestampsANDROID", "eglGetFrameTimestampsSupportedANDROID",
		"eglGetNativeClientBufferANDROID", "eglGetNextFrameIdANDROID",
		"eglGetSyncAttribKHR", "eglGetSystemTimeNV", "eglPresentationTimeANDROID",
		"eglQueryTimestampSupportedANDROID",
		"glBlendEquationSeparatei", "glBlendEquationSeparateiEXT",
		"glBlendEquationi", "glBlendEquationiEXT", "glBlendFuncSeparatei",
		"glBlendFuncSeparateiEXT", "glBlendFunci", "glBlendFunciEXT",
		"glBufferStorageEXT", "glColorMaski", "glColorMaskiEXT",
		"glCopyImageSubData", "glDebugMessageCallbackKHR",
		"glDebugMessageControlKHR", "glDebugMessageInsertKHR",
		"glDebugMessageLogKHR", "glDisablei", "glDisableiEXT",
		"glEGLImageTargetTexture2DOES", "glEnablei", "glEnableiEXT",
		"glFramebufferFetchBarrierQCOM", "glFramebufferTexture",
		"glFramebufferTexture2DMultisampleEXT",
		"glFramebufferTextureMultisampleMultiviewOVR",
		"glFramebufferTextureMultiviewOVR", "glGetObjectLabelEXT",
		"glGetObjectLabelKHR", "glGetObjectPtrLabelKHR", "glGetPointervKHR",
		"glGetQueryObjectui64vEXT", "glLabelObjectEXT", "glObjectLabelKHR",
		"glObjectPtrLabelKHR", "glPopDebugGroupKHR", "glPopGroupMarkerEXT",
		"glPushDebugGroupKHR", "glPushGroupMarkerEXT", "glQueryCounterEXT",
		"glRenderbufferStorageMultisampleEXT", "glTexBuffer",
		"glTexBufferEXT", "glTexBufferRange", "glTexBufferRangeEXT",
	} {
		println("proc", name, probeProc(name))
	}
	println("egl_extensions", goString(eglQueryStringCall(display, 0x3055)))

	// Test rejected context versions only after collecting the working baseline.
	// The shipped native driver can leave make-current unstable when failed
	// high-version requests precede its first ES 3.0 context.
	for _, version := range [][2]int32{{3, 2}, {3, 1}} {
		highAttrs := []int32{
			eglContextMajorVersion, version[0],
			eglContextMinorVersion, version[1],
			eglNone,
		}
		highContext := eglCreateContextCall(display, config, 0, pointer(highAttrs))
		runtime.KeepAlive(highAttrs)
		if highContext == 0 {
			println("request", version[0], version[1], "create=fail", "error", eglGetErrorCall())
		} else {
			println("request", version[0], version[1], "create=pass")
		}
	}
}
