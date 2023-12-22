// Ver3 2023/12/22 14:25

#if !defined(HUWA_PIXCEL_READ_WRITE)
#define HUWA_PIXCEL_READ_WRITE

#include "UnityCG.cginc"

#if !defined(SetDataTextureTexelSize)
static float4 _HPRW54300853 = float4(1.0 / _ScreenParams.xy, _ScreenParams.xy);
#define SetDataTextureTexelSize _HPRW54300853
#endif

// ClipSpacePixcelSize
static float3 _HPRW65645850 = float3(SetDataTextureTexelSize.xy * 2.0, 0.0);

// Temp
static float2 _HPRW23994811;

// GetClipSpacePixcelPosition
float2 HPRW13828804(uint id)
{
	float2 pos = float2(id % SetDataTextureTexelSize.z, floor(id * SetDataTextureTexelSize.x));
	pos = pos * _HPRW65645850.xy - 1.0;

#if UNITY_UV_STARTS_AT_TOP
	pos.y = -pos.y - _HPRW65645850.y;
#endif
	
	return pos;
}

#define PixcelGeneration(id, clipPosition, stream)\
_HPRW23994811 = HPRW13828804(id);\
clipPosition.w = 1.0;\
clipPosition.xy = _HPRW23994811 + _HPRW65645850.zz;\
stream.Append(output);\
clipPosition.xy = _HPRW23994811 + _HPRW65645850.xz;\
stream.Append(output);\
clipPosition.xy = _HPRW23994811 + _HPRW65645850.zy;\
stream.Append(output);\
clipPosition.xy = _HPRW23994811 + _HPRW65645850.xy;\
stream.Append(output);\
stream.RestartStrip();

float4 GetPixcelData(Texture2D tex, uint id)
{
	return tex[uint2(id % SetDataTextureTexelSize.z, id * SetDataTextureTexelSize.x)];
}

#endif // HUWA_PIXCEL_READ_WRITE
