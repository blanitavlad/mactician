#include <dlfcn.h>

#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

// Keep this probe self-contained. The Android Emulator runtime ships ANGLE
// dylibs, but it does not ship the EGL/GLES development headers used to build
// them. These declarations are the small ABI subset exercised below.
using EGLBoolean = unsigned int;
using EGLenum = unsigned int;
using EGLint = int;
using EGLAttrib = std::intptr_t;
using EGLDisplay = void*;
using EGLConfig = void*;
using EGLSurface = void*;
using EGLContext = void*;
using __eglMustCastToProperFunctionPointerType = void (*)();

using GLenum = unsigned int;
using GLuint = unsigned int;
using GLint = int;
using GLsizei = int;
using GLboolean = unsigned char;
using GLbitfield = unsigned int;
using GLchar = char;
using GLsizeiptr = std::intptr_t;
using GLubyte = unsigned char;
using GLuint64 = std::uint64_t;
using GLsync = void*;

constexpr EGLDisplay EGL_NO_DISPLAY = nullptr;
constexpr EGLSurface EGL_NO_SURFACE = nullptr;
constexpr EGLContext EGL_NO_CONTEXT = nullptr;
constexpr void* EGL_DEFAULT_DISPLAY = nullptr;

constexpr EGLint EGL_NONE = 0x3038;
constexpr EGLint EGL_EXTENSIONS = 0x3055;
constexpr EGLint EGL_VENDOR = 0x3053;
constexpr EGLint EGL_VERSION = 0x3054;
constexpr EGLint EGL_CLIENT_APIS = 0x308D;
constexpr EGLenum EGL_OPENGL_ES_API = 0x30A0;
constexpr EGLint EGL_SURFACE_TYPE = 0x3033;
constexpr EGLint EGL_PBUFFER_BIT = 0x0001;
constexpr EGLint EGL_RENDERABLE_TYPE = 0x3040;
constexpr EGLint EGL_OPENGL_ES3_BIT_KHR = 0x0040;
constexpr EGLint EGL_RED_SIZE = 0x3024;
constexpr EGLint EGL_GREEN_SIZE = 0x3023;
constexpr EGLint EGL_BLUE_SIZE = 0x3022;
constexpr EGLint EGL_ALPHA_SIZE = 0x3021;
constexpr EGLint EGL_WIDTH = 0x3057;
constexpr EGLint EGL_HEIGHT = 0x3056;
constexpr EGLint EGL_CONTEXT_MAJOR_VERSION_KHR = 0x3098;
constexpr EGLint EGL_CONTEXT_MINOR_VERSION_KHR = 0x30FB;

constexpr EGLenum EGL_PLATFORM_ANGLE_ANGLE = 0x3202;
constexpr EGLint EGL_PLATFORM_ANGLE_TYPE_ANGLE = 0x3203;
constexpr EGLint EGL_PLATFORM_ANGLE_TYPE_DEFAULT_ANGLE = 0x3206;
constexpr EGLint EGL_PLATFORM_ANGLE_TYPE_OPENGL_ANGLE = 0x320D;
constexpr EGLint EGL_PLATFORM_ANGLE_TYPE_VULKAN_ANGLE = 0x3450;
constexpr EGLint EGL_PLATFORM_ANGLE_TYPE_METAL_ANGLE = 0x3489;
constexpr EGLint EGL_FEATURE_NAME_ANGLE = 0x3460;
constexpr EGLint EGL_FEATURE_STATUS_ANGLE = 0x3464;
constexpr EGLint EGL_FEATURE_COUNT_ANGLE = 0x3465;
constexpr EGLint EGL_FEATURE_OVERRIDES_ENABLED_ANGLE = 0x3466;
constexpr EGLint EGL_FEATURE_OVERRIDES_DISABLED_ANGLE = 0x3467;

constexpr GLenum GL_VENDOR = 0x1F00;
constexpr GLenum GL_RENDERER = 0x1F01;
constexpr GLenum GL_VERSION = 0x1F02;
constexpr GLenum GL_EXTENSIONS = 0x1F03;
constexpr GLenum GL_SHADING_LANGUAGE_VERSION = 0x8B8C;
constexpr GLenum GL_MAJOR_VERSION = 0x821B;
constexpr GLenum GL_MINOR_VERSION = 0x821C;
constexpr GLenum GL_NUM_EXTENSIONS = 0x821D;
constexpr GLenum GL_NO_ERROR = 0;
constexpr GLenum GL_COMPUTE_SHADER = 0x91B9;
constexpr GLenum GL_VERTEX_SHADER = 0x8B31;
constexpr GLenum GL_TESS_CONTROL_SHADER = 0x8E88;
constexpr GLenum GL_TESS_EVALUATION_SHADER = 0x8E87;
constexpr GLenum GL_GEOMETRY_SHADER = 0x8DD9;
constexpr GLenum GL_FRAGMENT_SHADER = 0x8B30;
constexpr GLenum GL_COMPILE_STATUS = 0x8B81;
constexpr GLenum GL_LINK_STATUS = 0x8B82;
constexpr GLenum GL_INFO_LOG_LENGTH = 0x8B84;
constexpr GLenum GL_MAX_GEOMETRY_OUTPUT_VERTICES = 0x8DE0;
constexpr GLenum GL_MAX_PATCH_VERTICES = 0x8E7D;
constexpr GLenum GL_MAX_TESS_GEN_LEVEL = 0x8E7E;
constexpr GLenum GL_SHADER_STORAGE_BUFFER = 0x90D2;
constexpr GLenum GL_DYNAMIC_DRAW = 0x88E8;
constexpr GLenum GL_MAP_READ_BIT = 0x0001;
constexpr GLenum GL_BUFFER_UPDATE_BARRIER_BIT = 0x00000200;
constexpr GLenum GL_SHADER_STORAGE_BARRIER_BIT = 0x00002000;
constexpr GLenum GL_SHADER_IMAGE_ACCESS_BARRIER_BIT = 0x00000020;
constexpr GLenum GL_TEXTURE0 = 0x84C0;
constexpr GLenum GL_TEXTURE_2D = 0x0DE1;
constexpr GLenum GL_TEXTURE_BUFFER = 0x8C2A;
constexpr GLenum GL_R32UI = 0x8236;
constexpr GLenum GL_READ_WRITE = 0x88BA;
constexpr GLenum GL_SYNC_GPU_COMMANDS_COMPLETE = 0x9117;
constexpr GLenum GL_SYNC_FLUSH_COMMANDS_BIT = 0x00000001;
constexpr GLenum GL_ALREADY_SIGNALED = 0x911A;
constexpr GLenum GL_CONDITION_SATISFIED = 0x911C;

