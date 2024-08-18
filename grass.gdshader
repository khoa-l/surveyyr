shader_type spatial;

uniform float density : hint_range(1.0, 1000.0) = 100.0;
uniform float shell_thickness : hint_range(0.0, 1.0) = 0.1;

varying float is_offset;

void vertex() {
	VERTEX = VERTEX;
	is_offset = 0.0;

	vec3 displaced_position = VERTEX + NORMAL * shell_thickness;

	// Called for every vertex the material is visible on.
	VERTEX = displaced_position;
	UV = UV;
	is_offset = 1.0;
}

float hash(float x) {
	return fract(sin(x * 12.9898) * 43758.5453);
}

void fragment() {
	vec3 world_pos = FRAGCOORD.xyz;
	vec2 uv = UV;

	uv *= density;

	float noise = hash(dot(uv, vec2(1.0, 57.0)));
	if (is_offset > 0.5) {
		if (noise > 0.0){
			ALBEDO = vec3(0.0, 1.0, 0.0);
		} else {
			ALBEDO = vec3(0.0, 0.0, 0.0);
		}
	} else {
		ALBEDO = vec3(0.2, 0.2, 0.2);
	}

}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
