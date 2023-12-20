#version 410

in vec2 textureOut;
out vec4 fragColor;

uniform sampler2D tex_y;
uniform sampler2D tex_u;
uniform sampler2D tex_v;

const vec3 delyuv = vec3(-0.0/255.0,-128.0/255.0,-128.0/255.0);
const vec3 matYUVRGB1 = vec3(1.0,0.0,1.402);
const vec3 matYUVRGB2 = vec3(1.0,-0.344,-0.714);
const vec3 matYUVRGB3 = vec3(1.0,1.772,0.0);

void main(void) {
    //vec3 yuv;
    vec3 rgb;
    
    vec3 CurResult;
    highp vec3 yuv;
    
    yuv.x = texture(tex_y, textureOut).r;//因为是YUV的一个平面，所以采样后的r,g,b,a这四个参数的数值是一样的
    yuv.y = texture(tex_u, textureOut).r;
    yuv.z = texture(tex_v, textureOut).r;
    
    yuv += delyuv;//读取值得范围是0-255，读取时要-128回归原值
    //用数量积来模拟矩阵变换，转换成RGB值
    CurResult.x = dot(yuv,matYUVRGB1);
    CurResult.y = dot(yuv,matYUVRGB2);
    CurResult.z = dot(yuv,matYUVRGB3);
    
    fragColor = vec4(CurResult.rgb, 1);
    
//    yuv.x = texture(tex_y, textureOut).r;
//    yuv.y = texture(tex_u, textureOut).r - 0.5;
//    yuv.z = texture(tex_v, textureOut).r - 0.5;
//
//    float r = yuv.x + 1.402 * yuv.z;
//    float g = yuv.x - 0.344 * yuv.y - 0.714 * yuv.z;
//    float b = yuv.x + 1.772 * yuv.y;
    
    //rgb = mat3(1,        1,       1,
    //           0,       -0.21482, 2.12798,
    //           1.28033, -0.38059, 0) * yuv;
    
//    float y = texture(tex_y, textureOut).r;
//    float u = texture(tex_u, textureOut).r - 0.5;
//    float v = texture(tex_v, textureOut).r - 0.5;
//
//    float r = y + 1.402 * v;
//    float g = y - 0.344 * u - 0.714 * v;
//    float b = y + 1.772 * u;
    
    
    //输出像素值给光栅器
    //gl_FragColor = vec4(CurResult.rgb, 1);
    fragColor = vec4(CurResult.rgb, 1);
    //fragColor = vec4(r, g, b, 1);
}