using PFNEGLGETERRORPROC = EGLint (*)();
using PFNEGLGETDISPLAYPROC = EGLDisplay (*)(void*);
using PFNEGLGETPLATFORMDISPLAYPROC = EGLDisplay (*)(EGLenum, void*, const EGLAttrib*);
using PFNEGLGETPLATFORMDISPLAYEXTPROC = EGLDisplay (*)(EGLenum, void*, const EGLint*);
using PFNEGLINITIALIZEPROC = EGLBoolean (*)(EGLDisplay, EGLint*, EGLint*);
using PFNEGLQUERYSTRINGPROC = const char* (*)(EGLDisplay, EGLint);
using PFNEGLBINDAPIPROC = EGLBoolean (*)(EGLenum);
using PFNEGLCHOOSECONFIGPROC = EGLBoolean (*)(EGLDisplay, const EGLint*, EGLConfig*, EGLint, EGLint*);
using PFNEGLCREATEPBUFFERSURFACEPROC = EGLSurface (*)(EGLDisplay, EGLConfig, const EGLint*);
using PFNEGLCREATECONTEXTPROC = EGLContext (*)(EGLDisplay, EGLConfig, EGLContext, const EGLint*);
using PFNEGLMAKECURRENTPROC = EGLBoolean (*)(EGLDisplay, EGLSurface, EGLSurface, EGLContext);
using PFNEGLDESTROYCONTEXTPROC = EGLBoolean (*)(EGLDisplay, EGLContext);
using PFNEGLDESTROYSURFACEPROC = EGLBoolean (*)(EGLDisplay, EGLSurface);
using PFNEGLTERMINATEPROC = EGLBoolean (*)(EGLDisplay);
using PFNEGLGETPROCADDRESSPROC = __eglMustCastToProperFunctionPointerType (*)(const char*);
using PFNEGLQUERYSTRINGIANGLEPROC = const char* (*)(EGLDisplay, EGLint, EGLint);
using PFNEGLQUERYDISPLAYATTRIBANGLEPROC = EGLBoolean (*)(EGLDisplay, EGLint, EGLAttrib*);
using PFNGLGETSTRINGPROC = const GLubyte* (*)(GLenum);
using PFNGLGETSTRINGIPROC = const GLubyte* (*)(GLenum, GLuint);
using PFNGLGETINTEGERVPROC = void (*)(GLenum, GLint*);
using PFNGLGETERRORPROC = GLenum (*)();
using PFNGLCREATESHADERPROC = GLuint (*)(GLenum);
using PFNGLSHADERSOURCEPROC = void (*)(GLuint, GLsizei, const GLchar* const*, const GLint*);
using PFNGLCOMPILESHADERPROC = void (*)(GLuint);
using PFNGLGETSHADERIVPROC = void (*)(GLuint, GLenum, GLint*);
using PFNGLGETSHADERINFOLOGPROC = void (*)(GLuint, GLsizei, GLsizei*, GLchar*);
using PFNGLDELETESHADERPROC = void (*)(GLuint);
using PFNGLCREATEPROGRAMPROC = GLuint (*)();
using PFNGLATTACHSHADERPROC = void (*)(GLuint, GLuint);
using PFNGLLINKPROGRAMPROC = void (*)(GLuint);
using PFNGLGETPROGRAMIVPROC = void (*)(GLuint, GLenum, GLint*);
using PFNGLGETPROGRAMINFOLOGPROC = void (*)(GLuint, GLsizei, GLsizei*, GLchar*);
using PFNGLUSEPROGRAMPROC = void (*)(GLuint);
using PFNGLDELETEPROGRAMPROC = void (*)(GLuint);
using PFNGLGENBUFFERSPROC = void (*)(GLsizei, GLuint*);
using PFNGLBINDBUFFERPROC = void (*)(GLenum, GLuint);
using PFNGLBUFFERDATAPROC = void (*)(GLenum, GLsizeiptr, const void*, GLenum);
using PFNGLBINDBUFFERBASEPROC = void (*)(GLenum, GLuint, GLuint);
using PFNGLMAPBUFFERRANGEPROC = void* (*)(GLenum, std::intptr_t, GLsizeiptr, GLbitfield);
using PFNGLUNMAPBUFFERPROC = GLboolean (*)(GLenum);
using PFNGLDELETEBUFFERSPROC = void (*)(GLsizei, const GLuint*);
using PFNGLDISPATCHCOMPUTEPROC = void (*)(GLuint, GLuint, GLuint);
using PFNGLMEMORYBARRIERPROC = void (*)(GLbitfield);
using PFNGLFINISHPROC = void (*)();
using PFNGLGENTEXTURESPROC = void (*)(GLsizei, GLuint*);
using PFNGLACTIVETEXTUREPROC = void (*)(GLenum);
using PFNGLBINDTEXTUREPROC = void (*)(GLenum, GLuint);
using PFNGLTEXBUFFERPROC = void (*)(GLenum, GLenum, GLuint);
using PFNGLTEXSTORAGE2DPROC = void (*)(GLenum, GLsizei, GLenum, GLsizei, GLsizei);
using PFNGLBINDIMAGETEXTUREPROC = void (*)(
    GLuint, GLuint, GLint, GLboolean, GLint, GLenum, GLenum);
using PFNGLDELETETEXTURESPROC = void (*)(GLsizei, const GLuint*);
using PFNGLFENCESYNCPROC = GLsync (*)(GLenum, GLbitfield);
using PFNGLCLIENTWAITSYNCPROC = GLenum (*)(GLsync, GLbitfield, GLuint64);
using PFNGLDELETESYNCPROC = void (*)(GLsync);

