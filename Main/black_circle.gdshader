shader_type canvas_item;

uniform float rad: hint_range(0.0, 1.0);
uniform vec2 pos;
uniform float alpha: hint_range(0.0, 1.0);

void fragment() {
	vec2 center = UV - pos;
	float dist = length(center);

	if (dist > rad) {
		COLOR.a = 0.0;
	}
	else {
		COLOR = vec4(1, 1, 1, alpha);
	}
}

