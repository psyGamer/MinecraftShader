#version 120

varying vec2 TexCoords;
varying vec3 Normal;
varying vec4 Color;

void main() {
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    TexCoords = gl_MultiTexCoord0.st;
    Normal = gl_Normal * 0.5 + 0.5;
    Color = gl_Color;
}