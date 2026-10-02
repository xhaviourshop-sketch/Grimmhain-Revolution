shader_type canvas_item;
// Tote Plätze (P5): Rahmen, Porträt und Schild werden entsättigt und leicht abgedunkelt. Die Information „tot“ hängt nicht an der
// Farbe allein: Schild („†“) und Symbol am Ring bleiben.
uniform float amount = 0.9;
uniform float dim = 0.85;

void fragment() {
	float grey = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	COLOR.rgb = mix(COLOR.rgb, vec3(grey), amount) * dim;
}
