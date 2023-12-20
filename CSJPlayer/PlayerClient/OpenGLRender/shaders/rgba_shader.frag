#version 410

out vec4 fragColor;

in highp vec2 v_texcoord;
uniform sampler2D inputImageTexture;

void main() {
    fragColor = texture(inputImageTexture, v_texcoord);
}
