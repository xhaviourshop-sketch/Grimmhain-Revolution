shader_type canvas_item;
// Dorfplatz bei Nacht: dämpft die warmen Reflexe auf dem Pflaster zu kühlem Mondlicht und dunkelt die untere Bildhälfte leicht ab,
// damit Namensschilder und Porträts ruhig stehen (Abnahme 1).
// Fensterlicht (P4): Das Grundbild ist an den Fenstern abgedunkelt, die ID-Karte nummeriert jede Fensterinsel (Grauwert = Nummer,
// 0 = kein Fenster). Ein Schein addiert das fehlende Licht zurück, je Insel mit eigener langsamer Schwankung 85 bis 100 % und selten
// einem kurzen, weichen Absacken. Bei flicker = 1 entsteht wieder das ursprüngliche Bild.
uniform sampler2D id_map : filter_nearest, repeat_disable;
uniform float dim = 0.3;               // Helligkeit des Grundbilds in den Fenstern (muss zum Bauskript passen)
uniform float animate = 1.0;           // 0 = stehendes Licht (reduzierte Bewegung)
uniform float still_level = 0.93;      // Helligkeit des stehenden Lichts

float hash(float n) {
	return fract(sin(n * 127.1 + 311.7) * 43758.5453);
}

float flicker(float id) {
	float t = TIME;
	float slow = sin(t * (0.22 + 0.18 * hash(id)) + 6.2832 * hash(id + 17.0));
	float fine = sin(t * (0.55 + 0.35 * hash(id + 31.0)) + 6.2832 * hash(id + 43.0));
	float level = 0.925 + 0.05 * slow + 0.025 * fine;  // bleibt zwischen 0,85 und 1,0
	float period = 22.0 + 38.0 * hash(id + 59.0);       // Absacken alle 22 bis 60 s, je Insel versetzt
	float into = mod(t + period * hash(id + 71.0), period);
	float dip = smoothstep(0.0, 0.35, into) * (1.0 - smoothstep(0.35, 0.9, into));  // weich, unter einer Sekunde
	level = level - 0.15 * dip * step(0.5, hash(id + 83.0));  // nur ein Teil der Inseln sackt überhaupt ab
	return mix(still_level, level, animate);
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float id = floor(texture(id_map, UV).r * 255.0 + 0.5);
	if (id > 0.5) {
		c.rgb += c.rgb * (1.0 / dim - 1.0) * flicker(id);
	} else {
		float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
		float warm = clamp((c.r - c.b) * 2.5, 0.0, 1.0);
		float floor_mask = smoothstep(0.30, 0.48, UV.y);
		vec3 cool = vec3(lum) * vec3(0.78, 0.9, 1.1);
		c.rgb = mix(c.rgb, cool, warm * floor_mask * 0.9);
		c.rgb *= 1.0 - floor_mask * 0.2;
	}
	COLOR = c;
}
