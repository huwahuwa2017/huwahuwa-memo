// Ver21 2024-11-27 13:41

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
#define HTRW_R15BIT_TO_FP16(type)\
type temp0 = (input & 0x000003FF) << 13;\
type temp1 = (((input & 0x00003C00) >> 10) + 113) << 23;\
type temp2 = (input & 0x00004000) << 17;\
return asfloat(temp0 | temp1 | temp2);

float  R15bitToFP16(uint  input) { HTRW_R15BIT_TO_FP16(uint ) }
float2 R15bitToFP16(uint2 input) { HTRW_R15BIT_TO_FP16(uint2) }
float3 R15bitToFP16(uint3 input) { HTRW_R15BIT_TO_FP16(uint3) }
float4 R15bitToFP16(uint4 input) { HTRW_R15BIT_TO_FP16(uint4) }

// Convert right side 14bit to FP16
#define HTRW_R14BIT_TO_FP16(type)\
type temp0 = (input & 0x000003FF) << 13;\
type temp1 = (((input & 0x00003C00) >> 10) + 113) << 23;\
return asfloat(temp0 | temp1);

float  R14bitToFP16(uint  input) { HTRW_R14BIT_TO_FP16(uint ) }
float2 R14bitToFP16(uint2 input) { HTRW_R14BIT_TO_FP16(uint2) }
float3 R14bitToFP16(uint3 input) { HTRW_R14BIT_TO_FP16(uint3) }
float4 R14bitToFP16(uint4 input) { HTRW_R14BIT_TO_FP16(uint4) }

// Convert right side 10bit to FP16
#define HTRW_R10BIT_TO_FP16(type)\
type temp0 = (input & 0x000003FF) << 13;\
return asfloat(temp0 | 0x38800000);

float  R10bitToFP16(uint  input) { HTRW_R10BIT_TO_FP16(uint ) }
float2 R10bitToFP16(uint2 input) { HTRW_R10BIT_TO_FP16(uint2) }
float3 R10bitToFP16(uint3 input) { HTRW_R10BIT_TO_FP16(uint3) }
float4 R10bitToFP16(uint4 input) { HTRW_R10BIT_TO_FP16(uint4) }



// Convert FP16 to right side 15bit
#define HTRW_FP16_TO_R15BIT(type)\
type data = asuint(input);\
type temp0 = (data & 0x007FE000) >> 13;\
type temp1 = (((data & 0x7F800000) >> 23) - 113) << 10;\
type temp2 = (data & 0x80000000) >> 17;\
return temp0 | temp1 | temp2;

uint  FP16ToR15bit(float  input) { HTRW_FP16_TO_R15BIT(uint ) }
uint2 FP16ToR15bit(float2 input) { HTRW_FP16_TO_R15BIT(uint2) }
uint3 FP16ToR15bit(float3 input) { HTRW_FP16_TO_R15BIT(uint3) }
uint4 FP16ToR15bit(float4 input) { HTRW_FP16_TO_R15BIT(uint4) }

// Convert FP16 to right side 14bit
#define HTRW_FP16_TO_R14BIT(type)\
type data = asuint(input);\
type temp0 = (data & 0x007FE000) >> 13;\
type temp1 = (((data & 0x7F800000) >> 23) - 113) << 10;\
return temp0 | temp1;

uint  FP16ToR14bit(float  input) { HTRW_FP16_TO_R14BIT(uint ) }
uint2 FP16ToR14bit(float2 input) { HTRW_FP16_TO_R14BIT(uint2) }
uint3 FP16ToR14bit(float3 input) { HTRW_FP16_TO_R14BIT(uint3) }
uint4 FP16ToR14bit(float4 input) { HTRW_FP16_TO_R14BIT(uint4) }

// Convert FP16 to right side 10bit
#define HTRW_FP16_TO_R10BIT(type)\
type data = asuint(input);\
type temp0 = (data & 0x007FE000) >> 13;\
return temp0;

uint  FP16ToR10bit(float  input) { HTRW_FP16_TO_R10BIT(uint ) }
uint2 FP16ToR10bit(float2 input) { HTRW_FP16_TO_R10BIT(uint2) }
uint3 FP16ToR10bit(float3 input) { HTRW_FP16_TO_R10BIT(uint3) }
uint4 FP16ToR10bit(float4 input) { HTRW_FP16_TO_R10BIT(uint4) }

#endif // !defined(HUWA_TEXEL_READ_WRITE)
