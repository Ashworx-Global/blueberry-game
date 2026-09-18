shader_type canvas_item;

// 90s semi-pixel palette — slight posterize + dither, for sky/foreground cohesion
uniform float posterize_steps : hint_range(2.0,16.0) = 8.0;
uniform float dither_strength : hint_range(0.0,0.5) = 0.08;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	// posterize
	vec3 p = floor(col.rgb * posterize_steps) / posterize_steps;
	// bayer 4x4 dither
	float bayer = 0.0;
	int ix = int(mod(UV.x * 640.0, 4.0));
	int iy = int(mod(UV.y * 360.0, 4.0));
	float bayer_mat[16] = float[16](0., 8., 2., 10., 12., 4., 14., 6., 3., 11., 1., 9., 15., 7., 13., 5.);
	int idx = iy*4 + ix;
	bayer = bayer_mat[idx] / 16.0 - 0.5;
	p += bayer * dither_strength / posterize_steps;
	COLOR = vec4(p, col.a);
}
