#include "UnityCG.cginc"

struct I2G
{
    float4 lPos : POSITION;
};

struct G2F
{
    float4 cPos : SV_POSITION;
};

int _Subdivision;

I2G VertexShaderStage(I2G input)
{
    return input;
}

[maxvertexcount(128)]
void GeometryShaderStage(triangle I2G input[3], uint primitiveID : SV_PrimitiveID, inout PointStream<G2F> stream)
{
    float4 pos0 = UnityObjectToClipPos(input[0].lPos);
    float4 pos1 = UnityObjectToClipPos(input[1].lPos);
    float4 pos2 = UnityObjectToClipPos(input[2].lPos);
    
    float4 s0 = pos1 - pos0;
    float4 s1 = pos2 - pos0;
    
    G2F output = (G2F) 0;
    
    float2 dtc = (float2(2.0, 1.0) / 3.0) / _Subdivision;
    float2 utc = (float2(1.0, 2.0) / 3.0) / _Subdivision;
    
    {
        float2 offset;
        float2 uv;
        
        for (int countX = 0; countX < _Subdivision; ++countX)
        {
            offset = float2(countX, countX) / _Subdivision;
        
            uv = offset + dtc;
            uv.x = 1.0 - uv.x;
        
            output.cPos = pos0 + (s0 * uv.x) + (s1 * uv.y);
            stream.Append(output);
        }
    }
    
    for (int countX = 1; countX < _Subdivision ; ++countX)
    {
        float2 offset;
        float2 uv;

        for (int countY = 0; countY < countX; ++countY)
        {
            offset = float2(countX, countY) / _Subdivision;
            
            uv = offset + dtc;
            uv.x = 1.0 - uv.x;
            
            output.cPos = pos0 + (s0 * uv.x) + (s1 * uv.y);
            stream.Append(output);
            
            uv = offset + utc;
            uv.x = 1.0 - uv.x;
            
            output.cPos = pos0 + (s0 * uv.x) + (s1 * uv.y);
            stream.Append(output);
        }
    }
}

half4 FragmentShaderStage(G2F input) : SV_Target
{
    return 1.0;
}
