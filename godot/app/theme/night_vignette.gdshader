shader_type canvas_item;
// Randdämpfung: dunkle Mitte für Karte und Namen (ruhig, kein Detail), dunkle Ränder; die helle Zone dazwischen bleibt Dorf.
void fragment() {
	vec2 p = (UV - vec2(0.5, 0.58)) / vec2(0.5, 0.46);
	float d = length(p);
	float centre = 1.0 - smoothstep(0.35, 1.0, d);
	float edge = smoothstep(0.95, 1.5, d);
	COLOR = vec4(0.012, 0.02, 0.05, centre * 0.62 + edge * 0.3);
}
