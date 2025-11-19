#include "UnityCG.cginc"

#if !defined(UNITY_MATRIX_I_M)
#define UNITY_MATRIX_I_M unity_WorldToObject
#endif

struct I2V
{
    float4 lPos : POSITION;
};

struct V2F
{
    float4 cPos : SV_POSITION;
    float3 lRay : TEXCOORD0;
    float3 lStartPos : TEXCOORD1;
};

struct F2O
{
    float3 color : SV_Target;
    float depth : SV_Depth;
};

fixed4 _LightColor0;

V2F VertexShaderStage(I2V input)
{
    // カメラの位置(ワールド座標系)をローカル座標系に変換
    float3 localStartPos = mul(UNITY_MATRIX_I_M, float4(_WorldSpaceCameraPos, 1.0)).xyz;
    
    // ローカル座標系でRayを計算
    float3 lRay = input.lPos.xyz - localStartPos;
    
    V2F output = (V2F) 0;
    output.lStartPos = localStartPos;
    output.lRay = lRay;
    output.cPos = UnityObjectToClipPos(input.lPos);
    return output;
}

F2O FragmentShaderStage(V2F input)
{
    // 球とベクトルの交点を求める
    // https://tjkendev.github.io/procon-library/python/geometry/circle_line_cross_point.html
    
    // 半径
    float r = 0.4;
    
    float3 sp = input.lStartPos;
    float3 ray = input.lRay;
    
    // 2次方程式の解の公式のa,b,cを用意
    float a = dot(ray, ray);
    float b = dot(ray, sp) * 2.0;
    float c = dot(sp, sp) - r * r;
    
    // 2次方程式の解の公式の平方根の中
    float d = b * b - 4.0 * a * c;
    
    // dの平方根を計算する前に、dが0より小さいかを確認する
    // 0より小さい場合ピクセルを破棄する
    clip(d);
    d = sqrt(d);
    d = min(-b + d, -b - d);
    
    // dが0より小さいかを確認する
    // 0より小さい場合ピクセルを破棄する
    clip(d);
    
    // Rayと球体が衝突する座標(ローカル座標系)
    float3 lPos = sp + ray * (d / (a + a));
    
    
    
    float depth;
    {
        float4 wPos = mul(UNITY_MATRIX_M, float4(lPos, 1.0));
        depth = dot(UNITY_MATRIX_VP._m20_m21_m22_m23, wPos) / dot(UNITY_MATRIX_VP._m30_m31_m32_m33, wPos);
    
#if !defined(UNITY_REVERSED_Z) // OpenGL
        depth = depth * 0.5 + 0.5;
#endif
    }
    
    float3 color;
    {
        float3 wNormal = UnityObjectToWorldNormal(lPos);
        half3 ambient = ShadeSH9(half4(wNormal, 1.0));
        half diffuse = max(0.0, dot(wNormal, _WorldSpaceLightPos0.xyz));
        color = _LightColor0.rgb * diffuse + ambient;
    }
    
    F2O output = (F2O) 0;
    output.color = color;
    output.depth = depth;
    return output;
}