namespace {

template <typename T>
T load(void* library, const char* name) {
    auto symbol = reinterpret_cast<T>(dlsym(library, name));
    if (!symbol) {
        std::cerr << "missing required symbol: " << name << "\n";
        std::exit(2);
    }
    return symbol;
}

template <typename T>
T loadOptional(void* library, const char* name) {
    return reinterpret_cast<T>(dlsym(library, name));
}

template <typename T>
T resolve(void* library, PFNEGLGETPROCADDRESSPROC getProcAddress, const char* name) {
    auto symbol = loadOptional<T>(library, name);
    if (!symbol) {
        symbol = reinterpret_cast<T>(getProcAddress(name));
    }
    return symbol;
}

const char* safe(const char* value) {
    return value ? value : "<null>";
}

const char* glString(PFNGLGETSTRINGPROC getString, GLenum name) {
    return safe(reinterpret_cast<const char*>(getString(name)));
}

void printEglError(PFNEGLGETERRORPROC getError, const char* operation) {
    std::cout << "  " << operation << ": failed, egl_error=0x"
              << std::hex << getError() << std::dec << "\n";
}

EGLint backendType(const std::string& backend) {
    if (backend == "default") {
        return EGL_PLATFORM_ANGLE_TYPE_DEFAULT_ANGLE;
    }
    if (backend == "metal") {
        return EGL_PLATFORM_ANGLE_TYPE_METAL_ANGLE;
    }
    if (backend == "vulkan") {
        return EGL_PLATFORM_ANGLE_TYPE_VULKAN_ANGLE;
    }
    if (backend == "opengl") {
        return EGL_PLATFORM_ANGLE_TYPE_OPENGL_ANGLE;
    }
    std::cerr << "backend must be one of: default, metal, vulkan, opengl\n";
    std::exit(2);
}

bool containsExtension(PFNGLGETSTRINGIPROC getStringi, GLint count, const char* wanted) {
    if (!getStringi) {
        return false;
    }
    for (GLint index = 0; index < count; ++index) {
        const auto* value = reinterpret_cast<const char*>(
            getStringi(GL_EXTENSIONS, static_cast<GLuint>(index)));
        if (value && std::strcmp(value, wanted) == 0) {
            return true;
        }
    }
    return false;
}

std::vector<std::string> splitOverrides(const char* value) {
    std::vector<std::string> result;
    if (!value || !*value) {
        return result;
    }
    std::string remaining(value);
    std::size_t start = 0;
    while (start <= remaining.size()) {
        const std::size_t end = remaining.find(':', start);
        const std::string item = remaining.substr(start, end - start);
        if (!item.empty()) {
            result.push_back(item);
        }
        if (end == std::string::npos) {
            break;
        }
        start = end + 1;
    }
    return result;
}

std::vector<const char*> overridePointers(const std::vector<std::string>& names) {
    std::vector<const char*> result;
    for (const auto& name : names) {
        result.push_back(name.c_str());
    }
    result.push_back(nullptr);
    return result;
}

struct FunctionalGles {
    PFNGLGETERRORPROC getError = nullptr;
    PFNGLCREATESHADERPROC createShader = nullptr;
    PFNGLSHADERSOURCEPROC shaderSource = nullptr;
    PFNGLCOMPILESHADERPROC compileShader = nullptr;
    PFNGLGETSHADERIVPROC getShaderiv = nullptr;
    PFNGLGETSHADERINFOLOGPROC getShaderInfoLog = nullptr;
    PFNGLDELETESHADERPROC deleteShader = nullptr;
    PFNGLCREATEPROGRAMPROC createProgram = nullptr;
    PFNGLATTACHSHADERPROC attachShader = nullptr;
    PFNGLLINKPROGRAMPROC linkProgram = nullptr;
    PFNGLGETPROGRAMIVPROC getProgramiv = nullptr;
    PFNGLGETPROGRAMINFOLOGPROC getProgramInfoLog = nullptr;
    PFNGLUSEPROGRAMPROC useProgram = nullptr;
    PFNGLDELETEPROGRAMPROC deleteProgram = nullptr;
    PFNGLGENBUFFERSPROC genBuffers = nullptr;
    PFNGLBINDBUFFERPROC bindBuffer = nullptr;
    PFNGLBUFFERDATAPROC bufferData = nullptr;
    PFNGLBINDBUFFERBASEPROC bindBufferBase = nullptr;
    PFNGLMAPBUFFERRANGEPROC mapBufferRange = nullptr;
    PFNGLUNMAPBUFFERPROC unmapBuffer = nullptr;
    PFNGLDELETEBUFFERSPROC deleteBuffers = nullptr;
    PFNGLDISPATCHCOMPUTEPROC dispatchCompute = nullptr;
    PFNGLMEMORYBARRIERPROC memoryBarrier = nullptr;
    PFNGLFINISHPROC finish = nullptr;
    PFNGLGENTEXTURESPROC genTextures = nullptr;
    PFNGLACTIVETEXTUREPROC activeTexture = nullptr;
    PFNGLBINDTEXTUREPROC bindTexture = nullptr;
    PFNGLTEXBUFFERPROC texBuffer = nullptr;
    PFNGLTEXSTORAGE2DPROC texStorage2D = nullptr;
    PFNGLBINDIMAGETEXTUREPROC bindImageTexture = nullptr;
    PFNGLDELETETEXTURESPROC deleteTextures = nullptr;
    PFNGLFENCESYNCPROC fenceSync = nullptr;
    PFNGLCLIENTWAITSYNCPROC clientWaitSync = nullptr;
    PFNGLDELETESYNCPROC deleteSync = nullptr;
};

FunctionalGles loadFunctionalGles(
        void* library, PFNEGLGETPROCADDRESSPROC getProcAddress) {
#define RESOLVE(member, type, name) \
    result.member = resolve<type>(library, getProcAddress, name)
    FunctionalGles result;
    RESOLVE(getError, PFNGLGETERRORPROC, "glGetError");
    RESOLVE(createShader, PFNGLCREATESHADERPROC, "glCreateShader");
    RESOLVE(shaderSource, PFNGLSHADERSOURCEPROC, "glShaderSource");
    RESOLVE(compileShader, PFNGLCOMPILESHADERPROC, "glCompileShader");
    RESOLVE(getShaderiv, PFNGLGETSHADERIVPROC, "glGetShaderiv");
    RESOLVE(getShaderInfoLog, PFNGLGETSHADERINFOLOGPROC, "glGetShaderInfoLog");
    RESOLVE(deleteShader, PFNGLDELETESHADERPROC, "glDeleteShader");
    RESOLVE(createProgram, PFNGLCREATEPROGRAMPROC, "glCreateProgram");
    RESOLVE(attachShader, PFNGLATTACHSHADERPROC, "glAttachShader");
    RESOLVE(linkProgram, PFNGLLINKPROGRAMPROC, "glLinkProgram");
    RESOLVE(getProgramiv, PFNGLGETPROGRAMIVPROC, "glGetProgramiv");
    RESOLVE(getProgramInfoLog, PFNGLGETPROGRAMINFOLOGPROC, "glGetProgramInfoLog");
    RESOLVE(useProgram, PFNGLUSEPROGRAMPROC, "glUseProgram");
    RESOLVE(deleteProgram, PFNGLDELETEPROGRAMPROC, "glDeleteProgram");
    RESOLVE(genBuffers, PFNGLGENBUFFERSPROC, "glGenBuffers");
    RESOLVE(bindBuffer, PFNGLBINDBUFFERPROC, "glBindBuffer");
    RESOLVE(bufferData, PFNGLBUFFERDATAPROC, "glBufferData");
    RESOLVE(bindBufferBase, PFNGLBINDBUFFERBASEPROC, "glBindBufferBase");
    RESOLVE(mapBufferRange, PFNGLMAPBUFFERRANGEPROC, "glMapBufferRange");
    RESOLVE(unmapBuffer, PFNGLUNMAPBUFFERPROC, "glUnmapBuffer");
    RESOLVE(deleteBuffers, PFNGLDELETEBUFFERSPROC, "glDeleteBuffers");
    RESOLVE(dispatchCompute, PFNGLDISPATCHCOMPUTEPROC, "glDispatchCompute");
    RESOLVE(memoryBarrier, PFNGLMEMORYBARRIERPROC, "glMemoryBarrier");
    RESOLVE(finish, PFNGLFINISHPROC, "glFinish");
    RESOLVE(genTextures, PFNGLGENTEXTURESPROC, "glGenTextures");
    RESOLVE(activeTexture, PFNGLACTIVETEXTUREPROC, "glActiveTexture");
    RESOLVE(bindTexture, PFNGLBINDTEXTUREPROC, "glBindTexture");
    RESOLVE(texBuffer, PFNGLTEXBUFFERPROC, "glTexBuffer");
    RESOLVE(texStorage2D, PFNGLTEXSTORAGE2DPROC, "glTexStorage2D");
    RESOLVE(bindImageTexture, PFNGLBINDIMAGETEXTUREPROC, "glBindImageTexture");
    RESOLVE(deleteTextures, PFNGLDELETETEXTURESPROC, "glDeleteTextures");
    RESOLVE(fenceSync, PFNGLFENCESYNCPROC, "glFenceSync");
    RESOLVE(clientWaitSync, PFNGLCLIENTWAITSYNCPROC, "glClientWaitSync");
    RESOLVE(deleteSync, PFNGLDELETESYNCPROC, "glDeleteSync");
#undef RESOLVE
    return result;
}

bool hasComputeFunctions(const FunctionalGles& gl) {
    return gl.getError && gl.createShader && gl.shaderSource && gl.compileShader
        && gl.getShaderiv && gl.getShaderInfoLog && gl.deleteShader
        && gl.createProgram && gl.attachShader && gl.linkProgram
        && gl.getProgramiv && gl.getProgramInfoLog && gl.useProgram
        && gl.deleteProgram && gl.genBuffers && gl.bindBuffer && gl.bufferData
        && gl.bindBufferBase && gl.mapBufferRange && gl.unmapBuffer
        && gl.deleteBuffers && gl.dispatchCompute && gl.memoryBarrier && gl.finish;
}

GLuint compileShader(
        const FunctionalGles& gl, GLenum type, const char* label, const char* source) {
    const GLuint shader = gl.createShader(type);
    gl.shaderSource(shader, 1, &source, nullptr);
    gl.compileShader(shader);
    GLint compiled = 0;
    gl.getShaderiv(shader, GL_COMPILE_STATUS, &compiled);
    if (!compiled) {
        GLint length = 0;
        gl.getShaderiv(shader, GL_INFO_LOG_LENGTH, &length);
        std::vector<GLchar> log(static_cast<std::size_t>(length > 1 ? length : 2));
        gl.getShaderInfoLog(shader, static_cast<GLsizei>(log.size()), nullptr, log.data());
        std::cout << "    " << label << "_compile_log='" << log.data() << "'\n";
        gl.deleteShader(shader);
        return 0;
    }
    return shader;
}

GLuint linkProgram(
        const FunctionalGles& gl, const char* label, const std::vector<GLuint>& shaders) {
    const GLuint program = gl.createProgram();
    for (const GLuint shader : shaders) {
        gl.attachShader(program, shader);
    }
    gl.linkProgram(program);
    for (const GLuint shader : shaders) {
        gl.deleteShader(shader);
    }

    GLint linked = 0;
    gl.getProgramiv(program, GL_LINK_STATUS, &linked);
    if (!linked) {
        GLint length = 0;
        gl.getProgramiv(program, GL_INFO_LOG_LENGTH, &length);
        std::vector<GLchar> log(static_cast<std::size_t>(length > 1 ? length : 2));
        gl.getProgramInfoLog(program, static_cast<GLsizei>(log.size()), nullptr, log.data());
        std::cout << "    " << label << "_link_log='" << log.data() << "'\n";
        gl.deleteProgram(program);
        return 0;
    }
    return program;
}

GLuint compileComputeProgram(const FunctionalGles& gl, const char* source) {
    const GLuint shader = compileShader(gl, GL_COMPUTE_SHADER, "compute", source);
    return shader ? linkProgram(gl, "compute", {shader}) : 0;
}

bool readBufferValue(const FunctionalGles& gl, GLuint buffer, std::uint32_t expected) {
    gl.bindBuffer(GL_SHADER_STORAGE_BUFFER, buffer);
    gl.finish();
    void* mapped = gl.mapBufferRange(
        GL_SHADER_STORAGE_BUFFER, 0, sizeof(std::uint32_t), GL_MAP_READ_BIT);
    if (!mapped) {
        return false;
    }
    const auto actual = *static_cast<const std::uint32_t*>(mapped);
    const bool unmapped = gl.unmapBuffer(GL_SHADER_STORAGE_BUFFER) != 0;
    return unmapped && actual == expected;
}

void clearErrors(const FunctionalGles& gl) {
    if (!gl.getError) {
        return;
    }
    while (gl.getError() != GL_NO_ERROR) {
    }
}

bool runComputeSsboTest(const FunctionalGles& gl) {
    if (!hasComputeFunctions(gl)) {
        return false;
    }
    static const char* source =
        "#version 310 es\n"
        "layout(local_size_x=1) in;\n"
        "layout(std430, binding=0) buffer Output { uint value; } outData;\n"
        "void main() { outData.value = 0x1234abcdu; }\n";
    const GLuint program = compileComputeProgram(gl, source);
    if (!program) {
        return false;
    }
    GLuint output = 0;
    const std::uint32_t initial = 0;
    gl.genBuffers(1, &output);
    gl.bindBuffer(GL_SHADER_STORAGE_BUFFER, output);
    gl.bufferData(GL_SHADER_STORAGE_BUFFER, sizeof(initial), &initial, GL_DYNAMIC_DRAW);
    gl.bindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, output);
    gl.useProgram(program);
    gl.dispatchCompute(1, 1, 1);
    gl.memoryBarrier(GL_SHADER_STORAGE_BARRIER_BIT | GL_BUFFER_UPDATE_BARRIER_BIT);
    const bool passed = gl.getError() == GL_NO_ERROR
        && readBufferValue(gl, output, 0x1234abcdu)
        && gl.getError() == GL_NO_ERROR;
    gl.deleteBuffers(1, &output);
    gl.deleteProgram(program);
    return passed;
}

