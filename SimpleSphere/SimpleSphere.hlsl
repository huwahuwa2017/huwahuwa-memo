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
    float3 lCameraPos : TEXCOORD1;
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
    float3 localCameraPos = mul(UNITY_MATRIX_I_M, float4(_WorldSpaceCameraPos, 1.0)).xyz;
    
    // ローカル座標系でRayを計算
    float3 lRay = input.lPos.xyz - localCameraPos;
    
    V2F output = (V2F) 0;
    output.lCameraPos = localCameraPos;
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
    
    float3 cp = input.lCameraPos;
    float3 ray = input.lRay;
    
    // 2次方程式の解の公式のa,b,cを用意
    float a = dot(ray, ray);
    float b = dot(ray, cp) * 2.0;
    float c = dot(cp, cp) - r * r;
    
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
    float3 lPos = cp + ray * (d / (a + a));
    // 法線(ワールド座標系)
    float3 wNormal = UnityObjectToWorldNormal(lPos);
    // lPosをワールド座標系に変換
    float3 wPos = mul(UNITY_MATRIX_M, float4(lPos, 1.0)).xyz;
    
    // 単純なライティングの計算
    half3 ambient = ShadeSH9(half4(wNormal, 1.0));
    half diffuse = max(0.0, dot(wNormal, _WorldSpaceLightPos0.xyz));
    float3 color = _LightColor0.rgb * diffuse + ambient;
    
    // Z深度の計算
    float depth = LinearEyeDepth(dot(wPos - _WorldSpaceCameraPos, -UNITY_MATRIX_I_V._m02_m12_m22));
    
    F2O output = (F2O) 0;
    output.color = color;
    output.depth = depth;
    return output;
}
