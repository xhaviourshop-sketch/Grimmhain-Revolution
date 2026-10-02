shader_type canvas_item;
// Dorfplatz bei Nacht: dÃ¤mpft die warmen Reflexe auf dem Pflaster zu kÃ¼hlem Mondlicht und dunkelt die untere BildhÃ¤lfte leicht ab,
// damit Namensschilder und PortrÃ¤ts ruhig stehen (Abnahme 1).
// Fensterlicht (P4): Das Grundbild ist an den Fenstern abgedunkelt. Die ID-Karte nummeriert jede Fensterinsel (R = Nummer, 0 = kein
// Fenster) und gibt ihren Lichthof an (G = 255 im Fenster, 1 bis 254 = weicher Hof drumherum). Ein Schein addiert das fehlende Licht
// zurück, je Insel mit eigener Phase: langsame Schwankung zwischen 55 und 100 % des Scheins (Periode 2 bis 6 s), selten ein weiches
// Absacken auf 30 % für 0,2 bis 0,5 s. Im Mittel kehrt das Fenster auf seine Originalhelligkeit zurück; der Hof flackert mit.
uniform sampler2D id_map : filter_nearest, repeat_disable;
uniform float dim = 0.3;               // Helligkeit des Grundbilds in den Fenstern (muss zum Bauskript passen)
uniform float animate = 1.0;           // 0 = stehendes Licht (reduzierte Bewegung)
uniform float halo_strength = 0.3;     // Stärke des warmen Hofs am Fensterrand
uniform vec3 halo_color : source_color = vec3(1.0, 0.6, 0.22);
const float MEAN_LEVEL = 0.775;        // Mittel der Schwankung, damit der Schein im Mittel das Original ergibt

float hash(float n) {
	return fract(sin(n * 127.1 + 311.7) * 43758.5453);
}

float flicker(float id) {
	float t = TIME;
	float pa = 3.0 + 3.0 * hash(id);
	float pb = 2.0 + 1.5 * hash(id + 31.0);
	float level = MEAN_LEVEL + 0.225 * (0.7 * sin(6.2832 * t / pa + 6.2832 * hash(id + 17.0)) + 0.3 * sin(6.2832 * t / pb + 6.2832 * hash(id + 43.0)));
	float period = 20.0 + 20.0 * hash(id + 59.0);       // Absacken alle 20 bis 40 s, je Insel versetzt
	float length = 0.2 + 0.3 * hash(id + 67.0);
	float into = mod(t + period * hash(id + 71.0), period);
	float dip = smoothstep(0.0, 0.4 * length, into) * (1.0 - smoothstep(0.4 * length, length, into));
	level = mix(level, 0.3, dip);
	return mix(MEAN_LEVEL, level, animate);
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 info = texture(id_map, UV).rg;
	float id = floor(info.r * 255.0 + 0.5);
	float halo = info.g;
	if (halo > 0.999) {
		c.rgb += c.rgb * (1.0 / dim - 1.0) / MEAN_LEVEL * flicker(id);
	} else {
		float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
		float warm = clamp((c.r - c.b) * 2.5, 0.0, 1.0);
		float floor_mask = smoothstep(0.30, 0.48, UV.y);
		vec3 cool = vec3(lum) * vec3(0.78, 0.9, 1.1);
		c.rgb = mix(c.rgb, cool, warm * floor_mask * 0.9);
		c.rgb *= 1.0 - floor_mask * 0.2;
		if (id > 0.5) {
			c.rgb += halo_color * halo_strength * halo * flicker(id) / MEAN_LEVEL;
		}
	}
	COLOR = c;
}
