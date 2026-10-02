shader_type canvas_item;
// Nebel (P4): eine langsam ziehende Ebene über dem Hintergrund und hinter allen Bedienflächen. Am Rand dichter, über dem Spielerring
// (Mitte) schwächer, damit Namen und Porträts ruhig stehen. Rein kosmetisch, ohne Ton.
uniform float strength = 0.18;         // Deckkraft am Rand (Startwert 15 bis 20 %)
uniform float center_factor = 0.4;     // Anteil davon in der Mitte
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

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(17.0, 9.0);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	float t = TIME * animate;
	vec2 p = UV * vec2(3.0, 2.0);
	float n = fbm(p + vec2(t * 0.012, t * 0.004)) * 0.65 + fbm(p * 1.7 - vec2(t * 0.02, 0.0)) * 0.35;
	float cloud = smoothstep(0.3, 0.75, n);
	float edge = smoothstep(0.15, 0.75, length((UV - vec2(0.5)) * vec2(1.0, 1.25)) * 1.6);
	float density = mix(center_factor, 1.0, edge);
	COLOR = vec4(fog_color.rgb, strength * cloud * density);
}
