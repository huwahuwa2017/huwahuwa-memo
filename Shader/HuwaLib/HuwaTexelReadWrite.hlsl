// v22 2024-11-29 16:33

#if !defined(HUWA_TEXEL_READ_WRITE)
#define HUWA_TEXEL_READ_WRITE

#include "UnityCG.cginc"

static uint2 _ScreenSize = uint2(_ScreenParams.xy);

static uint2 _HTRW_WriteTextureSize = _ScreenSize;
static float3 _HTRW_TexelSize = float3(2.0 / float(_HTRW_WriteTextureSize.x), 2.0 / float(_HTRW_WriteTextureSize.y) * _ProjectionParams.x, 0.0);
static float2 _HTRW_TexelPosition = 0.0;

#define HTRW_SET_WRITE_TEXTURE_SIZE(textureSize)\
_HTRW_WriteTextureSize = uint2(textureSize);\
_HTRW_TexelSize = float3(2.0 / float(_HTRW_WriteTextureSize.x), 2.0 / float(_HTRW_WriteTextureSize.y) * _ProjectionParams.x, 0.0);

#define HTRW_TEXEL_WRITE(id, clipPosition, stream)\
_HTRW_TexelPosition = float2((id) % _HTRW_WriteTextureSize.x, (id) / _HTRW_WriteTextureSize.x) * _HTRW_TexelSize.xy - float2(1.0, _ProjectionParams.x);\
clipPosition.z = 0.5;\
clipPosition.w = 1.0;\
clipPosition.xy = _HTRW_TexelPosition + _HTRW_TexelSize.zz;\
stream.Append(output);\
clipPosition.xy = _HTRW_TexelPosition + _HTRW_TexelSize.zy;\
stream.Append(output);\
clipPosition.xy = _HTRW_TexelPosition + _HTRW_TexelSize.xz;\
stream.Append(output);\
clipPosition.xy = _HTRW_TexelPosition + _HTRW_TexelSize.xy;\
stream.Append(output);\
stream.RestartStrip();

static uint2 _HTRW_ReadTextureSize = 0;

#define HTRW_TEXEL_READ(tex, id, result)\
_HTRW_ReadTextureSize = uint2(tex##_TexelSize.zw);\
result = tex[uint2((id) % _HTRW_ReadTextureSize.x, ((id) / _HTRW_ReadTextureSize.x) % _HTRW_ReadTextureSize.y)];

#if defined(UNITY_SINGLE_PASS_STEREO)
    #define HTRW_GRAB_PASS_TEXEL_READ(tex, id, result)\
    result = tex[uint2(((id) % _ScreenSize.x) + (unity_StereoEyeIndex ? _ScreenSize.x : 0), (id) / _ScreenSize.x)];
#elif defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
    #define HTRW_GRAB_PASS_TEXEL_READ(tex, id, result)\
    result = tex[uint3((id) % _ScreenSize.x, (id) / _ScreenSize.x, unity_StereoEyeIndex)];
#else
    #define HTRW_GRAB_PASS_TEXEL_READ(tex, id, result)\
    result = tex[uint2((id) % _ScreenSize.x, (id) / _ScreenSize.x)];
#endif



// Convert right side 15bit to FP16
#define HTRW_R15BIT_TO_FP16(input) asfloat(((((input) & 0x00003FFF) << 13) + 0x38800000) | (((input) & 0x00004000) << 17))

// Convert right side 14bit to FP16
#define HTRW_R14BIT_TO_FP16(input) asfloat((((input) & 0x00003FFF) << 13) + 0x38800000)

// Convert right side 13bit to FP16
#define HTRW_R13BIT_TO_FP16(input) asfloat((((input) & 0x00003FFF) << 13) | 0x3C000000)



// Convert FP16 to right side 15bit
#define HTRW_FP16_TO_R15BIT(input) ((((asuint(input) & 0x7FFFE000) - 0x38800000) >> 13) | ((asuint(input) & 0x80000000) >> 17))

// Convert FP16 to right side 14bit
#define HTRW_FP16_TO_R14BIT(input) (((asuint(input) & 0x7FFFE000) - 0x38800000) >> 13)

// Convert FP16 to right side 13bit
#define HTRW_FP16_TO_R13BIT(input) ((asuint(input) & 0x03FFE000) >> 13)



#endif // !defined(HUWA_TEXEL_READ_WRITE)
