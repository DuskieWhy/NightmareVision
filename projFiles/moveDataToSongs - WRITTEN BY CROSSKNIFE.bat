
@echo off
    :main
    cls
    color 0a
    cd %~dp0
    echo SCRIPT BY CROSSKNIFE
    echo ---------------------------------------------------------------------------------------------------------------------
    cd ..

    if exist content\ (
        echo Content Folder EXISTS
        cd content
        echo.
        goto :ask
    ) else (
        echo Content Folder DOES NOT EXIST
        echo.
        echo Dude what the fuck where is your content Folder this isnt funny i got a job here
        echo place this inside Projfiles or the content folder itself then relaunch
        pause
        exit
    )
    pause

:ask
    echo Mods
    echo ---------------
    dir /b
    echo.
    set /p mod=folder: 
    echo.
    echo "%mod%"
    if exist %mod%/ (
        echo Ok you didnt troll
        TIMEOUT 1 > nul
        echo Now... lets go...
        TIMEOUT 3 > nul
        goto :newvision
    ) else (
        echo stop trolling
        TIMEOUT 1 > nul
        echo Lets do this again
        TIMEOUT 3 > nul
        cls
        goto :ask
    )

:newvision
    cls
    cd %mod%
    SET src_folder=data
    SET tar_folder=songs
    echo %src_folder%
    echo %tar_folder%
    for /f %%a IN ('dir "%src_folder%" /b') do (
        echo "%%a"
        move "%src_folder%\%%a\*" "%tar_folder%\%%a" > nul
    )
    for /f %%a IN ('dir "%src_folder%" /b') do (
        echo "%%a"
        rd "%src_folder%\%%a%" > nul
    )
    rd data
    echo We done
    pause
    exit

:troll
    echo no charts here blud...
    pause
    exit