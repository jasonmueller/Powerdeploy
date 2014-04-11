powershell -NoProfile -Command "Import-Module %~dp0PowerDeploy.psm1; Invoke-Powerdeploy %*; Remove-Module PowerDeploy"

exit /b %ERRORLEVEL%

