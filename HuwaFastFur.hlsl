//Ver3 2022/12/19 06:46

#define UNITY_MATRIX_I_M unity_WorldToObject

#include "HuwaRandomFunction.hlsl"
#include "HuwaVertexLighting.hlsl"

struct VertexData
{
    float4 pos : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float2 uv : TEXCOORD0;
    float furCount : TEXCOORD1;
    half3 lightColor : COLOR;
    uint id : BLENDINDICES;
};

struct TessellationFactor
{
    float tessFactor[3] : SV_TessFactor;
    float insideTessFactor : SV_InsideTessFactor;
    float furCount : TEXCOORD;
};

struct FragmentData
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD;
    half3 lightColor : COLOR0;
    half transparency : COLOR1;
};

sampler2D _MainTex;
sampler2D _FurDirectionTex;
sampler2D _FurLengthTex;
sampler2D _AreaDataTex;

float _FurMaxLength;
float _FurRandomLength;
float _FurScaleWidth;
float _FurRoughness;
float _FurDensity;
float _FurSplit;
float _FurAbsorption;

float _ColorIntensity;
half3 _AmbientColorAdjustment;

static int _MaxFurPerPolygon = 30;
static int _MaxVertexCount = _MaxFurPerPolygon * 3;
static float _FurAbsorptionTemp = (_FurAbsorption + 1.0) * 0.5;
static float _MaxFurPerPolygonReciprocal = 1.0 / _MaxFurPerPolygon;
static float _ThreeReciprocal = 1.0 / 3.0;
static float _FurSplitTemp = _FurSplit * 2.0;

VertexData VertexStage(VertexData input, uint id : SV_VertexID)
{
    half3 lightColor = HVL_ShadeVertexLightsFull(input.pos.xyz, input.normal, _AmbientColorAdjustment, 0.5);
    input.lightColor = lerp(lightColor, half3(1.0, 1.0, 1.0), _ColorIntensity);
    input.id = id;
    return input;
}

[domain("tri")]
[partitioning("integer")]
[outputtopology("triangle_cw")]
[patchconstantfunc("PatchConstantFunction")]
[outputcontrolpoints(3)]
VertexData HullStage(InputPatch<VertexData, 3> input, uint id : SV_OutputControlPointID)
{
    return input[id];
}

TessellationFactor PatchConstantFunction(InputPatch<VertexData, 3> input)
{
    float2 areaDataUV = (input[0].uv + input[1].uv + input[2].uv) * _ThreeReciprocal;
    float areaData = tex2Dlod(_AreaDataTex, float4(areaDataUV, 0.0, 0.0)).r;
    float lengthData = tex2Dlod(_FurLengthTex, float4(areaDataUV, 0.0, 0.0)).r;
    
    float temp0 = lengthData * lengthData;
    float furCount = _FurDensity * areaData / (temp0 + (temp0 == 0.0));
    furCount *= temp0 > 0.01;
    
    float temp1 = furCount * _MaxFurPerPolygonReciprocal;
    float requiredTessFactor = clamp(ceil(temp1 * _ThreeReciprocal), 0.0, 64.0);
    bool noTess = ceil(temp1) == 1.0;
    
    float temp2 = lerp(requiredTessFactor * 3.0, 1.0, noTess);
    float furCountPerPolygon = furCount / (temp2 + (temp2 == 0.0));
    furCountPerPolygon *= temp2 > 0.0;
    
    TessellationFactor output = (TessellationFactor) 0;
    output.tessFactor[0] = requiredTessFactor;
    output.tessFactor[1] = requiredTessFactor;
    output.tessFactor[2] = requiredTessFactor;
    output.insideTessFactor = 2 - noTess;
    output.furCount = furCountPerPolygon;
    return output;
}

[domain("tri")]
VertexData DomainStage(TessellationFactor tf, const OutputPatch<VertexData, 3> input, float3 bary : SV_DomainLocation)
{
    float3 temp0 = input[0].tangent.xyz;
    float3 temp1 = input[1].tangent.xyz;
    float3 temp2 = input[2].tangent.xyz;
    
    VertexData output = (VertexData) 0;
    output.pos = bary.x * input[0].pos + bary.y * input[1].pos + bary.z * input[2].pos;
    output.normal = bary.x * input[0].normal + bary.y * input[1].normal + bary.z * input[2].normal;
    output.tangent = float4(bary.x * temp0 + bary.y * temp1 + bary.z * temp2, input[0].tangent.w);
    output.uv = bary.x * input[0].uv + bary.y * input[1].uv + bary.z * input[2].uv;
    output.lightColor = bary.x * input[0].lightColor + bary.y * input[1].lightColor + bary.z * input[2].lightColor;
    output.id = UIntToRandom(uint4(input[0].id, input[1].id, input[2].id, FloatToRandom(bary)));
    output.furCount = tf.furCount;
    return output;
}

