@echo off 
cls 

rem ###################################################### 
rem # Batch-Datei fuer den kskscanner                    # 
rem ###################################################### 

echo Erstellen der aktuellen Statistiken: Dazu einfach beliebige RB-Webseiten als .html Dateien im gleichen Verzeichnis speichern.
echo.
kskscanner.exe *.html
echo.
echo.

pause 
