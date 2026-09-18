shader_type canvas_item;

// 2.5D Isometric ground — tiles a pixel ground texture with perspective skew
// Golden Axe style: ground plane angled, horizon at top, continuous scroll

uniform sampler2D ground_tex;
uniform vec2 scroll; // driven by script: player/camera offset
uniform float horizon : hint_range(0.0,1.0) = 0.42; // y where ground meets sky
uniform float perspective_strength : hint_range(0.0,1.0) = 0.68; // skew amount
uniform float tiling : hint_range(1.0,8.0) = 2.5;
uniform float time_scroll_speed : hint_range(0.0,1.0) = 0.0; // 0 = manual, >0 auto
uniform float discovery_radius : hint_range(0.0,1.0) = 0.0; // 0 = reveal all, 1 = hidden (for future discovery)
uniform vec2 discovery_center = vec2(0.5, 0.5);

void fragment() {
	vec2 uv = UV;
	
	// horizon cutoff — sky above stays transparent (shows Parallax layers)
	if (uv.y < horizon) {
		COLOR = vec4(0.0);
	} else {
		// remap ground uv to 0-1 in ground region
		float gy = (uv.y - horizon) / (1.0 - horizon); // 0 at horizon, 1 at bottom
	
	// perspective: compress x as we go to horizon (far = narrow)
	float persp = mix(1.0, 0.35, perspective_strength * (1.0 - gy));
	// slight y squash for iso feel
	float iso_y = gy * (0.7 + 0.3 * persp);
	
	// tiling + scroll — continuous
	vec2 g_uv = vec2(
		(uv.x - 0.5) / persp * tiling + 0.5 + scroll.x,
		iso_y * tiling * 0.75 + scroll.y
	);
	
	// sample tiled ground — fract for continuous repeat (90s tile)
	vec4 tex = texture(ground_tex, fract(g_uv));
	
	// distance fade / horizon haze — 90s muted
	float haze = smoothstep(0.0, 0.28, gy); // fade in from horizon
	float vign = 1.0 - 0.12 * length((uv - vec2(0.5, 0.85)) * vec2(1.4, 1.0));
	tex.a *= haze;
	tex.rgb *= vign;
	
	// subtle scanline for semi-pixel 90s CRT feel
	float scan = 1.0 - 0.08 * step(0.5, fract(uv.y * 180.0));
	tex.rgb *= scan;
	
	// discovery mask — radial reveal around player (hook for later)
	// when discovery_radius >0, darken outside radius
	if (discovery_radius > 0.001) {
		float d = distance(uv, discovery_center);
		float mask = smoothstep(discovery_radius, discovery_radius - 0.18, d);
		// outside = darker / desaturated
		tex.rgb = mix(tex.rgb * 0.35, tex.rgb, mask);
		tex.a = mix(tex.a * 0.6, tex.a, mask);
	}
	
		COLOR = tex;
	}
}
