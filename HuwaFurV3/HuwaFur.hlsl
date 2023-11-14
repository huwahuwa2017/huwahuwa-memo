// Ver7 2023/11/15 02:24

#define UNITY_MATRIX_I_M unity_WorldToObject

#include "UnityCG.cginc"
#include "HuwaRandomFunction.hlsl"

struct TessellationFactor_Fur
{
	float tessFactor[3] : SV_TessFactor;
	float insideTessFactor : SV_InsideTessFactor;
	float furCount : TEXCOORD0;
};

struct I2V_Fur
{
	float4 lPos : POSITION;
	float3 lNormal : NORMAL;
	float4 lTangent : TANGENT;
	uint id : SV_VertexID;
	float2 uv : TEXCOORD0;
};

struct V2G_Fur
{
	float3 wPos : TEXCOORD0;
	float3 wNormal : TEXCOORD1;
	float4 wTangent : TEXCOORD2;
	uint random : TEXCOORD3;
	float2 uv : TEXCOORD4;
	half3 ambient : TEXCOORD5;
	float furCount : TEXCOORD6;
};

struct G2F_Fur
{
	float4 cPos : SV_POSITION;
	half3 color : TEXCOORD0;
	half2 uv : TEXCOORD1;
};

struct I2V_Skin
{
	float4 lPos : POSITION;
	float3 lNormal : NORMAL;
	float2 uv : TEXCOORD0;
};

struct V2F_Skin
{
	float4 cPos : SV_POSITION;
	float2 uv : TEXCOORD0;
	float3 wPos : TEXCOORD1;
	float3 wNormal : TEXCOORD2;
#if defined(SHADOWS_SCREEN)
	float3 cspXYW : TEXCOORD3;
#endif
};

sampler2D _ShadowMapTexture;
half4 _LightColor0;

sampler2D _MainTex;
sampler2D _FurDirectionTex;
sampler2D _FurLengthTex;

Texture2D _AreaDataTex;
float4 _AreaDataTex_TexelSize;

float _FurLength;
float _FurWidth;
float _FurRandomLength;
float _FurRandomDirection;
float _FurDensity;
int _FurSplit;

float _FurAbsorption;
float _DiffuseOffset;
float _BaseColorStrength;

static int _MaxFurPerPolygon = 24;
static int _MaxVertexCount = _MaxFurPerPolygon * 3;

#define SetDataTextureTexelSize _AreaDataTex_TexelSize
#include "HuwaPixcelReadWrite.hlsl"

// Created based on VertexGIForward
half3 SimpleGI(float3 wPos, half3 wNormal)
{
	half3 pointLights = Shade4PointLights(
		unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
		unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
		unity_4LightAtten0, wPos, wNormal);
	
	return pointLights + max(0.0, ShadeSH9(half4(wNormal, 1.0)));
}

// Created based on UNITY_SHADOW_ATTENUATION
// cspXYW = computeScreenPos.xyw
half SimpleShadowAttenuation(float3 cspXYW)
{
#if defined(DIRECTIONAL) && \
	!defined(UNITY_STEREO_MULTIVIEW_ENABLED) && !defined(UNITY_STEREO_INSTANCING_ENABLED) && \
	defined(SHADOWS_SCREEN) && !defined(UNITY_NO_SCREENSPACE_SHADOWS)
	float4 coord = float4(cspXYW.xy / cspXYW.z, 0.0, 0.0);
	return tex2Dlod(_ShadowMapTexture, coord).r;
#else
	return 1.0;
#endif
}



V2F_Skin VertexShaderStage_Skin(I2V_Skin input)
{
	float3 wPos = mul(UNITY_MATRIX_M, input.lPos);
	float3 wNormal = mul(input.lNormal, (float3x3) UNITY_MATRIX_I_M);
	
	V2F_Skin output = (V2F_Skin) 0;
	output.cPos = UnityWorldToClipPos(wPos);
	output.uv = input.uv;
	output.wPos = wPos;
	output.wNormal = wNormal;
#if defined(SHADOWS_SCREEN)
	output.cspXYW = ComputeScreenPos(output.cPos).xyw;
#endif
	return output;
}

half4 FragmentShaderStage_Skin(V2F_Skin input) : SV_Target
{
	float3 wNormal = normalize(input.wNormal);
	
	half3 ambient = SimpleGI(input.wPos, wNormal);
	
	float attenuation = 1.0;
	
#if defined(SHADOWS_SCREEN)
	attenuation = SimpleShadowAttenuation(input.cspXYW);
#endif
	
	half3 lightColor = _LightColor0 * attenuation * saturate(dot(wNormal, _WorldSpaceLightPos0.xyz) + _DiffuseOffset);
	half3 color = tex2Dlod(_MainTex, float4(input.uv, 0, 0)).rgb;
	color *= lerp(lightColor + ambient, 1.0, _BaseColorStrength);
	color *= _FurAbsorption;
	
	return half4(color, 1.0);
}