bool runImageLoadStoreTest(const FunctionalGles& gl) {
    if (!hasComputeFunctions(gl) || !gl.genTextures || !gl.bindTexture
            || !gl.texStorage2D || !gl.bindImageTexture || !gl.deleteTextures) {
        return false;
    }
    static const char* writeSource =
        "#version 310 es\n"
        "layout(local_size_x=1) in;\n"
        "layout(r32ui, binding=0) writeonly uniform highp uimage2D targetImage;\n"
        "void main() { imageStore(targetImage, ivec2(0), uvec4(0xdecafbadu)); }\n";
    static const char* readSource =
        "#version 310 es\n"
        "layout(local_size_x=1) in;\n"
        "layout(r32ui, binding=0) readonly uniform highp uimage2D sourceImage;\n"
        "layout(std430, binding=1) buffer Output { uint value; } outData;\n"
        "void main() { outData.value = imageLoad(sourceImage, ivec2(0)).r; }\n";
    const GLuint writeProgram = compileComputeProgram(gl, writeSource);
    const GLuint readProgram = compileComputeProgram(gl, readSource);
    if (!writeProgram || !readProgram) {
        if (writeProgram) {
            gl.deleteProgram(writeProgram);
        }
        if (readProgram) {
            gl.deleteProgram(readProgram);
        }
        return false;
    }

    GLuint texture = 0;
    GLuint output = 0;
    const std::uint32_t initial = 0;
    gl.genTextures(1, &texture);
    gl.bindTexture(GL_TEXTURE_2D, texture);
    gl.texStorage2D(GL_TEXTURE_2D, 1, GL_R32UI, 1, 1);
    gl.bindImageTexture(0, texture, 0, 0, 0, GL_READ_WRITE, GL_R32UI);
    gl.genBuffers(1, &output);
    gl.bindBuffer(GL_SHADER_STORAGE_BUFFER, output);
    gl.bufferData(GL_SHADER_STORAGE_BUFFER, sizeof(initial), &initial, GL_DYNAMIC_DRAW);
    gl.bindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, output);

    clearErrors(gl);
    gl.useProgram(writeProgram);
    gl.dispatchCompute(1, 1, 1);
    gl.memoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT);
    gl.useProgram(readProgram);
    gl.dispatchCompute(1, 1, 1);
    gl.memoryBarrier(GL_SHADER_STORAGE_BARRIER_BIT | GL_BUFFER_UPDATE_BARRIER_BIT);
    const bool passed = gl.getError() == GL_NO_ERROR
        && readBufferValue(gl, output, 0xdecafbadu)
        && gl.getError() == GL_NO_ERROR;
    gl.deleteBuffers(1, &output);
    gl.deleteTextures(1, &texture);
    gl.deleteProgram(readProgram);
    gl.deleteProgram(writeProgram);
    return passed;
}

