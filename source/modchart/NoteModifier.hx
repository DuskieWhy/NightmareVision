// @author Nebula_Zorua

package modchart;

import modchart.Modifier.ModifierType;

import meta.data.*;
import meta.states.*;
import meta.states.substate.*;
import gameObjects.*;

class NoteModifier extends Modifier {
	override function getModType()
		return NOTE_MOD; // tells the mod manager to call this modifier when updating receptors/notes

}