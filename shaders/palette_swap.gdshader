shader_type canvas_item;

// Body key colors (painted in sprite)
const vec3 BODY_HI  = vec3(1.0, 0.0, 1.0);       // #FF00FF
const vec3 BODY_MID = vec3(0.8, 0.0, 0.8);       // #CC00CC
const vec3 BODY_SHA = vec3(0.6, 0.0, 0.6);       // #990099

// Shell key colors (painted in sprite)
const vec3 SHELL_HI  = vec3(0.0, 1.0, 1.0);      // #00FFFF
const vec3 SHELL_MID = vec3(0.0, 0.8, 0.8);      // #00CCCC
const vec3 SHELL_SHA = vec3(0.0, 0.6, 0.6);      // #009999

// Player colors (set per instance)
uniform vec3 body_color : source_color = vec3(0.69, 0.66, 0.78);
uniform vec3 shell_color : source_color = vec3(0.63, 0.41, 0.19);

// Tolerance for matching key colors (tight for pixel art)
const float TOLERANCE = 0.02;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 c = tex.rgb;

	// Body replacements
	if (distance(c, BODY_HI) < TOLERANCE) {
		COLOR = vec4(mix(body_color, vec3(1.0), 0.3), tex.a);
	} else if (distance(c, BODY_MID) < TOLERANCE) {
		COLOR = vec4(body_color, tex.a);
	} else if (distance(c, BODY_SHA) < TOLERANCE) {
		COLOR = vec4(body_color * 0.65, tex.a);
	}
	// Shell replacements
	else if (distance(c, SHELL_HI) < TOLERANCE) {
		COLOR = vec4(mix(shell_color, vec3(1.0), 0.3), tex.a);
	} else if (distance(c, SHELL_MID) < TOLERANCE) {
		COLOR = vec4(shell_color, tex.a);
	} else if (distance(c, SHELL_SHA) < TOLERANCE) {
		COLOR = vec4(shell_color * 0.65, tex.a);
	}
	// Everything else passes through unchanged
	else {
		COLOR = tex;
	}
}