bool runSyncTest(const FunctionalGles& gl) {
    if (!gl.getError || !gl.fenceSync || !gl.clientWaitSync || !gl.deleteSync) {
        return false;
    }
    clearErrors(gl);
    const GLsync sync = gl.fenceSync(GL_SYNC_GPU_COMMANDS_COMPLETE, 0);
    if (!sync || gl.getError() != GL_NO_ERROR) {
        return false;
    }
    const GLenum result = gl.clientWaitSync(
        sync, GL_SYNC_FLUSH_COMMANDS_BIT, static_cast<GLuint64>(1000000000));
    gl.deleteSync(sync);
    return (result == GL_ALREADY_SIGNALED || result == GL_CONDITION_SATISFIED)
        && gl.getError() == GL_NO_ERROR;
}

bool runTextureBufferTest(const FunctionalGles& gl) {
    if (!hasComputeFunctions(gl) || !gl.genTextures || !gl.activeTexture
            || !gl.bindTexture || !gl.texBuffer || !gl.deleteTextures) {
        return false;
    }
    static const char* source =
        "#version 320 es\n"
        "precision highp int;\n"
        "layout(local_size_x=1) in;\n"
        "layout(binding=0) uniform highp usamplerBuffer sourceBuffer;\n"
        "layout(std430, binding=1) buffer Output { uint value; } outData;\n"
        "void main() { outData.value = texelFetch(sourceBuffer, 0).r; }\n";
    const GLuint program = compileComputeProgram(gl, source);
    if (!program) {
        return false;
    }

    const std::uint32_t expected = 0x00c0ffeeu;
    const std::uint32_t initial = 0;
    GLuint buffers[2] = {};
    GLuint texture = 0;
    gl.genBuffers(2, buffers);
    gl.bindBuffer(GL_TEXTURE_BUFFER, buffers[0]);
    gl.bufferData(GL_TEXTURE_BUFFER, sizeof(expected), &expected, GL_DYNAMIC_DRAW);
    gl.genTextures(1, &texture);
    gl.activeTexture(GL_TEXTURE0);
    gl.bindTexture(GL_TEXTURE_BUFFER, texture);
    gl.texBuffer(GL_TEXTURE_BUFFER, GL_R32UI, buffers[0]);
    gl.bindBuffer(GL_SHADER_STORAGE_BUFFER, buffers[1]);
    gl.bufferData(GL_SHADER_STORAGE_BUFFER, sizeof(initial), &initial, GL_DYNAMIC_DRAW);
    gl.bindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, buffers[1]);
    gl.useProgram(program);
    gl.dispatchCompute(1, 1, 1);
    gl.memoryBarrier(GL_SHADER_STORAGE_BARRIER_BIT | GL_BUFFER_UPDATE_BARRIER_BIT);
    const bool passed = gl.getError() == GL_NO_ERROR
        && readBufferValue(gl, buffers[1], expected)
        && gl.getError() == GL_NO_ERROR;
    gl.deleteTextures(1, &texture);
    gl.deleteBuffers(2, buffers);
    gl.deleteProgram(program);
    return passed;
}

