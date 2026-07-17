@echo off
cd ../
cd .haxelib/lime/git/
git submodule sync --recursive
git submodule update --init --recursive --force
cd ../../../
haxelib run lime rebuild cpp -clean

echo:
echo Finished rebuilding lime
pause
