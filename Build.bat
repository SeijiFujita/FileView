@echo off
rem path=C:\D\dmd.2.069.2\windows\bin;C:\D\bin;
rem path=C:\D\dmd.2.070.2\windows\bin;C:\D\bin;
rem path=C:\D\dmd.2.071.2\windows\bin;C:\D\bin;
set path=C:\Dev\D\dmd.2.071.2\windows\bin;C:\Dev\D\Bin;

@echo on

dmd --version
rem dmd @dwtlib_normal.txt
rem dmd @dwt64lib_normal.txt

dmd @buildcf.txt

@if ERRORLEVEL 1 goto :eof

rem FileView01 C:\D\rakugaki
rem FileView64
copy bin\FileView64.exe C:\Dev\D\bin

echo done...
goto :eof
-----------------------------------