bool runShaderPipeline(
        const FunctionalGles& gl,
        const char* label,
        const std::vector<std::pair<GLenum, const char*>>& stages) {
    std::vector<GLuint> shaders;
    for (const auto& stage : stages) {
        const GLuint shader = compileShader(gl, stage.first, label, stage.second);
        if (!shader) {
            for (const GLuint compiled : shaders) {
                gl.deleteShader(compiled);
            }
            return false;
        }
        shaders.push_back(shader);
    }
    const GLuint program = linkProgram(gl, label, shaders);
    if (!program) {
        return false;
    }
    gl.deleteProgram(program);
    return gl.getError() == GL_NO_ERROR;
}

bool runEs32ShaderStageTests(const FunctionalGles& gl) {
    if (!hasComputeFunctions(gl)) {
        return false;
    }
    static const char* vertex =
        "#version 320 es\n"
        "void main() { gl_Position = vec4(float(gl_VertexID), 0.0, 0.0, 1.0); }\n";
    static const char* tessControl =
        "#version 320 es\n"
        "layout(vertices=3) out;\n"
        "void main() {\n"
        "  gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;\n"
        "  if (gl_InvocationID == 0) {\n"
        "    gl_TessLevelInner[0] = 1.0;\n"
        "    gl_TessLevelOuter[0] = 1.0;\n"
        "    gl_TessLevelOuter[1] = 1.0;\n"
        "    gl_TessLevelOuter[2] = 1.0;\n"
        "  }\n"
        "}\n";
    static const char* tessEvaluation =
        "#version 320 es\n"
        "layout(triangles, equal_spacing, cw) in;\n"
        "void main() {\n"
        "  gl_Position = gl_TessCoord.x * gl_in[0].gl_Position\n"
        "              + gl_TessCoord.y * gl_in[1].gl_Position\n"
        "              + gl_TessCoord.z * gl_in[2].gl_Position;\n"
        "}\n";
    static const char* geometry =
        "#version 320 es\n"
        "layout(triangles) in;\n"
        "layout(triangle_strip, max_vertices=3) out;\n"
        "void main() {\n"
        "  for (int i = 0; i < 3; ++i) {\n"
        "    gl_Position = gl_in[i].gl_Position; EmitVertex();\n"
        "  }\n"
        "  EndPrimitive();\n"
        "}\n";
    static const char* fragment =
        "#version 320 es\n"
        "precision highp float;\n"
        "layout(location=0) out vec4 color;\n"
        "void main() { color = vec4(0.25, 0.5, 0.75, 1.0); }\n";

    clearErrors(gl);
    const bool geometryPassed = runShaderPipeline(
        gl, "es32_geometry", {{GL_VERTEX_SHADER, vertex},
                               {GL_GEOMETRY_SHADER, geometry},
                               {GL_FRAGMENT_SHADER, fragment}});
    std::cout << "  functional_es32_geometry_pipeline="
              << (geometryPassed ? "pass" : "fail") << "\n";
    clearErrors(gl);
    const bool tessellationPassed = runShaderPipeline(
        gl, "es32_tessellation", {{GL_VERTEX_SHADER, vertex},
                                   {GL_TESS_CONTROL_SHADER, tessControl},
                                   {GL_TESS_EVALUATION_SHADER, tessEvaluation},
                                   {GL_FRAGMENT_SHADER, fragment}});
    std::cout << "  functional_es32_tessellation_pipeline="
              << (tessellationPassed ? "pass" : "fail") << "\n";
    clearErrors(gl);
    return geometryPassed && tessellationPassed;
}

}  // namespace

