pushd .

set DDKROOTDIR=%~dp0\Tools\EWDK_1703\
set VCINSTALLDIR=%DDKROOTDIR%Program Files\Microsoft Visual Studio 14.0\VC\
set VS140COMNTOOLS=%VCINSTALLDIR%\..\Common7\Tools\
set INCLUDE=%DDKROOTDIR%Program Files\Windows Kits\10\Include\10.0.15063.0\ucrt\
set INCLUDE=%INCLUDE%;%DDKROOTDIR%Program Files\Microsoft Visual Studio 14.0\VC\include\
set INCLUDE=%INCLUDE%;%DDKROOTDIR%Program Files\Windows Kits\10\Include\10.0.15063.0\um\
set INCLUDE=%INCLUDE%;%DDKROOTDIR%Program Files\Windows Kits\10\Include\10.0.15063.0\shared;
set LIB=%DDKROOTDIR%Program Files\Microsoft Visual Studio 14.0\VC\lib\amd64\;%DDKROOTDIR%Program Files\Windows Kits\10\Lib\10.0.15063.0\um\x64\;%DDKROOTDIR%Program Files\Windows Kits\10\Lib\10.0.15063.0\ucrt\x64\

call %DDKROOTDIR%LaunchBuildEnv.cmd amd64

popd

rem
rem automatically create MSCFINTRINx86-64.lib 
rem 

rem cleanup TEMP directory
set DELETE=lldiv.obj lldvrm.obj llmul.obj llrem.obj llshl.obj llshr.obj ulldiv.obj ulldvrm.obj ullrem.obj ullshr.obj _ftol2.obj _ftol3_.obj memcpy.obj memcmp.obj memset.obj __isa_available.obj
for %%d in (%DELETE%) do (
    if exist %TEMP%\%%d (
        attrib -r %TEMP%\%%d
        del %TEMP%\%%d
    )
)

rem find LIBCMT.LIB, create environment variable LIBCMT_LIB
set PATHORG=%PATH%
set PATH=%LIB%,%PATHORG%
for /F "delims=" %%p in ('where LIBCMT.LIB') do set LIBCMT_LIB="%%p"
set PATH=%PATHORG%
echo MICROSOFT C LIBRARY found: %LIBCMT_LIB%

rem rem
rem rem isolate INT64 intrinsics, need leading "\" to differtiate ll*.obj from ull*.obj
rem rem extract *.obj to %TEMP%
rem rem 
rem set OBJS=lldiv.obj lldvrm.obj llmul.obj llrem.obj llshl.obj llshr.obj ulldiv.obj ulldvrm.obj ullrem.obj ullshr.obj _ftol2_.obj _ftol3_.obj
rem echo 1234
rem for  %%o in (%OBJS%) do (
rem 
rem     for /F %%f in ('lib /nologo /list %LIBCMT_LIB% ^| find "\%%o"') do (
rem         lib /nologo /extract:%%f %LIBCMT_LIB% /out:%TEMP%\%%o
rem     )
rem )

rem
rem create runtime/ISA switches for Microsoft _ftol2_.obj, _ftol3_.obj
rem
echo unsigned __isa_available=2; > %temp%\__isa_available.c

rem
rem create MEMCPY.c
rem
ECHO #if   defined(_M_AMD64)                                                             > %temp%\memcpy.c
ECHO     typedef unsigned long long size_t;                                              >> %temp%\memcpy.c
ECHO #else                                                                               >> %temp%\memcpy.c
ECHO     typedef unsigned int size_t;                                                    >> %temp%\memcpy.c
ECHO #endif                                                                              >> %temp%\memcpy.c
ECHO void* memcpy(void* s1, const void* s2, size_t n) {                                  >> %temp%\memcpy.c
ECHO     size_t i;                                                                       >> %temp%\memcpy.c
ECHO     for (i = 0; i ^< n; i++) {                                                      >> %temp%\memcpy.c
ECHO         ((unsigned char*)s1)[i] = ((unsigned char*)s2)[i];                          >> %temp%\memcpy.c
ECHO     }                                                                               >> %temp%\memcpy.c
ECHO     return s1;                                                                      >> %temp%\memcpy.c
ECHO }                                                                                   >> %temp%\memcpy.c