V2G_Fur VertexShaderStage_Fur(I2V_Fur input)
{
	float3 wPos = mul(UNITY_MATRIX_M, input.lPos);
	float3 wNormal = mul(input.lNormal, (float3x3) UNITY_MATRIX_I_M);
	float3 wTangent = mul(UNITY_MATRIX_M, float4(input.lTangent.xyz, 0.0));
	half3 ambient = SimpleGI(wPos, wNormal);
	
	V2G_Fur output = (V2G_Fur) 0;
	output.wPos = wPos;
	output.wNormal = wNormal;
	output.wTangent = float4(wTangent, input.lTangent.w);
	output.random = input.id;
	output.uv = input.uv;
	output.ambient = ambient;
	return output;
}

[domain("tri")]
[partitioning("integer")]
[outputtopology("triangle_cw")]
[patchconstantfunc("PatchConstantFunction_Fur")]
[outputcontrolpoints(3)]
V2G_Fur HullShaderStage_Fur(InputPatch<V2G_Fur, 3> input, uint id : SV_OutputControlPointID)
{
	return input[id];
}

TessellationFactor_Fur PatchConstantFunction_Fur(InputPatch<V2G_Fur, 3> input, uint primitiveID : SV_PrimitiveID)
{
	float2 centerUV = (input[0].uv + input[1].uv + input[2].uv) / 3.0;
	float areaData = GetPixcelData(_AreaDataTex, primitiveID).r;
	areaData *= areaData;
	float lengthData = tex2Dlod(_FurLengthTex, float4(centerUV, 0.0, 0.0)).r;
	float temp0 = lengthData * lengthData;
	float furCount = _FurDensity * areaData / (temp0 + (temp0 == 0.0));
	furCount *= temp0 != 0.0;
	
	bool noTess = furCount <= _MaxFurPerPolygon;
	
	float requiredTessFactor = min(ceil(furCount / (_MaxFurPerPolygon * 3.0)), 64.0);
	float polygonCount = noTess ? 1.0 : requiredTessFactor * 3.0;
	
	TessellationFactor_Fur output = (TessellationFactor_Fur) 0;
	output.tessFactor[0] = requiredTessFactor;
	output.tessFactor[1] = requiredTessFactor;
	output.tessFactor[2] = requiredTessFactor;
	output.insideTessFactor = 2.0 - noTess;
	output.furCount = furCount / polygonCount;
	return output;
}

[domain("tri")]
V2G_Fur DomainShaderStage_Fur(TessellationFactor_Fur tf, const OutputPatch<V2G_Fur, 3> input, float3 bary : SV_DomainLocation)
{
	V2G_Fur output = (V2G_Fur) 0;
	output.wPos = bary.x * input[0].wPos + bary.y * input[1].wPos + bary.z * input[2].wPos;
	output.wNormal = bary.x * input[0].wNormal + bary.y * input[1].wNormal + bary.z * input[2].wNormal;
	output.wTangent = float4(bary.x * input[0].wTangent.xyz + bary.y * input[1].wTangent.xyz + bary.z * input[2].wTangent.xyz, input[0].wTangent.w);
	output.uv = bary.x * input[0].uv + bary.y * input[1].uv + bary.z * input[2].uv;
	output.ambient = bary.x * input[0].ambient + bary.y * input[1].ambient + bary.z * input[2].ambient;
	output.random = ValueToRandom(uint4(input[0].random, input[1].random, input[2].random, ValueToRandom(bary)));
	output.furCount = tf.furCount;
	return output;
}

