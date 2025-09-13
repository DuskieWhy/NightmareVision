import haxe.ds.StringMap;

var noteHitActions = new StringMap();
var noteMissActions = new StringMap();

var intendedChar = boyfriend;
var intendedGrp = boyfriendGroup;

function onCreatePost(){
    intendedChar.canDance = false;

    for(i in ['punchlow', 'punchlowblocked', 'punchlowdodged', 'punchlowspin'])
        noteHitActions.set(i, playPunchLowAnim);
    for(i in ['punchhigh', 'punchhighblocked', 'punchhighdodged', 'punchhighspin'])
        noteHitActions.set(i, playPunchHighAnim);
    for(i in ['blockhigh', 'blocklow', 'blockspin'])
        noteHitActions.set(i, playBlockAnim);
    for(i in ['dodgehigh', 'dodgelow', 'dodgespin'])
        noteHitActions.set(i, playDodgeAnim);
    for(i in ['darnelluppercutprep', 'idle', 'reversefakeout'])
        noteHitActions.set(i, playIdleAnim);
    noteHitActions.set('hithigh', playHitHighAnim);
    noteHitActions.set('hitlow', playHitLowAnim);
    noteHitActions.set('hitspin', playHitSpinAnim);
    noteHitActions.set('picouppercutprep', playUppercutPrepAnim);
    noteHitActions.set('picouppercut', playUppercutAnim);
    noteHitActions.set('darnelluppercut', playUppercutHitAnim);
    noteHitActions.set('fakeout', playFakeoutAnim);
    noteHitActions.set('taunt', playTauntConditionalAnim);
    noteHitActions.set('tauntforce', playTauntAnim);

    for(i in ['punchlow', 'punchlowblocked', 'punchlowdodged', 'blocklow', 'dodgelow', 'hitlow'])
        noteMissActions.set(i, playHitLowAnim);
    for(i in ['punchhigh', 'punchhighblocked', 'punchhighdodged', 'blockhigh', 'dodgehigh', 'hithigh', 'fakeout'])
        noteMissActions.set(i, playHitHighAnim);
    for(i in ['punchlowspin', 'punchhighspin', 'blockspin', 'hitspin'])
        noteMissActions.set(i, playHitSpinAnim);
    for(i in ['darnelluppercutprep', 'idle', 'reversefakeout'])
        noteMissActions.set(i, playIdleAnim);
    noteMissActions.set('taunt', playTauntConditionalAnim);
    noteMissActions.set('tauntforce', playTauntAnim);
}

var alternate:Bool = false;
function doAlternate(){
    alternate = !alternate;
    return alternate ? '1' : '2';
}

function moveToFront() {
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

function playFakeoutAnim(){
    intendedChar.playAnim('fakeout', true);
    moveToBack();
}

function playTauntAnim(){
    intendedChar.playAnim('taunt', true);
    moveToBack();
}

function playTauntConditionalAnim(){
    if(intendedChar.getAnimName() == 'fakeout') playTauntAnim();
    else playIdleAnim();
}

// note stuff
function goodNoteHit(note){
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