shader_type spatial;

uniform sampler2D heightmap : repeat_disable;
uniform sampler2D colors : repeat_disable;

const vec2 iscale = 1.5 / vec2(1024.0, 1024.0);

float random(vec2 uv) {
    return fract(sin(dot(uv.xy,
        vec2(12.9898,78.233))) *
            43758.5453123);
}

float noise(vec2 uv) {
    vec2 uv_index = floor(uv);
    vec2 uv_fract = fract(uv);

    // Four corners in 2D of a tile
    float a = random(uv_index);
    float b = random(uv_index + vec2(1.0, 0.0));
    float c = random(uv_index + vec2(0.0, 1.0));
    float d = random(uv_index + vec2(1.0, 1.0));

    vec2 blur = smoothstep(0.0, 1.0, uv_fract);

    return mix(a, b, blur.x) +
            (c - a) * blur.y * (1.0 - blur.x) +
            (d - b) * blur.x * blur.y;
}

float fbm(vec2 uv) {
    int octaves = 6;
    float amplitude = 0.5;
    float frequency = 3.0;
	float value = 0.0;
	
    for(int i = 0; i < octaves; i++) {
        value += amplitude * noise(frequency * uv);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return value;
}

float h(vec2 uv, vec2 offset) {
	return texture(heightmap, uv + offset).r * 40.0 + fbm(uv * 256.0 + offset * 1024.0) * 0.2 - 0.1;
}

void vertex() {
	float z = h(UV, vec2(0, 0));
	VERTEX.y = z;
}

void fragment() {
	ALBEDO = texture(colors, vec2(texture(heightmap, UV).r, 0.0)).rgb;

	float l = h(UV, vec2(1.0, 0.0) * iscale);
	float t = h(UV, vec2(0.0, 1.0) * iscale);
	float r = h(UV, vec2(-1.0, 0.0) * iscale);
	float b = h(UV, vec2(0.0, -1.0) * iscale);
	float x = fbm(UV * 1024.0);
	float y = fbm(UV * 1024.0 + vec2(1.0));
	NORMAL = mat3(VIEW_MATRIX) * normalize(
		vec3(2.0*(r-l), 4.0, 2.0*(b-t)) +
		vec3(x, 0.0, y) * 0.4);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
