// IF YOUR MOD USES A NEW DEFAULT NOTESKIN, YOU CAN RENAME THE SCRIPT TO default AND IT WILL BE USED AUTOMATICALLY


// Sets the skin for respective characters. Set to the path of your skin.
function dadSkin(){ return 'NOTE_assets'; }
function bfSkin(){ return 'NOTE_assets'; }

// Sets the skin for notesplashes. Set to the asset path of your skin.
function noteSplash(offsets){ return 'noteSplashes'; }

// Return true or false if your noteskin has quant variants. 
// If your skin DOES have quant variants, make sure the assets for it are the same as the skin assets but with "QUANT" infront of it.
function quants(){ return false; }

// Offsets for each part of the notes. 
// Each are an array of 4 values, each representing the offset for the respective note.

// noteOff is the offset for the notes themself.
// strumOff is the offset for the strum.
// susOff is the offset for the sustain notes.
function offset(noteOff, strumOff, susOff){}