[maxvertexcount(_MaxVertexCount)]
void GeometryShaderStage_Fur(triangle V2G_Fur input[3], inout TriangleStream<G2F_Fur> stream)
{
	float3 position_Origin = input[0].wPos;
	float3 position_0 = input[1].wPos - position_Origin;
	float3 position_1 = input[2].wPos - position_Origin;
	
	float3 normal_Origin = input[0].wNormal;
	float3 normal_0 = input[1].wNormal - normal_Origin;
	float3 normal_1 = input[2].wNormal - normal_Origin;
	
	float3 tangent_Origin = input[0].wTangent.xyz;
	float3 tangent_0 = input[1].wTangent.xyz - tangent_Origin;
	float3 tangent_1 = input[2].wTangent.xyz - tangent_Origin;
	
	float2 uv_Origin = input[0].uv;
	float2 uv_0 = input[1].uv - uv_Origin;
	float2 uv_1 = input[2].uv - uv_Origin;
	
	half3 ambient_Origin = input[0].ambient;
	half3 ambient_0 = input[1].ambient - ambient_Origin;
	half3 ambient_1 = input[2].ambient - ambient_Origin;
	
	float tangentW = input[0].wTangent.w * unity_WorldTransformParams.w;
	float3 trueNormal = normalize(cross(position_0, position_1));
	
	uint random = ValueToRandom(uint3(input[0].random, input[1].random, input[2].random));
	float targetFurCount = input[0].furCount + RandomToFloatAbs(random) - 1.0;
	
	for (int count = 0; count < targetFurCount; ++count)
	{
		float2 moveFactor = 0.0;
		
		random = ValueToRandom(random);
		moveFactor.x = RandomToFloatAbs(random);
		random = ValueToRandom(random);
		moveFactor.y = RandomToFloatAbs(random);
		
		moveFactor = float2(1.0 - max(moveFactor.x, moveFactor.y), min(moveFactor.x, moveFactor.y));
		
		float3 position = position_Origin + position_0 * moveFactor.x + position_1 * moveFactor.y;
		float3 normal = normalize(normal_Origin + normal_0 * moveFactor.x + normal_1 * moveFactor.y);
		float3 tangent = normalize(tangent_Origin + tangent_0 * moveFactor.x + tangent_1 * moveFactor.y);
		float3 binormal = cross(normal, tangent) * tangentW;
		float2 uv = uv_Origin + uv_0 * moveFactor.x + uv_1 * moveFactor.y;
		half3 ambient = ambient_Origin + ambient_0 * moveFactor.x + ambient_1 * moveFactor.y;
		
		float3 furRandomDirection = 0.0;
		
		random = ValueToRandom(random);
		float furRandomLength = RandomToFloatAbs(random);
		random = ValueToRandom(random);
		furRandomDirection.x = RandomToFloat(random);
		random = ValueToRandom(random);
		furRandomDirection.y = RandomToFloat(random);
		random = ValueToRandom(random);
		furRandomDirection.z = RandomToFloat(random);
		
		float furLength = tex2Dlod(_FurLengthTex, float4(uv, 0.0, 0.0)).r;
		furLength *= _FurLength * (1.0 - furRandomLength * _FurRandomLength);
		
		float3 furDirection = UnpackNormal(tex2Dlod(_FurDirectionTex, float4(uv, 0.0, 0.0)));
		furDirection = tangent * furDirection.x + binormal * furDirection.y + normal * furDirection.z;
		furDirection = normalize(furDirection + furRandomDirection * _FurRandomDirection);
		furDirection = lerp(normal, furDirection, saturate(dot(normal, trueNormal)));
		
		float3 furWidthVector = normalize(cross(furDirection, furRandomDirection));
		furWidthVector *= furLength * _FurWidth;
		
		furDirection *= furLength;
		
		float4 cPos = UnityWorldToClipPos(position);
		
		float attenuation = 1.0;
		
#if defined(SHADOWS_SCREEN)
		float3 cspXYW = ComputeScreenPos(cPos).xyw;
		attenuation = SimpleShadowAttenuation(cspXYW);
#endif
		
		half3 lightColor = _LightColor0 * attenuation * saturate(dot(normal, _WorldSpaceLightPos0.xyz) + _DiffuseOffset);
		half3 color = tex2Dlod(_MainTex, float4(uv, 0, 0)).rgb;
		color *= lerp(lightColor + ambient, 1.0, _BaseColorStrength);
		
		G2F_Fur output = (G2F_Fur) 0;
		
		output.cPos = cPos;
		output.color = color * _FurAbsorption;
		output.uv = half2(0.0, 0.0);
		stream.Append(output);
		
		output.cPos = UnityWorldToClipPos(position + furDirection * 0.5 + furWidthVector);
		output.color = color * ((_FurAbsorption + 1.0) * 0.5);
		output.uv = half2(1.0, 0.5);
		stream.Append(output);
		
		output.cPos = UnityWorldToClipPos(position + furDirection);
		output.color = color;
		output.uv = half2(0.0, 1.0);
		stream.Append(output);
		
		stream.RestartStrip();
	}
}

half4 FragmentShaderStage_Fur(G2F_Fur input) : SV_Target
{
	float temp1 = (input.uv.y - input.uv.y * input.uv.y) * 4.0;
	float temp0 = floor((input.uv.x / temp1 * _FurSplit * 2) % 2.0);
	
	clip(0.5 - temp0);
	
	return half4(input.color, 1.0);
}
