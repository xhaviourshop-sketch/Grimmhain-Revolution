shader_type canvas_item;
// Tönung der gemalten Lichter im Nachtbild (lebendiges Dorf): Nur warme, helle Stellen (Fenster, Laternen, Schein) werden verändert,
// Pflaster und Dächer bleiben. `gain` dimmt das warme Licht (Wolfsschritt 0,6), `tint` färbt es (rötlich beim Wolfsschritt),
// `cold` 0 bis 1 tauscht das Warme gegen den Ton des Geisterfeuers (Akt IV). Kosten: eine Texturprobe je Pixel.
uniform float gain = 1.0;
uniform vec3 tint : source_color = vec3(1.0);
uniform float cold = 0.0;
uniform vec3 cold_color : source_color = vec3(0.35, 0.6, 1.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float warm = clamp((c.r - c.b - 0.08) * 3.0, 0.0, 1.0);
	if (warm > 0.0) {
		float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
		vec3 lit = c.rgb * gain * tint;
		vec3 ghost = cold_color * lum * 1.15 * gain;
		lit = mix(lit, ghost, cold);
		c.rgb = mix(c.rgb, lit, warm);
	}
	COLOR = c;
}
