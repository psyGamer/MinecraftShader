#version 120

attribute vec4 mc_Entity;

varying vec2 TexCoords;
varying vec2 LmCoords;
varying vec3 Normal;
varying vec4 Color;
varying vec4 Material;

void main() {
    vec4 position = gl_Vertex;
    TexCoords = gl_MultiTexCoord0.st;
    Normal = gl_Normal * 0.5 + 0.5;
    Color = gl_Color;

    // Use the texture matrix instead of dividing by 15 to maintain compatiblity for each version of Minecraft
    LmCoords = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    // Transform them into the [0, 1] range
    LmCoords = (LmCoords * 33.05 / 32.0) - (1.05 / 32.0);

    Material = mc_Entity.x == 10
        ? vec4(0.5, 0, 0, 1)
        : vec4(0, 0, 0, 1);

    gl_Position = gl_ModelViewProjectionMatrix * position;
}