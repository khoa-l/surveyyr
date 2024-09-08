shader_type particles;

uniform float particle_diameter = 5.0;

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void start() {
    // Convert RANDOM_SEED to float and create two different seeds
    float seed1 = float(RANDOM_SEED) / 4294967295.0; // Divide by max uint value
    float seed2 = fract(seed1 * 123.456);

    float x_modifier = rand(vec2(seed1, 0.0)) * particle_diameter;
    float z_modifier = rand(vec2(seed2, 0.0)) * particle_diameter;

    TRANSFORM[3].x = x_modifier - 0.5 * particle_diameter;
    TRANSFORM[3].z = z_modifier - 0.5 * particle_diameter;

    VELOCITY.y = -1.0;
}

void process() {
    // Use INDEX for consistent per-particle randomness
    float particle_rand = rand(vec2(float(INDEX), 0.0));
    float particle_rand2 = rand(vec2(float(INDEX) + 1.0, 0.0));

    VELOCITY.x = 3.0 * sin(TIME / 4.0) * sin(TIME) * particle_rand;
    VELOCITY.z = 3.0 * cos(TIME / 4.0) * cos(TIME) * particle_rand2;

    float x_rotation = TIME * rand(vec2(float(INDEX), 1.0));
    float y_rotation = TIME * rand(vec2(float(INDEX), 2.0));
    float z_rotation = TIME * rand(vec2(float(INDEX), 3.0));

    // Combine rotations into a single matrix for efficiency
    mat3 rotation = mat3(
        vec3(cos(y_rotation) * cos(z_rotation), cos(y_rotation) * sin(z_rotation), -sin(y_rotation)),
        vec3(-cos(x_rotation) * sin(z_rotation) + sin(x_rotation) * sin(y_rotation) * cos(z_rotation),
             cos(x_rotation) * cos(z_rotation) + sin(x_rotation) * sin(y_rotation) * sin(z_rotation),
             sin(x_rotation) * cos(y_rotation)),
        vec3(sin(x_rotation) * sin(z_rotation) + cos(x_rotation) * sin(y_rotation) * cos(z_rotation),
             -sin(x_rotation) * cos(z_rotation) + cos(x_rotation) * sin(y_rotation) * sin(z_rotation),
             cos(x_rotation) * cos(y_rotation))
    );

    TRANSFORM[0].xyz = rotation * TRANSFORM[0].xyz;
    TRANSFORM[1].xyz = rotation * TRANSFORM[1].xyz;
    TRANSFORM[2].xyz = rotation * TRANSFORM[2].xyz;
}