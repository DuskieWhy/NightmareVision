import funkin.states.editors.HScriptState;

/**

    Scripted states follow the same documentation as other states, but changing to them is a little different.
    Make SURE that you import HScriptState (as shown above) if you want to access the state!
    
        Example of switching:
         FlxG.switchState(new HscriptState('StateName'));

**/

function create(){}

function update(elapsed){}

function beatHit(curBeat){ trace(curBeat); }

function stepHit(curStep){ trace(curStep); }