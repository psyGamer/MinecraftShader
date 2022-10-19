#version 120

varying vec2 TexCoords;

uniform sampler2D colortex0;

void main() {
    vec3 color = texture2D(colortex0, TexCoords).rgb;
    // Sample and apply gamma correction
    color = pow(color, vec3(1 / 2.2));
    gl_FragData[0] = vec4(color, 1);
}