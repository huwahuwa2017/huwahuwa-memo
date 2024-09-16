#include "HuwaTexelReadWrite.hlsl"

struct I2V
{
    float4 lPos : POSITION;
    float2 uv : TEXCOORD0;
};

struct V2G
{
    float3 wPos : TEXCOORD0;
    float2 uv : TEXCOORD1;
};

struct G2F
{
    float4 cPos : SV_POSITION;
    float4 data : TEXCOORD0;
};
            
Texture2D _FurLengthTex;
float4 _FurLengthTex_TexelSize;

float2 _DataTextureTexelSize;
int _SubdivisionSample;
float _ShortFurDensity;

// CutOutを使っている時点でジャギるので、サンプラーを犠牲にして処理速度を優先する
#define TEXTURE_READ(tex, uv) tex[uint2(frac(uv) * tex##_TexelSize.zw)]

float SafeDivision(float a, float b)
{
    return (b == 0.0) ? 0.0 : a / b;
}

V2G VertexShaderStage(I2V input)
{
    V2G output = (V2G) 0;
    output.wPos = mul(UNITY_MATRIX_M, input.lPos).xyz;
    output.uv = input.uv;
    return output;
}

[maxvertexcount(4)]
void GeometryShaderStage(triangle V2G input[3], inout TriangleStream<G2F> stream, uint primitiveID : SV_PrimitiveID)
{
    // 毛の長さの平均を計算
    float furLength = 0.0;
    {
        int sc = 0;
        
        float2 origin = input[0].uv;
        float2 s0 = input[1].uv - origin;
        float2 s1 = input[2].uv - origin;
        
        float2 dtc = (float2(2.0, 1.0) / 3.0) / _SubdivisionSample;
        float2 utc = (float2(1.0, 2.0) / 3.0) / _SubdivisionSample;
        
        [loop]
        for (int countX = 0; countX < _SubdivisionSample; ++countX)
        {
            float2 offset;
            float2 tPos;
            float data;
            bool temp0;
            
            [loop]
            for (int countY = 0; countY < countX; ++countY)
            {
                offset = float2(countX, countY) / _SubdivisionSample;
                
                tPos = offset + dtc;
                tPos.x = 1.0 - tPos.x;
                data = TEXTURE_READ(_FurLengthTex, origin + (s0 * tPos.x) + (s1 * tPos.y)).r;
                temp0 = data > 0.01;
                furLength += temp0 ? data : 0.0;
                sc += temp0;
                
                tPos = offset + utc;
                tPos.x = 1.0 - tPos.x;
                data = TEXTURE_READ(_FurLengthTex, origin + (s0 * tPos.x) + (s1 * tPos.y)).r;
                temp0 = data > 0.01;
                furLength += temp0 ? data : 0.0;
                sc += temp0;
            }

            offset = float2(countX, countX) / _SubdivisionSample;
            
            tPos = offset + dtc;
            tPos.x = 1.0 - tPos.x;
            data = TEXTURE_READ(_FurLengthTex, origin + (s0 * tPos.x) + (s1 * tPos.y)).r;
            temp0 = data > 0.01;
            furLength += temp0 ? data : 0.0;
            sc += temp0;
        }

        furLength = SafeDivision(furLength, sc);
    }
    
    // ポリゴンの面積を計算
    float area = length(cross(input[1].wPos - input[0].wPos, input[2].wPos - input[0].wPos)) * 0.5;
    
    // 毛の本数を計算
    float furCount = SafeDivision(area, pow(furLength, _ShortFurDensity));
    
    G2F output = (G2F) 0;
    output.data = float4(furCount, 0.0, 0.0, 1.0);
                
    HTRW_SET_WRITE_TEXTURE_SIZE(uint2(_DataTextureTexelSize + 0.5))
    HTRW_TEXEL_WRITE(primitiveID, output.cPos, stream)
}

float4 FragmentShaderStage(G2F input) : SV_Target
{
    return input.data;
}
