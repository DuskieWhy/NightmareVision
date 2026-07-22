@echo off
cd ../

IF EXIST ".haxelib" (
    ECHO .haxelib already exists deleting
    rmdir /s /q ".haxelib"
    ECHO deleted existed .haxelib directory. Beginning setup
)

haxelib install hxpkg
haxelib run hxpkg install

cd .haxelib/lime/git/
git submodule sync --recursive
git submodule update --init --recursive --force
cd ../../../
haxelib run lime rebuild cpp -release

ECHO Clean setup complete.

pause