shader_type spatial;

render_mode cull_disabled;

uniform float height = 0;
uniform float normal_strength = 1.0;
uniform vec3 static_direction_local = vec3(0.0,0.0,0.0);
uniform float h = 0;
uniform float density = 1.0;
uniform bool render_skin = true;

uniform vec3 color: source_color;
uniform sampler2D height_gradient: source_color, filter_nearest;
uniform bool use_height_gradient = false;
uniform bool scale_height_gradient = true;
uniform bool use_albedo_texture = false;
uniform sampler2D albedo_texture : source_color;

uniform bool use_emission = false;
uniform vec3 emission_color: source_color;
uniform float emission_energy_multiplier;
uniform bool use_emission_texture = false;
uniform sampler2D emission_texture : source_color;

uniform sampler2D thickness_curve;
uniform bool use_thickness_curve = false;
uniform float thickness_scale = 1.0;

void vertex() {
    VERTEX += (NORMAL * normal_strength + static_direction_local * (1.0 - normal_strength)) * height * h;
}

void fragment() {
    vec2 uv = UV * density;
    float len = 1.0;

    vec2 center = vec2(0.5, 0.5);
    vec2 center_offset = fract(uv * 1024.0) - center;
    float relDist = length(center_offset) / thickness_scale * 2.0;

    float thickness;
    if(use_thickness_curve) {
        thickness = texture(thickness_curve, vec2(clamp(h / len, 0.0, 0.99), 0.0)).r * len;
    } else {
        thickness = h;
    }

    if(len - thickness >= relDist && h < len || (render_skin && h == 0.0)) {
        if(!FRONT_FACING) NORMAL = -NORMAL;
        vec3 col = color;

        float grad_h = h;
        if(scale_height_gradient) {
            grad_h /= len;
        }

        vec3 height_col;
        if(use_height_gradient) {
            height_col = texture(height_gradient, vec2(grad_h * 0.999, 0.0)).rgb;
        } else {
            float hg = pow(h, 0.9);
            height_col = vec3(hg,hg,hg);
        }
        col *= height_col;

        if(use_albedo_texture) {
            col *= texture(albedo_texture, UV).rgb;
        }
        ALBEDO = col;
        if(use_emission) {
            vec3 emission = emission_color;
            if(use_emission_texture) {
                emission += texture(emission_texture, UV).rgb;
            }
            EMISSION = emission * emission_energy_multiplier;
        }
    } else {
        discard;
    }
}

void light() {
    float d = dot(NORMAL, LIGHT) / 2.0 + 0.5;
    DIFFUSE_LIGHT += d * d * ATTENUATION * LIGHT_COLOR;
}