[maxvertexcount(_MaxVertexCount)]
void GeometryStage(triangle VertexData input[3], inout TriangleStream<FragmentData> stream)
{
    float3 position_Origin = input[0].pos.xyz;
    float3 position_0 = input[1].pos.xyz - position_Origin;
    float3 position_1 = input[2].pos.xyz - position_Origin;
    
    float3 normal_Origin = input[0].normal;
    float3 normal_0 = input[1].normal - normal_Origin;
    float3 normal_1 = input[2].normal - normal_Origin;
    
    float3 tangent_Origin = input[0].tangent.xyz;
    float3 tangent_0 = input[1].tangent.xyz - tangent_Origin;
    float3 tangent_1 = input[2].tangent.xyz - tangent_Origin;
    
    float2 uv_Origin = input[0].uv;
    float2 uv_0 = input[1].uv - uv_Origin;
    float2 uv_1 = input[2].uv - uv_Origin;
    
    half3 lightColor_Origin = input[0].lightColor;
    half3 lightColor_0 = input[1].lightColor - lightColor_Origin;
    half3 lightColor_1 = input[2].lightColor - lightColor_Origin;
    
    float tangentW = input[0].tangent.w * unity_WorldTransformParams.w;
    float3 trueNormal = normalize(cross(position_0, position_1));
    
    uint random = UIntToRandom(uint3(input[0].id, input[1].id, input[2].id));
    float targetfurcount = input[0].furCount + RandomToFloatAbs(random) - 1.0;
    
    for (int count = 0; count < targetfurcount; ++count)
    {
        float2 moveFactor = (float2) 0;
        
        random = UIntToRandom(random);
        moveFactor.x = RandomToFloatAbs(random);
        random = UIntToRandom(random);
        moveFactor.y = RandomToFloatAbs(random);
        
        moveFactor = lerp(moveFactor, 1.0 - moveFactor, (moveFactor.x + moveFactor.y) > 1.0);
        
        float3 position = position_Origin + position_0 * moveFactor.x + position_1 * moveFactor.y;
        float3 normal = normalize(normal_Origin + normal_0 * moveFactor.x + normal_1 * moveFactor.y);
        float3 tangent = normalize(tangent_Origin + tangent_0 * moveFactor.x + tangent_1 * moveFactor.y);
        float3 binormal = cross(normal, tangent) * tangentW;
        float2 uv = uv_Origin + uv_0 * moveFactor.x + uv_1 * moveFactor.y;
        half3 lightColor = lightColor_Origin + lightColor_0 * moveFactor.x + lightColor_1 * moveFactor.y;
        
        float3 furRandomDirection = (float3) 0;
        
        random = UIntToRandom(random);
        float furRandomLength = RandomToFloatAbs(random);
        random = UIntToRandom(random);
        furRandomDirection.x = RandomToFloat(random);
        random = UIntToRandom(random);
        furRandomDirection.y = RandomToFloat(random);
        random = UIntToRandom(random);
        furRandomDirection.z = RandomToFloat(random);
        
        float furLength = tex2Dlod(_FurLengthTex, float4(uv, 0.0, 0.0)).r;
        furLength *= _FurMaxLength * (1.0 - furRandomLength * _FurRandomLength);
        
        float3 furDirection = UnpackNormal(tex2Dlod(_FurDirectionTex, float4(uv, 0.0, 0.0)));
        furDirection = tangent * furDirection.x + binormal * furDirection.y + normal * furDirection.z;
        furDirection = normalize(furDirection + furRandomDirection * _FurRoughness);
        furDirection = lerp(normal, furDirection, saturate(dot(normal, trueNormal)));
        
        float3 furWidthVector = normalize(cross(furDirection, furRandomDirection));
        furWidthVector *= furLength * _FurScaleWidth;
        
        furDirection *= furLength;
        
        FragmentData output = (FragmentData) 0;
        output.uv = uv;
        
        output.pos = UnityObjectToClipPos(position);
        output.lightColor = lightColor * _FurAbsorption;
        output.transparency = 0.0;
        stream.Append(output);
        
        output.pos = UnityObjectToClipPos(position + furDirection * 0.5 + furWidthVector);
        output.lightColor = lightColor * _FurAbsorptionTemp;
        output.transparency = 1.0;
        stream.Append(output);
        
        output.pos = UnityObjectToClipPos(position + furDirection);
        output.lightColor = lightColor;
        output.transparency = 0.0;
        stream.Append(output);
        
        stream.RestartStrip();
    }
}

half4 FragmentStage(FragmentData input) : SV_Target
{
    clip(-(floor(input.transparency * _FurSplitTemp) % 2.0));
    
    half3 col = tex2D(_MainTex, input.uv).rgb * input.lightColor;
    return half4(col, 1.0);
}
