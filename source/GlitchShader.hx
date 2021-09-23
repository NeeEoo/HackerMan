import flixel.system.FlxAssets.FlxShader;

class GlitchShader extends FlxShader
{
	@:glFragmentSource('
	#pragma header

	uniform float uTime;

	uniform float amount; //0 - 1 glitch amount
	uniform float speed; //0 - 1 speed

	//2D (returns 0 - 1)
	float random2d(vec2 n) {
		return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
	}

	float randomRange (in vec2 seed, in float min, in float max) {
		return min + random2d(seed) * (max - min);
	}

	// return 1 if v inside 1d range
	float insideRange(float v, float bottom, float top) {
		return step(bottom, v) - step(top, v);
	}

	void main()
	{
		float time = floor(uTime * speed * 60.0);
		vec2 uv = openfl_TextureCoordv;

		//copy orig
		vec4 outCol = texture(bitmap, uv);

		//randomly offset slices horizontally
		float maxOffset = amount/2.0;
		for (float i = 0.0; i < 10.0 * amount; i += 1.0) {
			float sliceY = random2d(vec2(time, 2345.0 + float(i)));
			float sliceH = random2d(vec2(time, 9035.0 + float(i))) * 0.25;
			float hOffset = randomRange(vec2(time, 9625.0 + float(i)), -maxOffset, maxOffset);
			vec2 uvOff = uv;
			uvOff.x += hOffset;
			if (insideRange(uv.y, sliceY, fract(sliceY+sliceH)) == 1.0){
				outCol = texture(bitmap, uvOff);
			}
		}

		//do slight offset on one entire channel
		float maxColOffset = amount/6.0;
		float rnd = random2d(vec2(time, 9545.0));
		vec2 colOffset = vec2(randomRange(vec2(time, 9545.0), -maxColOffset, maxColOffset), randomRange(vec2(time, 7205.0), -maxColOffset, maxColOffset));
		if (rnd < 0.33){
			outCol.r = texture(bitmap, uv + colOffset).r;
		}else if (rnd < 0.66){
			outCol.g = texture(bitmap, uv + colOffset).g;
		}else{
			outCol.b = texture(bitmap, uv + colOffset).b;
		}
		// outCol.a = texture(bitmap, uv + colOffset).a;

		gl_FragColor = outCol;
	}
	')

	public function new()
	{
		super();

		resetParams();
	}

	public function resetParams() {
		this.uTime.value = [0.0];
		this.amount.value = [0.0];
		this.speed.value = [0.6];
	}
}