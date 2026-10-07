shader_type canvas_item;
// Wolfsschimmer: schwacher, langsam pulsierender roter Schein am Bildrand, solange ein Wolfsschritt läuft. Die Mitte bleibt frei.
uniform vec4 glow_color : source_color = vec4(0.78, 0.08, 0.1, 1.0);
uniform float strength = 0.0;          // 0 bis 1, blendet weich ein und aus
uniform float max_alpha = 0.18;        // Deckkraft ganz am Rand bei strength 1
uniform float pulse_seconds = 2.5;
uniform float animate = 1.0;           // 0 = gleichmäßiger Schein (reduzierte Bewegung)

void fragment() {
	float edge = smoothstep(0.62, 1.05, length((UV - vec2(0.5)) * vec2(1.0, 1.15)) * 1.6);
	float pulse = mix(0.8, 0.65 + 0.35 * sin(TIME * 6.2832 / pulse_seconds), animate);
	COLOR = vec4(glow_color.rgb, max_alpha * strength * edge * pulse);
}
