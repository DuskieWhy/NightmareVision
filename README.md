helloe we hit single

Havee fun with NightmareVision V1! (***[follow me on twitter](https://twitter.com/DuskieWhy)***)

![](https://github.com/DuskieWhy/NightmareVision/blob/V1/assets/game/images/branding/NMV.png)

## Special thanks to...

* ShadowMario and Co. for [Psych engine](https://github.com/ShadowMario/FNF-PsychEngine)

* Nebula_Zorua for the [specific Psych fork](https://github.com/nebulazorua/exe-psych-fork) NMV is built off and for the Modchart backend

* Rozebud for the chart editor little buddies ([Check out their engine too](https://github.com/ThatRozebudDude/FPS-Plus-Public))

* Cne crew for camera rotation support ([Check out codename engine](https://github.com/CodenameCrew/CodenameEngine))

* MaybeMaru for [MoonChart](https://github.com/MaybeMaru/moonchart) and [Flixel-Animate](https://github.com/MaybeMaru/flixel-animate)


## How to compile NMV Engine

### Quick Note
- Haxe 4.3.6 or newer is expected
- This engine ENFORCES the use of local libraries with hxpkg/hmm to prevent issues in relation to `hxvlc`
- The expected library versions are listed within the .hxpkg file. 

if compilation errors arise, Ensure your Haxe version is correct and your haxelibs match what is listed in the .hxpkg file

### Download the prerequisites... (skip this if you already have compiled any fnf project, or any flixel project basically lol)

[Haxe](https://haxe.org/download/)

[Git](https://git-scm.com/downloads)

[VS Community](https://visualstudio.microsoft.com/vs/community/)

within the VS Community Installer, download `Desktop development with c++`

### Download the projects required libraries...

In a cmd within the project directory, in order run...

> haxelib install hxpkg

> haxelib run hxpkg setup

> haxelib run hxpkg install

After that is complete, run `lime test windows` and you should be compiling
