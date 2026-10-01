shader_type canvas_item;
// Dorfplatz bei Nacht (G1): dämpft die warmen Reflexe auf dem Pflaster zu kühlem Mondlicht und dunkelt die untere Bildhälfte leicht ab,
// damit Namensschilder und Porträts ruhig stehen. Das Bild selbst bleibt unverändert (Abnahme 1: G1 mit Abdunklung und Randdämpfung).
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	float warm = clamp((c.r - c.b) * 2.5, 0.0, 1.0);
	float floor_mask = smoothstep(0.30, 0.48, UV.y);
	vec3 cool = vec3(lum) * vec3(0.78, 0.9, 1.1);
	c.rgb = mix(c.rgb, cool, warm * floor_mask * 0.9);
	c.rgb *= 1.0 - floor_mask * 0.2;
	COLOR = c;
}