rem
rem create MEMCMP.c
rem
ECHO #if   defined(_M_AMD64)                                                             > %temp%\memcmp.c
ECHO     typedef unsigned long long size_t;                                              >> %temp%\memcmp.c
ECHO #else                                                                               >> %temp%\memcmp.c
ECHO     typedef unsigned int size_t;                                                    >> %temp%\memcmp.c
ECHO #endif                                                                              >> %temp%\memcmp.c
ECHO int memcmp(void* s1, const void* s2, size_t n) {                                    >> %temp%\memcmp.c
ECHO     int nRet = 0;                                                                   >> %temp%\memcmp.c
ECHO     size_t i;                                                                       >> %temp%\memcmp.c
ECHO     for (i = 0; i ^< n; i++)                                                        >> %temp%\memcmp.c
ECHO         if(((unsigned char*)s1)[i] != ((unsigned char*)s2)[i])                      >> %temp%\memcmp.c
ECHO         {                                                                           >> %temp%\memcmp.c
ECHO             nRet = ((unsigned char*)s1)[i] ^< ((unsigned char*)s2)[i] ? -1 : +1;    >> %temp%\memcmp.c
ECHO             break;                                                                  >> %temp%\memcmp.c
ECHO         }                                                                           >> %temp%\memcmp.c
ECHO     return nRet;                                                                    >> %temp%\memcmp.c
ECHO }                                                                                   >> %temp%\memcmp.c

rem
rem create MEMSET.c
rem
ECHO #if   defined(_M_AMD64)                                                             > %temp%\memset.c
ECHO     typedef unsigned long long size_t;                                              >> %temp%\memset.c
ECHO #else                                                                               >> %temp%\memset.c
ECHO     typedef unsigned int size_t;                                                    >> %temp%\memset.c
ECHO #endif                                                                              >> %temp%\memset.c
ECHO void* memset(void* s, int c, size_t n) {                                            >> %temp%\memset.c
ECHO     unsigned char* p;                                                               >> %temp%\memset.c
ECHO     size_t i;                                                                       >> %temp%\memset.c
ECHO     for (i = 0, p = (unsigned char*)s; i ^< n; i++)                                 >> %temp%\memset.c
ECHO         p[i] = (unsigned char)c;                                                    >> %temp%\memset.c
ECHO     return s;                                                                       >> %temp%\memset.c
ECHO }                                                                                   >> %temp%\memset.c

rem
rem build the sourcecode
rem
for %%f in (__isa_available.c _fltused.c memcmp.c memcpy.c memset.c) do (
    echo cl /nologo /c /O1 /Fo:%temp%\%%~nf.obj %temp%\%%f
    cl /nologo /c /O1 /Fo:%temp%\%%~nf.obj %temp%\%%f
)

pushd %temp%
set OBJS=%OBJS% memcpy.obj memcmp.obj memset.obj __isa_available.obj _fltused.obj

echo lib /nologo %OBJS% /out:%~dp0\EDK2\CONF\MSFTINTRINX86-64.lib
lib /nologo %OBJS% /out:%TEMP%\MSFTINTRINX86-64.lib

move %TEMP%\MSFTINTRINX86-64.lib %~dp0\EDK2\CONF\MSFTINTRINX86-64.lib

popd

echo lib /nologo /list %~dp0\EDK2\CONF\MSFTINTRINX86-64.lib
lib /nologo /list %~dp0\EDK2\CONF\MSFTINTRINX86-64.lib

for %%e in (OBJS DELETE PATHORG) do set %%e=

