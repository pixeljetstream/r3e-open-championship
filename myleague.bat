%~dp0\luajit.exe %~dp0/r3e-open-championship.lua -addrace %~dp0/results/%~n0.lua %1 -makehtml %~dp0/results/%~n0.lua %~dp0/results/%~n0.html
start "" %~dp0/results/%~n0.html
pause