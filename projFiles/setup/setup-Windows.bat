@echo off
cd ../..
cd

ECHO hi :)

if not exist .haxelib\ (
    ECHO:
    ECHO missing .haxelib folder. Making one
    mkdir .haxelib\
)

ECHO:
ECHO downloading core libraries
haxelib install lime 8.1.3
haxelib install openfl 9.4.1
haxelib install flixel 6.0.0 --skip-dependencies
haxelib install flixel-addons 3.3.2 --skip-dependencies
haxelib install flixel-ui 2.6.4 --skip-dependencies
haxelib install hscript-iris 1.1.3
haxelib git flixel-animate https://github.com/MaybeMaru/flixel-animate d446dfa061b1ea5959e82bc94dcaee8135c565a1 --skip-dependencies

ECHO:
ECHO Download cpp specific libraries
haxelib git hxcpp https://github.com/HaxeFoundation/hxcpp 8268ef2d518b1e7c8e8494114d0bdf6b5bc4147d
haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc 2d83fa863ef0c1eace5f1cf67c3ac315d1a3a8a5 --skip-dependencies
haxelib git hxvlc https://github.com/MAJigsaw77/hxvlc a1ac9900248209a91a9a9c1ebc1ae8af5dfdfb86 --skip-dependencies
haxelib install hxcpp-debug-server 1.2.4

ECHO:
ECHO Downloading Haxe-UI
haxelib git haxeui-core https://github.com/haxeui/haxeui-core 99d5d035e7120ce027256b117a25625c53b488dc
haxelib git haxeui-flixel https://github.com/haxeui/haxeui-flixel b899a4c7d7318c5ff2b1bb645fbc73728fad1ac9 --skip-dependencies

ECHO:
ECHO etc
haxelib install hscript 2.6.0
haxelib git moonchart https://github.com/MaybeMaru/moonchart 8c9d7cfe3280588fa71a8f3c4444c97bc7b63714

haxelib git funkin.vis https://github.com/FunkinCrew/funkVis 1966f8fbbbc509ed90d4b520f3c49c084fc92fd6
haxelib git grig.audio https://github.com/FunkinCrew/grig.audio 8567c4dad34cfeaf2ff23fe12c3796f5db80685e

haxelib git json2object https://github.com/FunkinCrew/json2object a8c26f18463c98da32f744c214fe02273e1823fa

haxelib install hxjsonast 1.1.0

ECHO:
ECHO Finished installing libraries woo!
pause
