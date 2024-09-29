@echo off
cd %~p0\edk2
call build.bat -t VS2015x86 -a IA32 -p %WORKSPACE%\overrides\EmulatorPkg\EmulatorPkg.dsc -b DEBUG
echo ##################################################################################
echo ###                                                                            ###
echo ### enter "BLDEMU"               to build the original tianocore EDK2EMULATOR  ###
echo ###                                                                            ###
echo ### enter "RUNEMU /DEBUG"        to start debugging of EDK2EMULATOR build      ###
echo ###                                                                            ###
echo ### enter "rd /s /q build" to clean previous build                             ###
echo ###                                                                            ###
echo ##################################################################################

:EOF