@rem C:\Program Files\Microsoft SDKs\Windows\v6.0A\bin\rc" /foresource.res resource.rc
@"C:\Program Files (x86)\Windows Kits\8.1\bin\x86\rc" /foresource.res resource.rc
@if errorlevel 1 (
	echo Building failed!
	pause
)
