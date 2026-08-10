#include <dlfcn.h>

#include <cstdlib>
#include <iostream>

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <EGL/eglext_angle.h>
#include <GLES3/gl32.h>

#ifndef EGL_PLATFORM_ANGLE_TYPE_METAL_ANGLE
#define EGL_PLATFORM_ANGLE_TYPE_METAL_ANGLE 0x3489
#endif

namespace {

template <typename T>
T load(void* library, const char* name) {
    auto symbol = reinterpret_cast<T>(dlsym(library, name));
    if (!symbol) {
        std::cerr << "missing symbol: " << name << "\n";
        std::exit(2);
    }
    return symbol;
}

template <typename T>
T loadOptional(void* library, const char* name) {
    return reinterpret_cast<T>(dlsym(library, name));
}

void printEglError(PFNEGLGETERRORPROC getError, const char* operation) {
    std::cerr << operation << " failed: EGL error 0x" << std::hex << getError() << std::dec << "\n";
}

}  // namespace

int main(int argc, char** argv) {
    if (argc != 3) {
        std::cerr << "usage: angle-egl-probe /path/libEGL.dylib /path/libGLESv2.dylib\n";
        return 2;
    }

    void* glesLibrary = dlopen(argv[2], RTLD_NOW | RTLD_GLOBAL);
    if (!glesLibrary) {
        std::cerr << "dlopen GLES failed: " << dlerror() << "\n";
        return 2;
    }
    void* eglLibrary = dlopen(argv[1], RTLD_NOW | RTLD_GLOBAL);
    if (!eglLibrary) {
        std::cerr << "dlopen EGL failed: " << dlerror() << "\n";
        return 2;
    }

    const auto eglGetErrorFn = load<PFNEGLGETERRORPROC>(eglLibrary, "eglGetError");
    const auto eglGetDisplayFn = load<PFNEGLGETDISPLAYPROC>(eglLibrary, "eglGetDisplay");
    const auto eglGetPlatformDisplayEXTFn =
        loadOptional<PFNEGLGETPLATFORMDISPLAYEXTPROC>(eglLibrary, "eglGetPlatformDisplayEXT");
    const auto eglInitializeFn = load<PFNEGLINITIALIZEPROC>(eglLibrary, "eglInitialize");
    const auto eglQueryStringFn = load<PFNEGLQUERYSTRINGPROC>(eglLibrary, "eglQueryString");
    const auto eglBindAPIFn = load<PFNEGLBINDAPIPROC>(eglLibrary, "eglBindAPI");
    const auto eglChooseConfigFn = load<PFNEGLCHOOSECONFIGPROC>(eglLibrary, "eglChooseConfig");
    const auto eglCreatePbufferSurfaceFn =
        load<PFNEGLCREATEPBUFFERSURFACEPROC>(eglLibrary, "eglCreatePbufferSurface");
    const auto eglCreateContextFn = load<PFNEGLCREATECONTEXTPROC>(eglLibrary, "eglCreateContext");
    const auto eglMakeCurrentFn = load<PFNEGLMAKECURRENTPROC>(eglLibrary, "eglMakeCurrent");
    const auto glGetStringFn = load<PFNGLGETSTRINGPROC>(glesLibrary, "glGetString");

    const EGLint displayAttributes[] = {
        EGL_PLATFORM_ANGLE_TYPE_ANGLE,
        EGL_PLATFORM_ANGLE_TYPE_METAL_ANGLE,
        EGL_NONE,
    };
    std::cout << "EGL client extensions: "
              << eglQueryStringFn(EGL_NO_DISPLAY, EGL_EXTENSIONS) << "\n";
    EGLDisplay display = EGL_NO_DISPLAY;
    if (eglGetPlatformDisplayEXTFn) {
        display = eglGetPlatformDisplayEXTFn(
            EGL_PLATFORM_ANGLE_ANGLE, nullptr, displayAttributes);
    }
    if (display == EGL_NO_DISPLAY) {
        printEglError(eglGetErrorFn, "eglGetPlatformDisplayEXT(Metal); trying eglGetDisplay");
        display = eglGetDisplayFn(EGL_DEFAULT_DISPLAY);
        if (display == EGL_NO_DISPLAY) {
            printEglError(eglGetErrorFn, "eglGetDisplay");
            return 1;
        }
    }

    EGLint eglMajor = 0;
    EGLint eglMinor = 0;
    if (!eglInitializeFn(display, &eglMajor, &eglMinor)) {
        printEglError(eglGetErrorFn, "eglInitialize");
        return 1;
    }
    std::cout << "EGL " << eglMajor << "." << eglMinor << "\n";
    std::cout << "EGL vendor: " << eglQueryStringFn(display, EGL_VENDOR) << "\n";
    std::cout << "EGL version: " << eglQueryStringFn(display, EGL_VERSION) << "\n";

    if (!eglBindAPIFn(EGL_OPENGL_ES_API)) {
        printEglError(eglGetErrorFn, "eglBindAPI");
        return 1;
    }

    const EGLint configAttributes[] = {
        EGL_SURFACE_TYPE, EGL_PBUFFER_BIT,
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT_KHR,
        EGL_RED_SIZE, 8,
        EGL_GREEN_SIZE, 8,
        EGL_BLUE_SIZE, 8,
        EGL_ALPHA_SIZE, 8,
        EGL_NONE,
    };
    EGLConfig config = nullptr;
    EGLint configCount = 0;
    if (!eglChooseConfigFn(display, configAttributes, &config, 1, &configCount) || configCount == 0) {
        printEglError(eglGetErrorFn, "eglChooseConfig");
        return 1;
    }

    const EGLint surfaceAttributes[] = {EGL_WIDTH, 16, EGL_HEIGHT, 16, EGL_NONE};
    EGLSurface surface = eglCreatePbufferSurfaceFn(display, config, surfaceAttributes);
    if (surface == EGL_NO_SURFACE) {
        printEglError(eglGetErrorFn, "eglCreatePbufferSurface");
        return 1;
    }

    const EGLint contextAttributes[] = {
        EGL_CONTEXT_MAJOR_VERSION_KHR, 3,
        EGL_CONTEXT_MINOR_VERSION_KHR, 2,
        EGL_NONE,
    };
    EGLContext context = eglCreateContextFn(display, config, EGL_NO_CONTEXT, contextAttributes);
    if (context == EGL_NO_CONTEXT) {
        printEglError(eglGetErrorFn, "eglCreateContext(3.2)");
        return 1;
    }
    if (!eglMakeCurrentFn(display, surface, surface, context)) {
        printEglError(eglGetErrorFn, "eglMakeCurrent");
        return 1;
    }

    std::cout << "GL vendor: " << glGetStringFn(GL_VENDOR) << "\n";
    std::cout << "GL renderer: " << glGetStringFn(GL_RENDERER) << "\n";
    std::cout << "GL version: " << glGetStringFn(GL_VERSION) << "\n";
    std::cout << "GLSL version: " << glGetStringFn(GL_SHADING_LANGUAGE_VERSION) << "\n";
    return 0;
}
