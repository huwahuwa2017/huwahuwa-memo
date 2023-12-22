// Ver6 2023/12/22 16:49

#if !defined(HUWA_PIXCEL_READ_WRITE)
#define HUWA_PIXCEL_READ_WRITE

#include "UnityCG.cginc"

#if !defined(HPRW_SetDataTextureSize)
static uint2 _HPRW_TextureSize = uint2(_ScreenParams.xy + 0.5);
#else
static uint2 _HPRW_TextureSize = HPRW_SetDataTextureSize;
#endif

// ClipSpaceTexelSize
static float3 _HPRW_TexelSize = float3(2.0 / float2(_HPRW_TextureSize), 0.0);

// Temp
static float2 _HPRW_Temp = 0.0;

// GetClipSpaceTexelPosition
float2 GetTexelPosition(uint id)
{
	float2 pos = float2(id % _HPRW_TextureSize.x, id / _HPRW_TextureSize.x);
	pos = pos * _HPRW_TexelSize.xy - 1.0;

#if UNITY_UV_STARTS_AT_TOP
	pos.y = -pos.y - _HPRW_TexelSize.y;
#endif
	
	return pos;
}

#define PixcelGeneration(id, clipPosition, stream)\
_HPRW_Temp = GetTexelPosition(id);\
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

float4 GetPixcelData(Texture2D tex, uint id)
{
	return tex[uint2(id % _HPRW_TextureSize.x, id / _HPRW_TextureSize.x)];
}

#endif // !defined(HUWA_PIXCEL_READ_WRITE)
