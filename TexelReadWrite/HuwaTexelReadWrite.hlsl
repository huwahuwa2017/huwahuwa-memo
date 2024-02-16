// Ver13 2024-02-16 17:35

#if !defined(HUWA_TEXEL_READ_WRITE)
#define HUWA_TEXEL_READ_WRITE

#include "UnityCG.cginc"

#if !defined(HPRW_SET_DATA_TEXTURE_SIZE)
static uint2 _HPRW_TextureSize = uint2(_ScreenParams.xy + 0.5);
#else
static uint2 _HPRW_TextureSize = HPRW_SET_DATA_TEXTURE_SIZE;
#endif

static float3 _HPRW_TexelSize = float3(2.0 / float(_HPRW_TextureSize.x), 2.0 / float(_HPRW_TextureSize.y) * _ProjectionParams.x, 0.0);

static float2 _HPRW_Temp = 0.0;

float2 HPRW_GetTexelPosition(uint id)
{
	float2 pos = float2(id % _HPRW_TextureSize.x, id / _HPRW_TextureSize.x);
	return pos * _HPRW_TexelSize.xy - float2(1.0, _ProjectionParams.x);
}

#define HPRW_TEXEL_GENERATION(id, clipPosition, stream)\
_HPRW_Temp = HPRW_GetTexelPosition(id);\
clipPosition.z = 0.5;\
clipPosition.w = 1.0;\
clipPosition.xy = _HPRW_Temp + _HPRW_TexelSize.zz;\
stream.Append(output);\
clipPosition.xy = _HPRW_Temp + _HPRW_TexelSize.zy;\
stream.Append(output);\
clipPosition.xy = _HPRW_Temp + _HPRW_TexelSize.xz;\
stream.Append(output);\
clipPosition.xy = _HPRW_Temp + _HPRW_TexelSize.xy;\
stream.Append(output);\
stream.RestartStrip();

#define HPRW_GET_TEXEL_DATA(tex, id) tex[uint2((id) % _HPRW_TextureSize.x, (id) / _HPRW_TextureSize.x)]



#define HPRW_R15BIT_TO_FP16 \
temp0 = (input & 0x000003FF) << 13;\
temp1 = (input & 0x00003C00) >> 10;\
temp1 = (113 + temp1) << 23;\
temp2 = (input & 0x00004000) << 17;\
return asfloat(temp0 | temp1 | temp2);

float R15bitToFP16(uint input)
{
	uint temp0, temp1, temp2;
	HPRW_R15BIT_TO_FP16
}

float2 R15bitToFP16(uint2 input)
{
	uint2 temp0, temp1, temp2;
	HPRW_R15BIT_TO_FP16
}

float3 R15bitToFP16(uint3 input)
{
	uint3 temp0, temp1, temp2;
	HPRW_R15BIT_TO_FP16
}

float4 R15bitToFP16(uint4 input)
{
	uint4 temp0, temp1, temp2;
	HPRW_R15BIT_TO_FP16
}

#define HPRW_R14BIT_TO_FP16 \
temp0 = (input & 0x000003FF) << 13;\
temp1 = (input & 0x00003C00) >> 10;\
temp1 = (113 + temp1) << 23;\
return asfloat(temp0 | temp1);

float R14bitToFP16(uint input)
{
	uint temp0, temp1;
	HPRW_R14BIT_TO_FP16
}

float2 R14bitToFP16(uint2 input)
{
	uint2 temp0, temp1;
	HPRW_R14BIT_TO_FP16
}

float3 R14bitToFP16(uint3 input)
{
	uint3 temp0, temp1;
	HPRW_R14BIT_TO_FP16
}

float4 R14bitToFP16(uint4 input)
{
	uint4 temp0, temp1;
	HPRW_R14BIT_TO_FP16
}

#define HPRW_R10BIT_TO_FP16 \
temp0 = (input & 0x000003FF) << 13;\
return asfloat(temp0 | 0x38800000);

float R10bitToFP16(uint input)
{
	uint temp0;
	HPRW_R10BIT_TO_FP16
}

float2 R10bitToFP16(uint2 input)
{
	uint2 temp0;
	HPRW_R10BIT_TO_FP16
}

float3 R10bitToFP16(uint3 input)
{
	uint3 temp0;
	HPRW_R10BIT_TO_FP16
}

float4 R10bitToFP16(uint4 input)
{
	uint4 temp0;
	HPRW_R10BIT_TO_FP16
}



#define HPRW_FP16_TO_R15BIT \
data = asuint(input);\
temp0 = (data & 0x007FE000) >> 13;\
temp1 = (data & 0x7F800000) >> 23;\
temp1 = (temp1 - 113) << 10;\
temp2 = (data & 0x80000000) >> 17;\
return temp0 | temp1 | temp2;

uint FP16ToR15bit(float input)
{
	uint data, temp0, temp1, temp2;
	HPRW_FP16_TO_R15BIT
}

uint2 FP16ToR15bit(float2 input)
{
	uint2 data, temp0, temp1, temp2;
	HPRW_FP16_TO_R15BIT
}

uint3 FP16ToR15bit(float3 input)
{
	uint3 data, temp0, temp1, temp2;
	HPRW_FP16_TO_R15BIT
}

uint4 FP16ToR15bit(float4 input)
{
	uint4 data, temp0, temp1, temp2;
	HPRW_FP16_TO_R15BIT
}

#define HPRW_FP16_TO_R14BIT \
data = asuint(input);\
temp0 = (data & 0x007FE000) >> 13;\
temp1 = (data & 0x7F800000) >> 23;\
temp1 = (temp1 - 113) << 10;\
return temp0 | temp1;

uint FP16ToR14bit(float input)
{
	uint data, temp0, temp1;
	HPRW_FP16_TO_R14BIT
}

uint2 FP16ToR14bit(float2 input)
{
	uint2 data, temp0, temp1;
	HPRW_FP16_TO_R14BIT
}

uint3 FP16ToR14bit(float3 input)
{
	uint3 data, temp0, temp1;
	HPRW_FP16_TO_R14BIT
}

uint4 FP16ToR14bit(float4 input)
{
	uint4 data, temp0, temp1;
	HPRW_FP16_TO_R14BIT
}

#define HPRW_FP16_TO_R10BIT \
data = asuint(input);\
temp0 = (data & 0x007FE000) >> 13;\
return temp0;

uint FP16ToR10bit(float input)
{
	uint data, temp0;
	HPRW_FP16_TO_R10BIT
}

uint2 FP16ToR10bit(float2 input)
{
	uint2 data, temp0;
	HPRW_FP16_TO_R10BIT
}

uint3 FP16ToR10bit(float3 input)
{
	uint3 data, temp0;
	HPRW_FP16_TO_R10BIT
}

uint4 FP16ToR10bit(float4 input)
{
	uint4 data, temp0;
	HPRW_FP16_TO_R10BIT
}

#endif // !defined(HUWA_TEXEL_READ_WRITE)
