#!/bin/sh
# literally just compile.bat but for mac and linux.
cd ..
echo INSTALLING LIBRARIES
haxelib set hxcpp 4.3.2
haxelib set lime 8.1.1
haxelib set openfl 9.2.2
haxelib set flixel-addons 2.10.0
haxelib set flixel-tools 1.5.1
haxelib set flixel-ui 2.5.0
haxelib set flixel 5.2.2
haxelib set hscript 2.5.0
haxelib set hxvlc 1.2.0
haxelib set away3d 5.0.9
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit
haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc.git
echo BUILDING GAME
lime test cpp
echo.
echo done.
