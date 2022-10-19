#version 120

varying vec2 TexCoords;
varying vec2 LmCoords;
varying vec3 Normal;
varying vec4 Color;

void main() {
    gl_Position = ftransform();
    TexCoords = gl_MultiTexCoord0.st;
    Normal = gl_NormalMatrix * gl_Normal;
    Color = gl_Color;

    // Use the texture matrix instead of dividing by 15 to maintain compatiblity for each version of Minecraft
    LmCoords = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    // Transform them into the [0, 1] range
    LmCoords = (LmCoords * 33.05 / 32.0) - (1.05 / 32.0);
}