int main(int argc, char** argv) {
    if (argc != 4) {
        std::cerr << "usage: angle-egl-probe /path/libEGL.dylib "
                     "/path/libGLESv2.dylib default|metal|vulkan|opengl\n";
        return 2;
    }
    const std::string backend = argv[3];

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
    const auto eglGetPlatformDisplayFn =
        loadOptional<PFNEGLGETPLATFORMDISPLAYPROC>(eglLibrary, "eglGetPlatformDisplay");
    const auto eglGetProcAddressFn =
        load<PFNEGLGETPROCADDRESSPROC>(eglLibrary, "eglGetProcAddress");
    auto eglGetPlatformDisplayEXTFn =
        loadOptional<PFNEGLGETPLATFORMDISPLAYEXTPROC>(eglLibrary, "eglGetPlatformDisplayEXT");
    if (!eglGetPlatformDisplayEXTFn) {
        eglGetPlatformDisplayEXTFn = reinterpret_cast<PFNEGLGETPLATFORMDISPLAYEXTPROC>(
            eglGetProcAddressFn("eglGetPlatformDisplayEXT"));
    }
    const auto eglInitializeFn = load<PFNEGLINITIALIZEPROC>(eglLibrary, "eglInitialize");
    const auto eglQueryStringFn = load<PFNEGLQUERYSTRINGPROC>(eglLibrary, "eglQueryString");
    const auto eglBindAPIFn = load<PFNEGLBINDAPIPROC>(eglLibrary, "eglBindAPI");
    const auto eglChooseConfigFn = load<PFNEGLCHOOSECONFIGPROC>(eglLibrary, "eglChooseConfig");
    const auto eglCreatePbufferSurfaceFn =
        load<PFNEGLCREATEPBUFFERSURFACEPROC>(eglLibrary, "eglCreatePbufferSurface");
    const auto eglCreateContextFn =
        load<PFNEGLCREATECONTEXTPROC>(eglLibrary, "eglCreateContext");
    const auto eglMakeCurrentFn = load<PFNEGLMAKECURRENTPROC>(eglLibrary, "eglMakeCurrent");
    const auto eglDestroyContextFn =
        load<PFNEGLDESTROYCONTEXTPROC>(eglLibrary, "eglDestroyContext");
    const auto eglDestroySurfaceFn =
        load<PFNEGLDESTROYSURFACEPROC>(eglLibrary, "eglDestroySurface");
    const auto eglTerminateFn = load<PFNEGLTERMINATEPROC>(eglLibrary, "eglTerminate");
    const auto glGetStringFn = load<PFNGLGETSTRINGPROC>(glesLibrary, "glGetString");
    const auto glGetStringiFn = loadOptional<PFNGLGETSTRINGIPROC>(glesLibrary, "glGetStringi");
    const auto glGetIntegervFn = load<PFNGLGETINTEGERVPROC>(glesLibrary, "glGetIntegerv");
    const auto functionalGles = loadFunctionalGles(glesLibrary, eglGetProcAddressFn);
    auto eglQueryStringiANGLEFn =
        loadOptional<PFNEGLQUERYSTRINGIANGLEPROC>(eglLibrary, "eglQueryStringiANGLE");
    if (!eglQueryStringiANGLEFn) {
        eglQueryStringiANGLEFn = reinterpret_cast<PFNEGLQUERYSTRINGIANGLEPROC>(
            eglGetProcAddressFn("eglQueryStringiANGLE"));
    }
    auto eglQueryDisplayAttribANGLEFn =
        loadOptional<PFNEGLQUERYDISPLAYATTRIBANGLEPROC>(eglLibrary, "eglQueryDisplayAttribANGLE");
    if (!eglQueryDisplayAttribANGLEFn) {
        eglQueryDisplayAttribANGLEFn = reinterpret_cast<PFNEGLQUERYDISPLAYATTRIBANGLEPROC>(
            eglGetProcAddressFn("eglQueryDisplayAttribANGLE"));
    }

    std::cout << "backend=" << backend << "\n";
    std::cout << "ANGLE_FEATURE_OVERRIDES_ENABLED="
              << safe(std::getenv("ANGLE_FEATURE_OVERRIDES_ENABLED")) << "\n";
    std::cout << "EGL client extensions: "
              << safe(eglQueryStringFn(EGL_NO_DISPLAY, EGL_EXTENSIONS)) << "\n";

    const auto enabledOverrideNames =
        splitOverrides(std::getenv("ANGLE_FEATURE_OVERRIDES_ENABLED"));
    const auto disabledOverrideNames =
        splitOverrides(std::getenv("ANGLE_FEATURE_OVERRIDES_DISABLED"));
    const auto enabledOverridePointers = overridePointers(enabledOverrideNames);
    const auto disabledOverridePointers = overridePointers(disabledOverrideNames);

    EGLDisplay display = EGL_NO_DISPLAY;
    if (eglGetPlatformDisplayFn) {
        std::vector<EGLAttrib> displayAttributes = {
            EGL_PLATFORM_ANGLE_TYPE_ANGLE,
            backendType(backend),
        };
        if (!enabledOverrideNames.empty()) {
            displayAttributes.push_back(EGL_FEATURE_OVERRIDES_ENABLED_ANGLE);
            displayAttributes.push_back(reinterpret_cast<EGLAttrib>(
                enabledOverridePointers.data()));
        }
        if (!disabledOverrideNames.empty()) {
            displayAttributes.push_back(EGL_FEATURE_OVERRIDES_DISABLED_ANGLE);
            displayAttributes.push_back(reinterpret_cast<EGLAttrib>(
                disabledOverridePointers.data()));
        }
        displayAttributes.push_back(EGL_NONE);
        display = eglGetPlatformDisplayFn(
            EGL_PLATFORM_ANGLE_ANGLE, EGL_DEFAULT_DISPLAY, displayAttributes.data());
    } else if (eglGetPlatformDisplayEXTFn) {
        const EGLint displayAttributes[] = {
            EGL_PLATFORM_ANGLE_TYPE_ANGLE,
            backendType(backend),
            EGL_NONE,
        };
        display = eglGetPlatformDisplayEXTFn(
            EGL_PLATFORM_ANGLE_ANGLE, EGL_DEFAULT_DISPLAY, displayAttributes);
    }
    if (display == EGL_NO_DISPLAY && backend == "default") {
        printEglError(eglGetErrorFn, "eglGetPlatformDisplayEXT(default)");
        display = eglGetDisplayFn(EGL_DEFAULT_DISPLAY);
    }
    if (display == EGL_NO_DISPLAY) {
        printEglError(eglGetErrorFn, "display creation");
        return 1;
    }

    EGLint eglMajor = 0;
    EGLint eglMinor = 0;
    if (!eglInitializeFn(display, &eglMajor, &eglMinor)) {
        printEglError(eglGetErrorFn, "eglInitialize");
        return 1;
    }
    std::cout << "EGL=" << eglMajor << "." << eglMinor
              << " vendor='" << safe(eglQueryStringFn(display, EGL_VENDOR))
              << "' version='" << safe(eglQueryStringFn(display, EGL_VERSION))
              << "' client_apis='" << safe(eglQueryStringFn(display, EGL_CLIENT_APIS))
              << "'\n";
    if (eglQueryStringiANGLEFn && eglQueryDisplayAttribANGLEFn) {
        EGLAttrib featureCount = 0;
        if (eglQueryDisplayAttribANGLEFn(
                display, EGL_FEATURE_COUNT_ANGLE, &featureCount)) {
            std::cout << "ANGLE features=" << featureCount << "\n";
            for (EGLint index = 0; index < featureCount; ++index) {
                const char* name = eglQueryStringiANGLEFn(
                    display, EGL_FEATURE_NAME_ANGLE, index);
                if (!name) {
                    continue;
                }
                const std::string featureName(name);
                if (featureName.find("expose") == std::string::npos
                    && featureName.find("ES3") == std::string::npos
                    && featureName.find("metal") == std::string::npos
                    && featureName.find("Metal") == std::string::npos) {
                    continue;
                }
                std::cout << "  feature " << featureName << " status="
                          << safe(eglQueryStringiANGLEFn(
                                 display, EGL_FEATURE_STATUS_ANGLE, index))
                          << "\n";
            }
        }
    }

    if (!eglBindAPIFn(EGL_OPENGL_ES_API)) {
        printEglError(eglGetErrorFn, "eglBindAPI");
        eglTerminateFn(display);
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
    if (!eglChooseConfigFn(display, configAttributes, &config, 1, &configCount)
        || configCount == 0) {
        printEglError(eglGetErrorFn, "eglChooseConfig(ES3 pbuffer)");
        eglTerminateFn(display);
        return 1;
    }

    const EGLint surfaceAttributes[] = {EGL_WIDTH, 16, EGL_HEIGHT, 16, EGL_NONE};
    EGLSurface surface = eglCreatePbufferSurfaceFn(display, config, surfaceAttributes);
    if (surface == EGL_NO_SURFACE) {
        printEglError(eglGetErrorFn, "eglCreatePbufferSurface");
        eglTerminateFn(display);
        return 1;
    }

    struct Version { EGLint major; EGLint minor; };
    const std::vector<Version> versions = {{3, 2}, {3, 1}, {3, 0}};
    int successfulContexts = 0;
    int functionalFailures = 0;
    for (const auto version : versions) {
        const EGLint contextAttributes[] = {
            EGL_CONTEXT_MAJOR_VERSION_KHR, version.major,
            EGL_CONTEXT_MINOR_VERSION_KHR, version.minor,
            EGL_NONE,
        };
        EGLContext context = eglCreateContextFn(
            display, config, EGL_NO_CONTEXT, contextAttributes);
        std::cout << "request=ES" << version.major << "." << version.minor << "\n";
        if (context == EGL_NO_CONTEXT) {
            printEglError(eglGetErrorFn, "eglCreateContext");
            continue;
        }
        if (!eglMakeCurrentFn(display, surface, surface, context)) {
            printEglError(eglGetErrorFn, "eglMakeCurrent");
            eglDestroyContextFn(display, context);
            continue;
        }
        ++successfulContexts;

        GLint actualMajor = 0;
        GLint actualMinor = 0;
        GLint extensionCount = 0;
        glGetIntegervFn(GL_MAJOR_VERSION, &actualMajor);
        glGetIntegervFn(GL_MINOR_VERSION, &actualMinor);
        glGetIntegervFn(GL_NUM_EXTENSIONS, &extensionCount);
        std::cout << "  actual=ES" << actualMajor << "." << actualMinor
                  << " version='" << glString(glGetStringFn, GL_VERSION)
                  << "' glsl='" << glString(glGetStringFn, GL_SHADING_LANGUAGE_VERSION)
                  << "'\n";
        std::cout << "  vendor='" << glString(glGetStringFn, GL_VENDOR)
                  << "' renderer='" << glString(glGetStringFn, GL_RENDERER)
                  << "' extensions=" << extensionCount << "\n";

        const char* requiredExtensions[] = {
            "GL_EXT_geometry_shader",
            "GL_EXT_tessellation_shader",
            "GL_EXT_gpu_shader5",
            "GL_EXT_texture_buffer",
            "GL_KHR_debug",
            "GL_OES_geometry_shader",
            "GL_OES_tessellation_shader",
        };
        std::cout << "  selected_extensions:";
        for (const char* extension : requiredExtensions) {
            std::cout << " " << extension << "="
                      << (containsExtension(glGetStringiFn, extensionCount, extension)
                              ? "yes" : "no");
        }
        std::cout << "\n";

        const char* requiredFunctions[] = {
            "glDispatchCompute",
            "glBindImageTexture",
            "glMemoryBarrier",
            "glTexStorage3DMultisample",
            "glPatchParameteri",
            "glFramebufferTexture",
            "glDebugMessageCallback",
            "glPrimitiveBoundingBox",
        };
        std::cout << "  entrypoints:";
        for (const char* function : requiredFunctions) {
            const bool available = dlsym(glesLibrary, function)
                || eglGetProcAddressFn(function);
            std::cout << " " << function << "=" << (available ? "yes" : "no");
        }
        std::cout << "\n";

        if (actualMajor > 3 || (actualMajor == 3 && actualMinor >= 1)) {
            const bool passed = runComputeSsboTest(functionalGles);
            std::cout << "  functional_compute_ssbo="
                      << (passed ? "pass" : "fail") << "\n";
            functionalFailures += passed ? 0 : 1;
            const bool imagePassed = runImageLoadStoreTest(functionalGles);
            std::cout << "  functional_image_load_store="
                      << (imagePassed ? "pass" : "fail") << "\n";
            functionalFailures += imagePassed ? 0 : 1;
            const bool syncPassed = runSyncTest(functionalGles);
            std::cout << "  functional_sync="
                      << (syncPassed ? "pass" : "fail") << "\n";
            functionalFailures += syncPassed ? 0 : 1;
        }
        if (actualMajor > 3 || (actualMajor == 3 && actualMinor >= 2)) {
            const bool passed = runTextureBufferTest(functionalGles);
            std::cout << "  functional_texture_buffer="
                      << (passed ? "pass" : "fail") << "\n";
            functionalFailures += passed ? 0 : 1;
            GLint maxGeometryOutputVertices = 0;
            GLint maxPatchVertices = 0;
            GLint maxTessGenLevel = 0;
            glGetIntegervFn(GL_MAX_GEOMETRY_OUTPUT_VERTICES, &maxGeometryOutputVertices);
            glGetIntegervFn(GL_MAX_PATCH_VERTICES, &maxPatchVertices);
            glGetIntegervFn(GL_MAX_TESS_GEN_LEVEL, &maxTessGenLevel);
            std::cout << "  es32_limits: max_geometry_output_vertices="
                      << maxGeometryOutputVertices
                      << " max_patch_vertices=" << maxPatchVertices
                      << " max_tess_gen_level=" << maxTessGenLevel << "\n";
            const bool stagesPassed = runEs32ShaderStageTests(functionalGles);
            std::cout << "  functional_es32_shader_stages="
                      << (stagesPassed ? "pass" : "fail") << "\n";
            functionalFailures += stagesPassed ? 0 : 1;
        }

        eglMakeCurrentFn(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        eglDestroyContextFn(display, context);
    }

    eglDestroySurfaceFn(display, surface);
    eglTerminateFn(display);
    dlclose(eglLibrary);
    dlclose(glesLibrary);
    return successfulContexts == 0 || functionalFailures != 0 ? 1 : 0;
}
