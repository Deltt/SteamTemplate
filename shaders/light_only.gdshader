shader_type spatial;

render_mode diffuse_burley, depth_prepass_alpha;

void vertex() {
}

void fragment() {
	ALBEDO = vec3(1.0, 1.0, 1.0);
    ALPHA = 0.0;
}

void light() {
    float NdotL = dot(NORMAL, LIGHT);
    float light_intensity = max(0.0, NdotL) * ATTENUATION;

    ALPHA += light_intensity;

    DIFFUSE_LIGHT += light_intensity * LIGHT_COLOR;
}
