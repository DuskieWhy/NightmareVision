package extensions.funkinvis;

import funkin.vis.dsp.SpectralAnalyzer;

import lime.media.AudioSource;

import grig.audio.FFT;

class SpectralAnalyzerEx extends SpectralAnalyzer
{
	public function new(audioSource:AudioSource, barCount:Int, maxDelta:Float = 0.01, peakHold:Int = 30)
	{
		super(audioSource, barCount, maxDelta, peakHold);
		
		this.audioClip = new LimeAudioClipEx(audioSource);
	}
}
