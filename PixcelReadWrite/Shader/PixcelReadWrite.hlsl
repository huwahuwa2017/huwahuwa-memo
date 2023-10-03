#if !defined(PIXCEL_READ_WRITE)

#include "UnityCG.cginc"

static float2 _ClipSpacePixcelSize = float2(2.0 / _ScreenParams.x, 2.0 / _ScreenParams.y);

static float2 _ClipSpacePixcelOffset[] =
{
	float2(0.0, 0.0),
	float2(_ClipSpacePixcelSize.x, 0.0),
	float2(0.0, _ClipSpacePixcelSize.y),
	_ClipSpacePixcelSize
};

float2 GetPixcelPosition(uint id)
{
	float2 pos = float2(id % _ScreenParams.x, floor(id / _ScreenParams.x));
	pos = pos * _ClipSpacePixcelSize - 1.0;

#if UNITY_UV_STARTS_AT_TOP
	pos.y = -pos.y - _ClipSpacePixcelSize.y;
#endif
	
	return pos;
}

float4 GetPixcelData(Texture2D tex, float4 texelSize, uint id)
{
	return tex[int2(id % texelSize.z, id * texelSize.x)];
}

#endif