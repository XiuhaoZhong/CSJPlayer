#version 410

in vec4 vertexIn;
in vec2 textureIn;
out vec2 textureOut;

void main(void) {
    gl_Position = vertexIn;
    textureOut = textureIn;
}
