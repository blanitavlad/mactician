#include "textflag.h"

// Each wrapper is entered by runtime.asmcgocall using the platform C ABI. The
// argument-block pointer is in R0. The imported symbol result is returned in
// the final block slot so pointer-sized values are not truncated.
#define C_WRAPPER(wrapperName, addressName, symbolName) \
TEXT wrapperName(SB),NOSPLIT,$0-0; \
	SUB $16, RSP; \
	MOVD R19, 0(RSP); \
	MOVD R0, R19; \
	MOVD 0(R19), R0; \
	MOVD 8(R19), R1; \
	MOVD 16(R19), R2; \
	MOVD 24(R19), R3; \
	MOVD 32(R19), R4; \
	MOVD 40(R19), R5; \
	CALL symbolName(SB); \
	MOVD R0, 48(R19); \
	MOVD 0(RSP), R19; \
	ADD $16, RSP; \
	MOVD $0, R0; \
	RET; \
TEXT addressName(SB),NOSPLIT,$0-8; \
	MOVD $wrapperName(SB), R0; \
	MOVD R0, ret+0(FP); \
	RET

C_WRAPPER(·eglGetDisplayC, ·eglGetDisplayAddress, guest_eglGetDisplay)
C_WRAPPER(·eglInitializeC, ·eglInitializeAddress, guest_eglInitialize)
C_WRAPPER(·eglBindAPIC, ·eglBindAPIAddress, guest_eglBindAPI)
C_WRAPPER(·eglChooseConfigC, ·eglChooseConfigAddress, guest_eglChooseConfig)
C_WRAPPER(·eglCreatePbufferSurfaceC, ·eglCreatePbufferSurfaceAddress, guest_eglCreatePbufferSurface)
C_WRAPPER(·eglCreateContextC, ·eglCreateContextAddress, guest_eglCreateContext)
C_WRAPPER(·eglMakeCurrentC, ·eglMakeCurrentAddress, guest_eglMakeCurrent)
C_WRAPPER(·eglGetProcAddressC, ·eglGetProcAddressAddress, guest_eglGetProcAddress)
C_WRAPPER(·eglQueryStringC, ·eglQueryStringAddress, guest_eglQueryString)
C_WRAPPER(·eglGetErrorC, ·eglGetErrorAddress, guest_eglGetError)
C_WRAPPER(·glGetStringC, ·glGetStringAddress, guest_glGetString)
C_WRAPPER(·glGetIntegervC, ·glGetIntegervAddress, guest_glGetIntegerv)
