@echo off
rem path=C:\D\dmd.2.069.2\windows\bin;C:\D\bin;
rem path=C:\D\dmd.2.070.2\windows\bin;C:\D\bin;
rem path=C:\D\dmd.2.071.2\windows\bin;C:\D\bin;

@echo on

rem dmd @dwtlib_normal.txt
dmd @dwt64lib_normal.txt
@if ERRORLEVEL 1 goto :eof
del *.obj

rem FileView01 C:\D\rakugaki
FileView64

echo done...
goto :eof
