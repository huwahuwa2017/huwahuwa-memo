#include "RandomFunction.hlsl"

static int _calculationRange1D[] =
{
	0,
	1
};

static int2 _calculationRange2D[] =
{
	int2(0, 0),
	int2(1, 0),
	int2(0, 1),
	int2(1, 1)
};

static int3 _calculationRange3D[] =
{
	int3(0, 0, 0),
	int3(1, 0, 0),
	int3(0, 1, 0),
	int3(1, 1, 0),
	int3(0, 0, 1),
	int3(1, 0, 1),
	int3(0, 1, 1),
	int3(1, 1, 1)
};

static int4 _calculationRange4D[] =
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

float Smooth(float t)
{
	return t * t * (t * -2.0 + 3.0);
	//return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float Grad1D(uint hash, float v)
{
	float nf = RandomToFloat(hash);
	return dot(v, nf);
}

float Grad2D(uint hash, float2 v)
{
	uint r1 = UIntToRandom(hash);
	float2 nf = float2(RandomToFloat(hash), RandomToFloat(r1));
	return dot(v, nf);
}

float Grad3D(uint hash, float3 v)
{
	uint r1 = UIntToRandom(hash);
	uint r2 = UIntToRandom(r1);
	float3 nf = float3(RandomToFloat(hash), RandomToFloat(r1), RandomToFloat(r2));
	return dot(v, nf);
}

float Grad4D(uint hash, float4 v)
{
	uint r1 = UIntToRandom(hash);
	uint r2 = UIntToRandom(r1);
	uint r3 = UIntToRandom(r2);
	float4 nf = float4(RandomToFloat(hash), RandomToFloat(r1), RandomToFloat(r2), RandomToFloat(r3));
	return dot(v, nf);
}

float BasicPerlinNoise1D(float position)
{
	int positionInt = floor(position);
	position -= positionInt;
	float temp[2];

	for (int index = 0; index < 2; ++index)
	{
		uint random = IntToRandom(positionInt + _calculationRange1D[index]);
		temp[index] = Grad1D(random, position - _calculationRange1D[index]);
	}

	float sx = Smooth(position.x);
	
	return lerp(temp[0], temp[1], sx);
}

float BasicPerlinNoise2D(float2 position)
{
	int2 positionInt = floor(position);
	position -= positionInt;
	float temp[4];

	for (int index = 0; index < 4; ++index)
	{
		uint random = IntToRandom(positionInt + _calculationRange2D[index]);
		temp[index] = Grad2D(random, position - _calculationRange2D[index]);
	}

	float sx = Smooth(position.x);
	float sy = Smooth(position.y);
	
	float tempX[] =
	{
		lerp(temp[0], temp[1], sx),
		lerp(temp[2], temp[3], sx)
	};
	
	return lerp(tempX[0], tempX[1], sy);
}

float BasicPerlinNoise3D(float3 position)
{
	int3 positionInt = floor(position);
	position -= positionInt;
	float temp[8];

	for (int index = 0; index < 8; ++index)
	{
		uint random = IntToRandom(positionInt + _calculationRange3D[index]);
		temp[index] = Grad3D(random, position - _calculationRange3D[index]);
	}

	float sx = Smooth(position.x);
	float sy = Smooth(position.y);
	float sz = Smooth(position.z);
	
	float tempX[] =
	{
		lerp(temp[0], temp[1], sx),
		lerp(temp[2], temp[3], sx),
		lerp(temp[4], temp[5], sx),
		lerp(temp[6], temp[7], sx)
	};
	
	float tempY[] =
	{
		lerp(tempX[0], tempX[1], sy),
		lerp(tempX[2], tempX[3], sy)
	};
	
	return lerp(tempY[0], tempY[1], sz);
}

float BasicPerlinNoise4D(float4 position)
{
	int4 positionInt = floor(position);
	position -= positionInt;
	float temp[16];

	for (int index = 0; index < 16; ++index)
	{
		uint random = IntToRandom(positionInt + _calculationRange4D[index]);
		temp[index] = Grad4D(random, position - _calculationRange4D[index]);
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

float PerlinNoise1D(float position, float scale = 1, int detail = 1)
{
	float noise = 0.0;
	float maxValue = 0.0;
	int shrink = 1;

	for (int count = 0; count < detail; ++count)
	{
		noise += BasicPerlinNoise1D(position / scale * shrink) / shrink;
		maxValue += 1.0 / shrink;
		shrink *= 2;
	}

	return noise / maxValue;

}

float PerlinNoise2D(float2 position, float scale = 1, int detail = 1)
{
	float noise = 0.0;
	float maxValue = 0.0;
	int shrink = 1;

	for (int count = 0; count < detail; ++count)
	{
		noise += BasicPerlinNoise2D(position / scale * shrink) / shrink;
		maxValue += 1.0 / shrink;
		shrink *= 2;
	}

	return noise / maxValue;
}

float PerlinNoise3D(float3 position, float scale = 1, int detail = 1)
{
	float noise = 0.0;
	float maxValue = 0.0;
	int shrink = 1;

	for (int count = 0; count < detail; ++count)
	{
		noise += BasicPerlinNoise3D(position / scale * shrink) / shrink;
		maxValue += 1.0 / shrink;
		shrink *= 2;
	}

	return noise / maxValue;
}

float PerlinNoise4D(float4 position, float scale = 1, int detail = 1)
{
	float noise = 0.0;
	float maxValue = 0.0;
	int shrink = 1;

	for (int count = 0; count < detail; ++count)
	{
		noise += BasicPerlinNoise4D(position / scale * shrink) / shrink;
		maxValue += 1.0 / shrink;
		shrink *= 2;
	}

	return noise / maxValue;
}
