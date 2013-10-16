powershell -NoProfile -Command "Import-Module %~dp0PowerDeploy.psm1; Publish-Package %*; Remove-Module PowerDeploy"

exit /b %ERRORLEVEL%

