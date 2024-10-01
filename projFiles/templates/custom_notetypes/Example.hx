// called when the note is created
function setupNote(note){ }

// called when the note is spawned in game
function spawnNote(note){ }

// called after the note is spawned in game
function postSpawnNote(note){ }

// called when the note asset is reloaded
function onReloadNote(note, prefix, texture, suffix){ }

// called after the note has been reloaded
function postReloadNote(note, prefix, texture, suffix){ }

// called when the notes animations are loaded
function loadNoteAnims(note){ }

//called when the pixel variants of the notes animations are loaded
function loadNotePixelAnims(note){ }

// called when a strumline that isnt the player hits a note
function opponentNoteHit(note){ }

// called when a strumline under player control hits a note
function playerNoteHit(note){ }

// called when the note is missed ingame
function noteMiss(note){ }

// called every frame
function update(elapsed){ }