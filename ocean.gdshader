shader_type spatial;

void vertex() {
	VERTEX = vec3(VERTEX.x * 10.0, VERTEX.y, VERTEX.z * 10.0);
	// Called for every vertex the material is visible on.
}

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

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

float h(vec2 uv) {
	return fbm(uv * 5.0 + vec2(TIME * 0.04, TIME * 0.02)) * 1.0
		+ fbm(uv * 10.0 + vec2(TIME * 0.01, TIME * 0.01)) * 1.0;
}

void fragment() {
	vec2 pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz * 0.001;
	float l = h(pos + vec2(1.0, 0.0));
	float t = h(pos + vec2(0.0, 1.0));
	float r = h(pos + vec2(-1.0, 0.0));
	float b = h(pos + vec2(0.0, -1.0));
	NORMAL = mat3(VIEW_MATRIX) * normalize(vec3(2.0*(r-l), 4.0, 2.0*(b-t)));

	vec4 c = vec4(0.1, 0.2, 0.3, 0.1) + vec4(0, 0, 0, 0.9) * fresnel(1.0, NORMAL, VIEW);
	ALBEDO = c.rgb;
	ALPHA = c.a;
	SPECULAR = 0.5;
	ROUGHNESS = 0.0;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
