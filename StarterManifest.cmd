@PROMPT PROMPT$G
@ECHO DIR = %0
IF EXIST StarterManifest.res  DEL StarterManifest.res
BRCC32.exe -m -foStarterManifest.res StarterManifest.rc
IF ERRORLEVEL 1   PAUSE
EXIT
