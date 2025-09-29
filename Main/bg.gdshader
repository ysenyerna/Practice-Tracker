shader_type canvas_item;

const float CYCLE_TIME = 60.0;


void fragment() {
	float t = fract(TIME / CYCLE_TIME) * 2.0;
	if (t > 1.0)
	t = -t + 2.0;


	float a = 0.0;
	a = smoothstep(0.0, 1.0, t);

	float b = a - 0.5;

	float c = abs(UV.x - 0.5);
	c = -c  + a;
	c += 0.25;

	c = smoothstep(0, 1, c);
	c /= 10.0;



	vec2 uv = UV;
	uv.y += c;
	uv.x += a;


	COLOR = texture(TEXTURE, uv);

	COLOR.x += b / 20.0;
	COLOR.y += -(b / 20.0);


}