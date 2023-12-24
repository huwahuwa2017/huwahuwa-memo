// Ver11 2023-12-24 17:13

#if !defined(HUWA_TEXEL_READ_WRITE)
#define HUWA_TEXEL_READ_WRITE

#include "UnityCG.cginc"

#if !defined(HPRW_SET_DATA_TEXTURE_SIZE)
static uint2 _HPRW_TextureSize = uint2(_ScreenParams.xy + 0.5);
#else
static uint2 _HPRW_TextureSize = HPRW_SET_DATA_TEXTURE_SIZE;
#endif

static float3 _HPRW_TexelSize = float3(2.0 / float2(_HPRW_TextureSize), 0.0);

static float2 _HPRW_Temp = 0.0;

float2 HPRW_GetTexelPosition(uint id)
{
	float2 pos = float2(id % _HPRW_TextureSize.x, id / _HPRW_TextureSize.x);
	pos = pos * _HPRW_TexelSize.xy - 1.0;

#if UNITY_UV_STARTS_AT_TOP
	pos.y = -pos.y - _HPRW_TexelSize.y;
#endif
	
	return pos;
}

#define HPRW_TEXEL_GENERATION(id, clipPosition, stream)\
_HPRW_Temp = HPRW_GetTexelPosition(id);\
clipPosition.z = 0.999;\
clipPosition.w = 1.0;\
clipPosition.xy = _HPRW_Temp + _HPRW_TexelSize.zz;\
stream.Append(output);\
clipPosition.xy = _HPRW_Temp + _HPRW_TexelSize.xz;\
stream.Append(output);\
clipPosition.xy = _HPRW_Temp + _HPRW_TexelSize.zy;\
stream.Append(output);\
clipPosition.xy = _HPRW_Temp + _HPRW_TexelSize.xy;\
stream.Append(output);\
stream.RestartStrip();

#define HPRW_GET_TEXEL_DATA(tex, id) tex[uint2((id) % _HPRW_TextureSize.x, (id) / _HPRW_TextureSize.x)]



float L15bitToFP16(uint input)
{
	uint data = 0x38000000;
	data |= input & 0x80000000;
	data |= (input & 0x7FFE0000) >> 4;
	return asfloat(data);
}

float2 L15bitToFP16(uint2 input)
{
	uint2 data = 0x38000000;
	data |= input & 0x80000000;
	data |= (input & 0x7FFE0000) >> 4;
	return asfloat(data);
}

float3 L15bitToFP16(uint3 input)
{
	uint3 data = 0x38000000;
	data |= input & 0x80000000;
	data |= (input & 0x7FFE0000) >> 4;
	return asfloat(data);
}

float4 L15bitToFP16(uint4 input)
{
	uint4 data = 0x38000000;
	data |= input & 0x80000000;
	data |= (input & 0x7FFE0000) >> 4;
	return asfloat(data);
}



uint FP16ToL15bit(float input)
{
	uint temp0 = asuint(input);
	uint data = temp0 & 0x80000000;
	data |= (temp0 & 0x07FFE000) << 4;
	return data;
}

uint2 FP16ToL15bit(float2 input)
{
	uint2 temp0 = asuint(input);
	uint2 data = temp0 & 0x80000000;
	data |= (temp0 & 0x07FFE000) << 4;
	return data;
}

uint3 FP16ToL15bit(float3 input)
{
	uint3 temp0 = asuint(input);
	uint3 data = temp0 & 0x80000000;
	data |= (temp0 & 0x07FFE000) << 4;
	return data;
}

uint4 FP16ToL15bit(float4 input)
{
	uint4 temp0 = asuint(input);
	uint4 data = temp0 & 0x80000000;
	data |= (temp0 & 0x07FFE000) << 4;
	return data;
}



float L14bitToFP16(uint input)
{
	return asfloat(0x38000000 | ((input & 0xFFFC0000) >> 5));
}

float2 L14bitToFP16(uint2 input)
{
	return asfloat(0x38000000 | ((input & 0xFFFC0000) >> 5));
}

float3 L14bitToFP16(uint3 input)
{
	return asfloat(0x38000000 | ((input & 0xFFFC0000) >> 5));
}

float4 L14bitToFP16(uint4 input)
{
	return asfloat(0x38000000 | ((input & 0xFFFC0000) >> 5));
}



uint FP16ToL14bit(float input)
{
	return (asuint(input) & 0x07FFE000) << 5;
}

uint2 FP16ToL14bit(float2 input)
{
	return (asuint(input) & 0x07FFE000) << 5;
}

uint3 FP16ToL14bit(float3 input)
{
	return (asuint(input) & 0x07FFE000) << 5;
}

uint4 FP16ToL14bit(float4 input)
{
	return (asuint(input) & 0x07FFE000) << 5;
}

#endif // !defined(HUWA_TEXEL_READ_WRITE)
