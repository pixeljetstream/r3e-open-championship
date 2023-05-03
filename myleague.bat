cd %~dp0
luajit.exe r3e-open-championship.lua -addrace ./results/%~n0.lua %1 -makehtml ./results/%~n0.lua ./results/%~n0.html
start "" ./results/%~n0.html
pause