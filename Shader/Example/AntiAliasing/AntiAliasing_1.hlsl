
#include "UnityCG.cginc"

struct I2V
{
    float4 lPos : POSITION;
    float2 uv : TEXCOORD0;
};

struct V2F
{
    float4 cPos : SV_POSITION;
    float2 uv : TEXCOORD0;
};

sampler2D _MainTex;
float4 _MainTex_TexelSize;

uint _Difference;
uint _ViewOriginalColor;
float _OffsetLOD;

V2F VertexShaderStage(I2V input)
{
    V2F output = (V2F) 0;
    output.cPos = UnityObjectToClipPos(input.lPos);
    output.uv = input.uv;
    return output;
}

half4 FragmentShaderStage(V2F input) : SV_Target
{
    float2 size = _MainTex_TexelSize.zw;
    
    float2 uv = input.uv;
    uv = mul(float2x2(0.707, 0.707, -0.707, 0.707), uv);
    
    // uv の値が大きくなると誤差も大きくなる
    // かといって uv を frac 関数に直接入れると、
    // 繰り返し部分の ddx, ddy が正しく計算できなりエイリアスが発生する
    // なので少し工夫する必要がある
    uv.x += frac(_Time.x);
    
    
    
    float2 dx, dy;
    {
        float2 temp00 = uv * size;
        dx = ddx(temp00);
        dy = ddy(temp00);
    }
    
    float lod = max(length(dx), length(dy));
    lod = log2(lod) + _OffsetLOD;
    
    half4 resultColors = tex2Dlod(_MainTex, float4(uv, 0.0, lod));
    
    
    
    // 比較用
    half4 originalColor = tex2D(_MainTex, uv);
    
    half4 output = _ViewOriginalColor ? originalColor : resultColors;
    output = _Difference ? abs(resultColors - originalColor) : output;
    return output;
}
