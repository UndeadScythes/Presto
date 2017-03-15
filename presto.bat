@echo off
rem Echo off - we don't need to see the commands we're running.

echo Running Presto Server startup script v1.0

rem Set some vars for the trip, hopefully makes things a little easier.
set src_dir=%CD%\src
set config_file=%CD%\configs\presto_config.json

rem Change into our working directory and run the script.
set presto_root=%CD%
cd %src_dir%

rem Open a loop to run the server in so we can restart from source if necessary.
:server_loop

    rem Log the start and end times in seconds.
    set /a start_time=((((%DATE:~7,2%*24+%TIME:~0,2%*60)+%TIME:~3,2%)*60+%TIME:~6,2%)*100+%TIME:~9,2%)*10
    ruby presto.rb -v -c %config_file% -r %presto_root%
    set /a end_time=((((%DATE:~7,2%*24+%TIME:~0,2%*60)+%TIME:~3,2%)*60+%TIME:~6,2%)*100+%TIME:~9,2%)*10

    rem Try to detect load fails.
    echo Started at: %start_time%
    echo Ended at  : %end_time%
    set /a run_time=%end_time%-%start_time%
    echo Uptime    : %run_time%ms
    if not "%end_time%"=="" (
        if %run_time% leq 5000 (
            set /p dummy="Startup fail detected"
            goto server_loop
        ) else (
            echo Restarting server
            goto server_loop
        )
    ) else (
        echo Bad uptime so restarting server
        goto server_loop
    )

rem Await user response so we can see any errors before the shell closes.
set /p dummy="Server loop terminated"