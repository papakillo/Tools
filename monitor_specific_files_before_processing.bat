@echo off
setlocal enabledelayedexpansion
rem author: Benjamin Ohene-Adu
rem Ben.aduohene@gmail.com
rem 21st May 2024
rem Description: This script monitors specific files before running a SQL Server Agent job. The script will wait for the    

:: Set variables
set "folderPath=\\bhxappfs01\InhouseApps\UAT\Blue Yonder\Outbound"  REM Path to the folder to monitor
set "ssisJobName=Dashboard_CostPriceDeltaOutput"  REM Name of the SQL Server Agent job

:: File patterns to look for
set "patterns=PMM_DB_IB01_ PMM_DB_IB02_ PMM_DB_ADJ_ PMM_DB_BR02_"

:loop
:: Initialize an array to keep track of found files
set "foundFiles= "

:: Loop through the file patterns and find the most recent files
for %%P in (%patterns%) do (
    set "mostRecentFile="
    for /f "delims=" %%F in ('dir /b /o-d "%folderPath%\%%P" 2^>nul') do (
        if not defined mostRecentFile (
            set "mostRecentFile=%%F"
            set "foundFiles=!foundFiles! %%F"
        )
    )
)

:: Check if all four files are found
for %%P in (%patterns%) do (
    echo Looking for %%P...
    if not "!foundFiles: %%P=!"=="" (
        echo %%P found.
    ) else (
        echo %%P not found. Waiting for all files...
        goto continueWaiting
    )
)

:: All four files are found; trigger the SSIS job
echo All required files found. Triggering the SSIS job...
sqlcmd -S JUNEAU -Q "EXEC msdb.dbo.sp_start_job @job_name = '%ssisJobName%'"

:continueWaiting
:: Pause for a specified time (e.g., 5 minutes)
timeout /t 300 > nul
goto loop
