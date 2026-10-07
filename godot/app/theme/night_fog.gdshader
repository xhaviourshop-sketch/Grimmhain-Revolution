shader_type canvas_item;
// Bodennebel (Nacht-Atmosphäre): zwei durchscheinende Schichten in Bodennähe in einem Durchgang. Unten im Bild dichter, oben nichts
// (dort endet die Rechnung früh). Die Schichten ziehen unterschiedlich schnell. Rein kosmetisch, ohne Ton.
// Kosten: 3 + 2 Rauschproben je Pixel mit Nebel, darüber keine.
uniform float strength = 0.25;         // Deckkraft ganz unten; 0 blendet aus
uniform float animate = 1.0;           // 0 = stehender Nebel (reduzierte Bewegung)
uniform vec4 fog_color : source_color = vec4(0.62, 0.7, 0.85, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm3(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(17.0, 9.0);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	float ground = smoothstep(0.45, 1.0, UV.y);   // oben praktisch nichts
	if (ground < 0.01 || strength < 0.001) {
		COLOR = vec4(0.0);
	} else {
		float t = TIME * animate;
		float a = smoothstep(0.35, 0.75, fbm3(UV * vec2(3.0, 2.0) + vec2(t * 0.012, 0.0)));
		float b = smoothstep(0.4, 0.8, 0.5 * (noise(UV * vec2(5.0, 3.0) - vec2(t * 0.025, 3.0)) + noise(UV * vec2(9.0, 5.0) - vec2(t * 0.04, 7.0))));
		float density = ground * (0.6 * a + 0.4 * b);
		COLOR = vec4(fog_color.rgb, strength * density);
	}
}
