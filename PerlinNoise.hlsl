#include "RandomFunction.hlsl"

static int4 _calculationRange[] =
{
	int4(0, 0, 0, 0),
	int4(1, 0, 0, 0),
	int4(0, 1, 0, 0),
	int4(1, 1, 0, 0),
	int4(0, 0, 1, 0),
	int4(1, 0, 1, 0),
	int4(0, 1, 1, 0),
	int4(1, 1, 1, 0),
	int4(0, 0, 0, 1),
	int4(1, 0, 0, 1),
	int4(0, 1, 0, 1),
	int4(1, 1, 0, 1),
	int4(0, 0, 1, 1),
	int4(1, 0, 1, 1),
	int4(0, 1, 1, 1),
	int4(1, 1, 1, 1)
};

float Grad(uint hash, float4 v)
{
	float temp[] =
	{
		v.x + v.y,
		v.y + v.z,
		v.z + v.w,
		v.w + v.x,
		-v.x + v.y,
		-v.y + v.z,
		-v.z + v.w,
		-v.w + v.x,
		v.x - v.y,
		v.y - v.z,
		v.z - v.w,
		v.w - v.x,
		-v.x - v.y,
		-v.y - v.z,
		-v.z - v.w,
		-v.w - v.x
	};
	
	return temp[hash & 15];
}

float Smooth(float t)
{
	return t * t * (t * -2.0 + 3.0);
	//return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float BasicPerlinNoise(float4 position)
{
	int4 positionInt = floor(position);
	position -= positionInt;
	float temp[16];

	for (int index = 0; index < 16; ++index)
	{
		uint random = IntToRandom(positionInt + _calculationRange[index]);
		temp[index] = Grad(random, position - _calculationRange[index]);
	}

	float sx = Smooth(position.x);
	float sy = Smooth(position.y);
	float sz = Smooth(position.z);
	float sw = Smooth(position.w);
	
	float tempX[] =
	{
		lerp(temp[0], temp[1], sx),
		lerp(temp[2], temp[3], sx),
		lerp(temp[4], temp[5], sx),
		lerp(temp[6], temp[7], sx),
		lerp(temp[8], temp[9], sx),
		lerp(temp[10], temp[11], sx),
		lerp(temp[12], temp[13], sx),
		lerp(temp[14], temp[15], sx)
	};
	
	float tempY[] =
	{
		lerp(tempX[0], tempX[1], sy),
		lerp(tempX[2], tempX[3], sy),
		lerp(tempX[4], tempX[5], sy),
		lerp(tempX[6], tempX[7], sy)
	};
	
	float tempZ[] =
	{
		lerp(tempY[0], tempY[1], sz),
		lerp(tempY[2], tempY[3], sz)
	};
	
	return lerp(tempZ[0], tempZ[1], sw);
}

float PerlinNoise(float4 position, float scale = 1, int detail = 1)
{
	float noise = 0.0;
	float maxValue = 0.0;
	int shrink = 1;

	for (int count = 0; count < detail; ++count)
	{
		noise += BasicPerlinNoise(position / scale * shrink) / shrink;
		maxValue += 1.0 / shrink;
		shrink *= 2;
	}

	return noise / maxValue;
}

float PerlinNoise(float3 position, float scale = 1, int detail = 1)
{
	return PerlinNoise(float4(position, 0.5), scale, detail);
}

float PerlinNoise(float2 position, float scale = 1, int detail = 1)
{
	return PerlinNoise(float4(position, 0.5, 0.5), scale, detail);
}

float PerlinNoise(float position, float scale = 1, int detail = 1)
{
	return PerlinNoise(float4(position, 0.5, 0.5, 0.5), scale, detail);
}
