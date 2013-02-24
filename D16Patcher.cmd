@PROMPT PROMPT$G
@ECHO DIR = %0
IF EXIST D16Patcher.res  DEL D16Patcher.res
BRCC32.exe -m -foD16Patcher.res D16Patcher.rc
IF ERRORLEVEL 1   PAUSE
EXIT
