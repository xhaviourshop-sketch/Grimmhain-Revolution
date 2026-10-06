shader_type canvas_item;
// Grund der Vollbildkarten: das, was unter der Karte steht (das Dorf), leicht unscharf und stark abgedunkelt.
// Compatibility-tauglich: keine Mipmaps, nur 13 Proben (Mitte plus Spirale), Radius in Bildschirmpunkten.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float radius = 5.0;
uniform float darken = 0.22;                         // Restlicht der Szene (0 = schwarz, 1 = unverändert)
uniform vec4 tint : source_color = vec4(0.04, 0.063, 0.133, 1.0);
uniform float tint_amount = 0.12;

void fragment() {
	vec3 sum = texture(screen_tex, SCREEN_UV).rgb;
	for (int i = 1; i < 13; i++) {
		float fi = float(i);
		float a = fi * 2.399963;                      // Goldener Winkel
		float r = sqrt(fi / 12.0) * radius;
		sum += texture(screen_tex, SCREEN_UV + vec2(cos(a), sin(a)) * r * SCREEN_PIXEL_SIZE).rgb;
	}
	vec3 scene = sum / 13.0 * darken;
	COLOR = vec4(mix(scene, tint.rgb, tint_amount), 1.0);
}
