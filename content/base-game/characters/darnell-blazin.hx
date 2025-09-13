import haxe.ds.StringMap;

var noteHitActions = new StringMap();
var noteMissActions = new StringMap();

var intendedChar = dad;
var intendedGrp = dadGroup;

function onCreatePost(){
    intendedChar.canDance = false;

    for(i in ['blockhigh', 'blockspin', 'dodgehigh', 'dodgespin', 'hithigh', 'hitspin'])
        noteHitActions.set(i, playPunchHighAnim);
    for(i in ['blocklow', 'dodgelow', 'hitlow'])
        noteHitActions.set(i, playPunchLowAnim);
    for(i in ['punchlowblocked', 'punchhighblocked'])
        noteHitActions.set(i, playBlockAnim);
    for(i in ['punchlowdodged', 'punchhighdodged'])
        noteHitActions.set(i, playDodgeAnim);
    for(i in ['punchlowspin', 'punchhighspin'])
        noteHitActions.set(i, playHitSpinAnim);
    noteHitActions.set('punchhigh', playHitHighAnim);
    noteHitActions.set('punchlow', playHitLowAnim);
    noteHitActions.set('darnelluppercutprep', playUppercutPrepAnim);
    noteHitActions.set('darnelluppercut', playUppercutAnim);
    noteHitActions.set('picouppercut', playUppercutHitAnim);
    noteHitActions.set('idle', playIdleAnim);
    noteHitActions.set('fakeout', playCringeAnim);
    noteHitActions.set('taunt', playPissedConditionalAnim);
    noteHitActions.set('tauntforce', playPissedAnim);
    noteHitActions.set('reversefakeout', playFakeoutAnim);

    for(i in ['punchlow', 'punchlowblocked', 'punchlowdodged', 'blocklow', 'dodgelow', 'hitlow'])
        noteMissActions.set(i, playPunchLowAnim);
    for(i in ['punchhigh', 'punchhighblocked', 'punchhighdodged', 'blockhigh', 'dodgehigh', 'hithigh', 'fakeout', 'punchlowspin', 'punchhighspin', 'blockspin', 'hitspin'])
        noteMissActions.set(i, playPunchHighAnim);
    noteMissActions.set('taunt', playPissedConditionalAnim);
    noteMissActions.set('tauntforce', playPissedAnim);

}

var alternate:Bool = false;
function doAlternate(){
    alternate = !alternate;
    return alternate ? '1' : '2';
}

function moveToFront(){
    intendedGrp.zIndex = 3000;
    refreshZ(stage);
}

function moveToBack(){
    intendedGrp.zIndex = 2000;
    refreshZ(stage);
}

function playIdleAnim(){
    intendedChar.playAnim('idle', true);
    moveToBack();
}
function playPunchHighAnim(){
    intendedChar.playAnim('punchHigh' + doAlternate(), true);
    moveToFront();
}

function playPunchLowAnim(){
    intendedChar.playAnim('punchLow' + doAlternate(), true);
    moveToFront();
}

function playHitHighAnim(){
    intendedChar.playAnim('hitHigh', true);
    camGame.shake(0.0025, 0.15);
    moveToBack();
}

function playHitLowAnim(){
    intendedChar.playAnim('hitLow', true);
    camGame.shake(0.0025, 0.15);
    moveToBack();
}

function playHitSpinAnim(){
    intendedChar.playAnim('hitSpin', true);
    camGame.shake(0.0025, 0.15);
    moveToBack();
}

function playBlockAnim(){
    intendedChar.playAnim('block', true);
    camGame.shake(0.002, 0.1);
    moveToBack();
}

function playDodgeAnim(){
    intendedChar.playAnim('dodge', true);
    moveToBack();
}

function playUppercutPrepAnim(){
    intendedChar.playAnim('uppercutPrep', true);
    moveToFront();
}

function playUppercutAnim(){
    intendedChar.playAnim('uppercut', true);
    camGame.shake(0.005, 0.25);
    moveToFront();
}

function playUppercutHitAnim(){
    intendedChar.playAnim('uppercutHit', true);
    camGame.shake(0.005, 0.25);
    moveToBack();
}


function playCringeAnim(){
    intendedChar.playAnim('cringe', true);
    moveToBack();
}

function playFakeoutAnim(){
    intendedChar.playAnim('fakeout', true);
    moveToBack();
}

function playPissedAnim(){
    intendedChar.playAnim('pissed', true);
    moveToBack();
}

function playPissedConditionalAnim(){
    if(intendedChar.getAnimName() == 'cringe') playPissedAnim();
    else playIdleAnim();
}

// note stuff
function goodNoteHit(note){
    if(note.noteType == 'picouppercutprep') return;
    
    var action = noteHitActions.get(note.noteType);
    action();
}

function opponentNoteHit(note){
    var action = noteHitActions.get(note.noteType);
    action();
}

function noteMiss(note){
    var action = noteMissActions.get(note.noteType);
    action();
}