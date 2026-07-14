
Shader"Custom/Example"
{
    // https://docs.unity3d.com/ja/2022.3/Manual/SL-Properties.html
    // https://docs.unity3d.com/ja/2022.3/Manual/SL-PropertiesInPrograms.html
    // https://artawa.hatenablog.com/entry/2020/08/30/200211
    // https://tsubakit1.hateblo.jp/entry/2014/07/23/095513
    Properties
    {
        [NoScaleOffset]
        _MainTex("Skin Color Texture", 2D) = "white" {}
        
        _ExampleName ("Cubemap", Cube) = "" {}

        _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        
        [HDR]
        _EmissionColor("Emission Color", Color) = (0,0,0)
        
        [Gamma]
        _TestVector0("Vector0", Vector) = (1.0, 1.0, 1.0, 1.0)
        
        _Metallic("Metallic", Range(0.0, 1.0)) = 1.0
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 1.0
        
        _MaxSize("Max Size", Float) = 0.1
        
        
        
        [Header("ヘッダー名")]
        [Space(48)]
        
        // Unity 2020 以前
        _Integer("Integer", Int) = 0
        
        // Unity 2021 以後
        _ExampleName ("Integer display name", Integer) = 1
    }
    
    SubShader
    {
        CGINCLUDE
        // ここにコードを書くと、
        // すべてのパスでこのコードを書き込んだことになる
        ENDCG
        
        // https://docs.unity3d.com/ja/2022.3/Manual/SL-SubShaderTags.html
        Tags
        {
            // Queue が 2500 以下は不透明 (Render.OpaqueGeometry)
            // Queue が 2500 以下かつ同じ値のオブジェクトが複数ある場合、
            // ランダムな順番(ソートしない)で描画する
            
            // Queue が 2501 以上は半透明   (Render.TransparentGeometry)
            // Queue が 2501 以上かつ同じ値のオブジェクトが複数ある場合、
            // 遠いオブジェクトから先に描画する
            
            // Background = 1000, Geometry = 2000, AlphaTest = 2450, Transparent = 3000, Overlay = 4000
            "Queue" = "Background" "Geometry" "AlphaTest" "Transparent" "Overlay" "Overlay+815199"
            
            // 動的バッチングを無効化する
            "DisableBatching" = "True"
            
            // プロジェクターコンポーネントの対象外にする
            "IgnoreProjector" = "True"
            
            // https://docs.unity3d.com/ja/2022.3/Manual/SL-ShaderReplacement.html
            // Shaderを置き換えるときの判定に使う
            // DepthTextureMode.DepthNormals でも使うらしい
            // RenderType の違いで負荷が変わるという噂があるが未検証
            // VRCのアバター用Shaderであれば設定しなくても良いと思う
            "RenderType" = "Opaque" "Transparent" "TransparentCutout" "Background" "Overlay"
            
            // VRChat用
            // https://creators.vrchat.com/avatars/shader-fallback-system/
            "VRCFallback" = "Hidden"
        }
        
        https://docs.unity3d.com/ja/2019.4/Manual/SL-ShaderLOD.html
        LOD 100
        
        GrabPass
        {
            "_GrabPass"
        }
        
        Pass
        {
            // https://docs.unity3d.com/ja/2022.3/Manual/shader-shaderlab-commands.html
            AlphaToMask On
            Blend SrcAlpha OneMinusSrcAlpha
            BlendOp
            ColorMask 0
            Conservative True
            Cull Back Front Off
            Offset
            ZClip False
            ZTest Always
            ZWrite Off
            
            Stencil
            {
                Ref 2
                Comp Always
                Pass Replace
            }
            
            // https://docs.unity3d.com/ja/2022.3/Manual/shader-predefined-pass-tags-built-in.html
            Tags
            {
                // LightMode に Unity が想定していない文字列を入れると、そのパスは実行されなくなる
                // これを利用しているのが lilToon の "LightMode" = "Never"
                "LightMode" = "Always" "ForwardBase" "ForwardAdd" "ShadowCaster"
            }
            
            CGPROGRAM
            
            // https://docs.unity3d.com/ja/2022.3/Manual/SL-PragmaDirectives.html
            // https://docs.unity3d.com/ja/2022.3/Manual/SL-ShaderCompileTargets.html
            #pragma target 3.0
            #pragma require tessellation
            #pragma require geometry
            #pragma exclude_renderers gles
            
            #pragma vertex VertexShaderStage
            #pragma hull HullShaderStage
            #pragma domain DomainShaderStage
            #pragma geometry GeometryShaderStage
            #pragma fragment FragmentShaderStage
            
            // https://docs.unity3d.com/ja/2022.3/Manual/SL-MultipleProgramVariants.html
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap
            
            #pragma multi_compile_local _MODE_ALPHA_OFF _MODE_ALPHATEST_ON _MODE_ALPHABLEND_ON _MODE_ALPHAPREMULTIPLY_ON
            
            // 警告を非表示にする  できるだけ使わない方が良い
            // https://learn.microsoft.com/ja-jp/windows/win32/direct3dhlsl/hlsl-errors-and-warnings
            #pragma warning(suppress : 警告番号)
            // ここに警告が出るコードを入れる
            #pragma warning(suppress : 警告番号)
            
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            
            // 定義されたマクロを削除することができる
            #undef
            
            ENDCG
        }
    }
}

// UnityCG.cginc
#define UNITY_PI            3.14159265359f
#define UNITY_TWO_PI        6.28318530718f
#define UNITY_FOUR_PI       12.56637061436f
#define UNITY_INV_PI        0.31830988618f
#define UNITY_INV_TWO_PI    0.15915494309f
#define UNITY_INV_FOUR_PI   0.07957747155f
#define UNITY_HALF_PI       1.57079632679f
#define UNITY_INV_HALF_PI   0.636619772367f

// 2^-14, the same value for 10, 11 and 16-bit: https://www.khronos.org/opengl/wiki/Small_Float_Formats
#define UNITY_HALF_MIN      6.103515625e-5  



// UnityShaderVariables.cginc
#define UNITY_MATRIX_P glstate_matrix_projection
#define UNITY_MATRIX_V unity_MatrixV
#define UNITY_MATRIX_I_V unity_MatrixInvV
#define UNITY_MATRIX_VP unity_MatrixVP
#define UNITY_MATRIX_M unity_ObjectToWorld



// 下記の変数はCPUから値が送られるのではなく、シェーダー内で計算される
static float4x4 unity_MatrixMVP = mul(unity_MatrixVP, unity_ObjectToWorld);
static float4x4 unity_MatrixMV = mul(unity_MatrixV, unity_ObjectToWorld);
static float4x4 unity_MatrixTMV = transpose(unity_MatrixMV);
static float4x4 unity_MatrixITMV = transpose(mul(unity_WorldToObject, unity_MatrixInvV));

// 下記のマクロは上記の変数を使用する
#define UNITY_MATRIX_MVP
#define UNITY_MATRIX_MV
#define UNITY_MATRIX_T_MV
#define UNITY_MATRIX_IT_MV



// ShadowCaster では使えない
float4x4 unity_CameraProjection;
float4x4 unity_CameraInvProjection;
float4x4 unity_WorldToCamera;
float4x4 unity_CameraToWorld;



#if !defined(UNITY_MATRIX_I_M)
#define UNITY_MATRIX_I_M unity_WorldToObject
#endif

#define COMPUTE_VIEW_NORMAL normalize(mul((float3x3)UNITY_MATRIX_IT_MV, v.normal))

#define TRANSFORM_TEX(tex,name) (tex.xy * name##_ST.xy + name##_ST.zw)



// https://docs.unity3d.com/ja/2022.3/Manual/SL-ShaderSemantics.html
struct I2V
{
    float4 lPos : POSITION;
    float3 lNormal : NORMAL;
    float4 lTangent : TANGENT;
    float2 uv : TEXCOORD0;
};

struct V2F
{
    float4 cPos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 wTangent : TEXCOORD1;
    float3 wBinormal : TEXCOORD2;
    float3 wNormal : TEXCOORD3;
    
    // nointerpolation は頂点間の線形補間を無効化する
    // おそらく三角形を構成している最初の頂点の値となる
    nointerpolation float value : TEXCOORD4;
};

struct V2G
{
    float4 cPos : TEXCOORD0;
    float2 uv : TEXCOORD1;
};

struct G2F
{
    float4 cPos : SV_POSITION;
    float2 uv : TEXCOORD0;
};

struct F2O
{
    half4 color : SV_Target;
    float depth : SV_Depth;
};

struct TessellationFactor
{
    float tessFactor[3] : SV_TessFactor;
    float insideTessFactor : SV_InsideTessFactor;
};



// https://docs.unity3d.com/ja/2022.3/Manual/SL-SamplerStates.html
SamplerState _InlineSampler_Point_Clamp;
SamplerState _InlineSampler_Linear_Clamp;
SamplerState _InlineSampler_Point_Repeat;
SamplerState _InlineSampler_Linear_Repeat;

sampler2D _MainTex;

Texture2D _MainTex;
SamplerState sampler_MainTex;

// float4(1.0/width, 1.0/height, width, height)
float4 _MainTex_TexelSize;



// 時代遅れのミラー検出
static bool _IsInMirror = UNITY_MATRIX_P._31 != 0.0 || UNITY_MATRIX_P._32 != 0.0;

// ミラー検出
float _VRChatMirrorMode;
static bool _IsInMirror = _VRChatMirrorMode != 0.0;



#if defined(UNITY_PASS_FORWARDBASE)
#endif

#if defined(UNITY_PASS_FORWARDADD)
#endif

#if defined(UNITY_PASS_SHADOWCASTER)
#endif



// https://tips.hecomi.com/entry/2018/11/04/232219

// Single Pass
// VRChatがこれを使っている
// 今では時代遅れの機能となり、特殊な方法でないと有効にできない
#if defined(UNITY_SINGLE_PASS_STEREO)
#endif

// Single Pass Instancing 
// 現在では一般的な描画方式
#if defined(UNITY_STEREO_INSTANCING_ENABLED)
#endif

// MultiView
// OpenGL系のシェーダーAPIで動作する Single Pass Instancing に似ている描画方式
// MultiPass と名前が似ているが別物なので注意
#if defined(UNITY_STEREO_MULTIVIEW_ENABLED)
#endif

#if defined(UNITY_SINGLE_PASS_STEREO) || defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
#define USING_STEREO_MATRICES
#endif



// UNITY_UV_STARTS_AT_TOP の定義
#if defined(SHADER_API_D3D11) || defined(SHADER_API_PSSL) || defined(SHADER_API_METAL) || defined(SHADER_API_VULKAN) || defined(SHADER_API_SWITCH)
#define UNITY_UV_STARTS_AT_TOP 1
#endif

// UNITY_REVERSED_Z  の定義
#if defined(SHADER_API_D3D11) || defined(SHADER_API_PSSL) || defined(SHADER_API_METAL) || defined(SHADER_API_VULKAN) || defined(SHADER_API_SWITCH)
#define UNITY_REVERSED_Z 1
#endif

// UNITY_UV_STARTS_AT_TOP と UNITY_REVERSED_Z は同じ

#if defined(UNITY_REVERSED_Z)
    // DirectX
#else
    // OpenGL
#endif



#define TEX2D_LOAD_CLAMP(tex, uv) tex[uint2(clamp(uv, 0.0, 0.999999) * tex##_TexelSize.zw)]

#define TEX2D_LOAD_REPEAT(tex, uv) tex[uint2(frac(uv) * tex##_TexelSize.zw)]

// 2026-06-24 update
#define TEX2D_LOAD_CLAMP_INDEX(tex, index) tex[uint2(clamp(index, 0, int2(tex##_TexelSize.zw) - 1))]

// 2026-07-02 update
uint2 RepeatIndex(int2 index, uint2 size)
{
    uint2 temp = uint2(abs(index)) % size;
    return ((index < 0) && (temp != 0)) ? size - temp : temp;
}

#define TEX2D_LOAD_REPEAT_INDEX(tex, index) tex[RepeatIndex(index, tex##_TexelSize.zw)]




// 逆ガンマ補正 暗くなる
#define SRGB_TO_XYZ(value)\
value = saturate(value);\
value = (value <= 0.04045) ? (value / 12.92) : pow((value + 0.055) / 1.055, 2.4);

// ガンマ補正 明るくなる
#define XYZ_TO_SRGB(value)\
value = saturate(value);\
value = (value <= 0.0031308) ? (value * 12.92) : (pow(value, 1.0 / 2.4) * 1.055 - 0.055);



static float nan = asfloat(0xFFFFFFFF);

static float infinity = asfloat(0x7F800000);

// 255.0 / 256.0
asfloat(0x3F7F0000);



// unity_ObjectToWorld で ローカル座標系をワールド座標系にしてから、
// UNITY_MATRIX_VP で ワールド座標系をクリップ座標系に変換する
// w 成分は 1 に上書きされる
float4 UnityObjectToClipPos(float3 lPos);
float4 UnityObjectToClipPos(float4 lPos);

// UNITY_MATRIX_VP で ワールド座標系をクリップ座標系に変換する
// w 成分は 1 として扱う
float4 UnityWorldToClipPos(float3 wPos);



float4 colorA = tex2D(_MainTex, TRANSFORM_TEX(uv, _MainTex));
float4 colorB = _MainTex.Sample(sampler_MainTex, TRANSFORM_TEX(uv, _MainTex));



float3 wPos = mul(UNITY_MATRIX_M, input.lPos).xyz;



//カメラが向いている方向(World)
float3 wCameraDir = -UNITY_MATRIX_I_V._m02_m12_m22;

float3 wCameraDir = -UNITY_MATRIX_V._m20_m21_m22;

float3 wCameraDir = -UNITY_MATRIX_V[2].xyz;

//カメラが向いている方向(Local)
float3 lCameraDir = -UNITY_MATRIX_IT_MV[2].xyz;





float3 HSVToRGB(float h, float s, float v)
{
    float3 rgb = saturate(abs(frac(h + float3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 1.0);
    return v * lerp(float3(1.0, 1.0, 1.0), rgb, s);
}





void PointLight()
{
    float4 atten = 0.0;
    
    // ポイントライトの光の減衰
    
    // UnityのShade4PointLights
    atten = 1.0 / (1.0 + lengthSq * unity_4LightAtten0);

    // huwahuwa製
    atten = (1.0 - lengthSq * unity_4LightAtten0 * 0.04) / (1.0 + lengthSq * unity_4LightAtten0);
    atten = max(0.0, atten);
    
    // lilToon製
    //https://github.com/lilxyzw/OpenLit/blob/main/Assets/OpenLit/core.hlsl
    atten = saturate(saturate((25.0 - lengthSq * unity_4LightAtten0) * 0.111375) / (0.987725 + lengthSq * unity_4LightAtten0));

    
    
    // unity_4LightAtten0 から PointLight の範囲を計算する式
    
    // unity_4LightAtten0 = 25.0 / (range * range)
    // unity_4LightAtten0 * (range * range) = 25.0
    // (range * range) = 25.0 / unity_4LightAtten0

    float range = sqrt(25.0 / unity_4LightAtten0);
}





// Tessellation係数から三角形の数を計算する (partitioning("integer"))
uint TessFactor2TriangleCount(float factor)
{
    factor = ceil(factor);
    return floor(factor * factor * 1.5);
}

// 三角形の数からTessellation係数を計算する (partitioning("integer"))
uint TriangleCount2TessFactor(float count)
{
    return sqrt(count / 1.5f);
}



// 1メートルあたりのピクセル数
// cPos_W = UnityWorldToClipPos(wPos).w
// cPos_W = dot(UNITY_MATRIX_VP._m30_m31_m32_m33, float4(wPos, 1.0))
float2 PixelPerMeter(float cPos_W)
{
    return (_ScreenParams.xy * abs(UNITY_MATRIX_P._m00_m11)) / (cPos_W * 2.0);
}

// 1ピクセルあたりのメートル数
// cPos_W = UnityWorldToClipPos(wPos).w
// cPos_W = dot(UNITY_MATRIX_VP._m30_m31_m32_m33, float4(wPos, 1.0))
float2 MeterPerPixel(float cPos_W)
{
    return (cPos_W * 2.0) / (_ScreenParams.xy * abs(UNITY_MATRIX_P._m00_m11));
}



// 補間
float Smooth(float input)
{
    return input * input * (3.0 - (2.0 * input));
}



// ガウス関数 (の一種)
float GaussianFunction(float input)
{
    return exp(-2.5 * input * input);
}

// ガウス関数の近似
float ApproximateGaussianFunction1(float input)
{
    float temp0 = 1.0 - abs(input);
    return temp0 * temp0 * (3.0 - (2.0 * temp0));
}

// ガウス関数の近似
// こちらの方が負荷が少ない
float ApproximateGaussianFunction2(float input)
{
    float temp0 = abs(input);
    return 1.0 - temp0 * temp0 * (3.0 - (2.0 * temp0));
}



// ShadeSH9 の調査
void SH(float3 n)
{
    float3 color = 0.0;

    color += float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w); // Y(0, 0)
    
    color += float3(unity_SHAr.y, unity_SHAg.y, unity_SHAb.y) * n.y; // Y(1, -1)
    color += float3(unity_SHAr.z, unity_SHAg.z, unity_SHAb.z) * n.z; // Y(1,  0)
    color += float3(unity_SHAr.x, unity_SHAg.x, unity_SHAb.x) * n.x; // Y(1,  1)

    color += float3(unity_SHBr.x, unity_SHBg.x, unity_SHBb.x) * n.x * n.y; // Y(2, -2)
    color += float3(unity_SHBr.y, unity_SHBg.y, unity_SHBb.y) * n.y * n.z; // Y(2, -1)
    color += float3(unity_SHBr.z, unity_SHBg.z, unity_SHBb.z) * n.z * n.z; // Y(2,  0)
    color += float3(unity_SHBr.w, unity_SHBg.w, unity_SHBb.w) * n.z * n.x; // Y(2,  1)
    color += unity_SHC * (n.x * n.x - n.y * n.y); // Y(2,  2)
}

void SH(float3 n)
{
    float3 color = 0.0;
    
    color += SphericalHarmonicsL2[0];

    color += SphericalHarmonicsL2[1] * n.y;
    color += SphericalHarmonicsL2[2] * n.z;
    color += SphericalHarmonicsL2[3] * n.x;

    color += SphericalHarmonicsL2[4] * n.x * n.y;
    color += SphericalHarmonicsL2[5] * n.y * n.z;
    color += SphericalHarmonicsL2[6] * (3.0 * n.z * n.z - 1.0);
    color += SphericalHarmonicsL2[7] * n.z * n.x;
    color += SphericalHarmonicsL2[8] * (n.x * n.x - n.y * n.y);
}

void SH(float3 n)
{
    float3 color = 0.0;

    color += float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w) + (float3(unity_SHBr.z, unity_SHBg.z, unity_SHBb.z) / 3.0); // Y(0, 0)
    
    color += float3(unity_SHAr.y, unity_SHAg.y, unity_SHAb.y) * n.y; // Y(1, -1)
    color += float3(unity_SHAr.z, unity_SHAg.z, unity_SHAb.z) * n.z; // Y(1,  0)
    color += float3(unity_SHAr.x, unity_SHAg.x, unity_SHAb.x) * n.x; // Y(1,  1)

    color += float3(unity_SHBr.x, unity_SHBg.x, unity_SHBb.x) * n.x * n.y;                       // Y(2, -2)
    color += float3(unity_SHBr.y, unity_SHBg.y, unity_SHBb.y) * n.y * n.z;                       // Y(2, -1)
    color += (float3(unity_SHBr.z, unity_SHBg.z, unity_SHBb.z) / 3.0) * (3.0 * n.z * n.z - 1.0); // Y(2,  0)
    color += float3(unity_SHBr.w, unity_SHBg.w, unity_SHBb.w) * n.z * n.x;                       // Y(2,  1)
    color += unity_SHC * (n.x * n.x - n.y * n.y);                                                // Y(2,  2)
}

// float3(unity_SHBr.z, unity_SHBg.z, unity_SHBb.z) = SphericalHarmonicsL2[6] * 3.0;
// float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w) = SphericalHarmonicsL2[0] - SphericalHarmonicsL2[6]

            #define SH_Y0_0 sqrt(1.0 / (4.0 * _Pi))

            #define SH_Y1M1 sqrt(3.0 / (4.0 * _Pi)) * y
            #define SH_Y1_0 sqrt(3.0 / (4.0 * _Pi)) * z
            #define SH_Y1P1 sqrt(3.0 / (4.0 * _Pi)) * x

            #define SH_Y2M2 sqrt(15.0 / ( 4.0 * _Pi)) * x * y
            #define SH_Y2M1 sqrt(15.0 / ( 4.0 * _Pi)) * y * z
            #define SH_Y2_0 sqrt( 5.0 / (16.0 * _Pi)) * (3.0 * z * z - 1.0)
            #define SH_Y2P1 sqrt(15.0 / ( 4.0 * _Pi)) * z * x
            #define SH_Y2P2 sqrt(15.0 / (16.0 * _Pi)) * (x * x - y * y)

            #define SH_Y3M3 sqrt( 35.0 / (32.0 * _Pi)) * y * (3.0 * x * x - y * y)
            #define SH_Y3M2 sqrt(105.0 / ( 4.0 * _Pi)) * x * y * z
            #define SH_Y3M1 sqrt( 21.0 / (32.0 * _Pi)) * y * (5.0 * z * z - 1.0)
            #define SH_Y3_0 sqrt(  7.0 / (16.0 * _Pi)) * z * (5.0 * z * z - 3.0)
            #define SH_Y3P1 sqrt( 21.0 / (32.0 * _Pi)) * x * (5.0 * z * z - 1.0)
            #define SH_Y3P2 sqrt(105.0 / (16.0 * _Pi)) * z * (x * x - y * y)
            #define SH_Y3P3 sqrt( 35.0 / (32.0 * _Pi)) * x * (x * x - 3.0 * y * y)

            #define SH_Y4M4 sqrt(315.0 / ( 16.0 * _Pi)) * x * y * (x * x - y * y)
            #define SH_Y4M3 sqrt(315.0 / ( 32.0 * _Pi)) * y * z * (3.0 * x * x - y * y)
            #define SH_Y4M2 sqrt( 45.0 / ( 16.0 * _Pi)) * x * y * (7.0 * z * z - 1.0)
            #define SH_Y4M1 sqrt( 45.0 / ( 32.0 * _Pi)) * y * z * (7.0 * z * z - 3.0)
            #define SH_Y4_0 sqrt(  9.0 / (256.0 * _Pi)) * (35.0 * z * z * z * z - 30.0 * z * z + 3.0)
            #define SH_Y4P1 sqrt( 45.0 / ( 32.0 * _Pi)) * z * x * (7.0 * z * z - 3.0)
            #define SH_Y4P2 sqrt( 45.0 / ( 64.0 * _Pi)) * (x * x - y * y) * (7.0 * z * z - 1.0)
            #define SH_Y4P3 sqrt(315.0 / ( 32.0 * _Pi)) * x * z * (x * x - 3.0 * y * y)
            #define SH_Y4P4 sqrt(315.0 / (256.0 * _Pi)) * (x * x * (x * x - 3.0 * y * y) - y * y * (3.0 * x * x - y * y))





// 2次方程式の解の公式の色々な実装
void Temp0()
{
    float a, b, c, result;
    float s = 1; // 1 or -1

    {
        float d = b * b - 4.0 * a * c;
        result = (-b + s * sqrt(d)) / (2.0 * a);
    }

    {
        float d = b * b - 4.0 * a * c;
        result = (2.0 * c) / (-b - s * sqrt(d));
    }

    {
        b *= 0.5;
        float d = b * b - a * c;
        result = (-b + s * sqrt(d)) / a;
    }

    {
        b *= 0.5;
        float d = b * b - a * c;
        result = c / (-b - s * sqrt(d));
    }
}





// 接空間の計算メモ
void TangentSpace(I2V input)
{
    float3 lNormal = input.lNormal;
    float3 lTangent = input.lTangent.xyz;
    float3 lBinormal = cross(lNormal, lTangent) * input.lTangent.w;

    float3 wNormal = UnityObjectToWorldNormal(lNormal);
    float3 wTangent = UnityObjectToWorldDir(lTangent);
    float3 wBinormal = cross(wNormal, wTangent) * (input.lTangent.w * unity_WorldTransformParams.w);

    //float3 unpackNormal = UnpackNormal(tex2Dlod(_NormalMap, float4(uv, 0.0, 0.0)));
    //float3 unpackNormal = UnpackNormal(tex2D(_BumpMap, uv));
    //float3 unpackNormal = UnpackScaleNormalRGorAG(tex2D(_BumpMap, uv), _BumpScale);
    float3 unpackNormal = UnpackNormalWithScale(tex2D(_BumpMap, uv), _BumpScale);
    
    // R = tangent
    // G = binormal
    // B = normal
    unpackNormal = wTangent * unpackNormal.r + wBinormal * unpackNormal.g + wNormal * unpackNormal.b;
    unpackNormal = normalize(unpackNormal);
}





void MatrixMemoryLayout()
{
    float4x4 a;

    float4x3
    (
        a[0][0], a[0][1], a[0][2],
        a[1][0], a[1][1], a[1][2],
        a[2][0], a[2][1], a[2][2],
        a[3][0], a[3][1], a[3][2]
    );

    float4x3
    (
        a._m00, a._m01, a._m02,
        a._m10, a._m11, a._m12,
        a._m20, a._m21, a._m22,
        a._m30, a._m31, a._m32
    );

    float4x3
    (
        a._11, a._12, a._13,
        a._21, a._22, a._23,
        a._31, a._32, a._33,
        a._41, a._42, a._43
    );
}

// わざわざ関数にしないと警告が出る
float3x3 ScalarMul(float3x3 mat, float scalar)
{
    return mat * scalar;
}

// Transform の Scale を取得する
// しかし、親階層の Transform が回転したりスケールが変更されていると使えない
float3 GetScale()
{
    float3 scale;
    scale.x = length(UNITY_MATRIX_M._m00_m10_m20);
    scale.y = length(UNITY_MATRIX_M._m01_m11_m21);
    scale.z = length(UNITY_MATRIX_M._m02_m12_m22);
    return scale;
}

float2 Rotarion2D(float2 uv, float angle)
{
    float S, C;
    sincos(angle, S, C);

    // 反時計回り
    return mul(float2x2(C, -S, S, C), uv);
    return mul(float2x2(C, S, -S, C), uv.yx).yx;
    // 時計回り
    return mul(float2x2(C, S, -S, C), uv);
    return mul(float2x2(C, -S, S, C), uv.yx).yx;

}

float3x3 LookRotation(float3 fv, float3 uv)
{
    fv = normalize(fv);
    float3 rv = normalize(cross(uv, fv));
    uv = cross(fv, rv);

    return float3x3
    (
        rv.x, uv.x, fv.x,
        rv.y, uv.y, fv.y,
        rv.z, uv.z, fv.z
    );
}





// Rasterrizer Stage などで変化する SV_POSITION を再現する式
float4 CPosToSVPos(float4 cPos)
{
    
//#if UNITY_UV_STARTS_AT_TOP
//    cPos.y = -cPos.y;
//#endif
    
    cPos.y *= _ProjectionParams.x;
    
    cPos.xyz /= cPos.w;
    
#if defined(UNITY_REVERSED_Z)
    cPos.xy = cPos.xy * 0.5 + 0.5;
#else
    cPos.xyz = cPos.xyz * 0.5 + 0.5;
#endif
    
#if defined(UNITY_SINGLE_PASS_STEREO)
    cPos.x += unity_StereoEyeIndex;
#endif
    
    cPos.xy *= _ScreenParams.xy;
    
    return cPos;
}

// Rasterrizer Stage などで変化する SV_POSITION を元に戻す式
float4 SVPosToCPos(float4 svPos)
{
    svPos.xy /= _ScreenParams.xy;

#if defined(UNITY_SINGLE_PASS_STEREO)
    svPos.x -= unity_StereoEyeIndex;
#endif
    
#if defined(UNITY_REVERSED_Z)
    svPos.xy = svPos.xy * 2.0 - 1.0;
#else
    svPos.xyz = svPos.xyz * 2.0 - 1.0;
#endif

    svPos.xyz *= svPos.w;
    
    svPos.y *= _ProjectionParams.x;
    
//#if UNITY_UV_STARTS_AT_TOP
//    svPos.y = -svPos.y;
//#endif
    
    return svPos;
}





// near clip面を考慮したRayの開始位置をWorld座標系で返す
// 特殊な投影行列では使えないことがある
float3 WorldRayStartPos(float4 cPos)
{
    float4x4 mp = UNITY_MATRIX_P;
    
    // 平行投影ではないときに発動
    // unity_OrthoParams.wはShadowCasterでは使えないので不採用
    if (any(mp[3] != float4(0.0, 0.0, 0.0, 1.0)))
    {
        return _WorldSpaceCameraPos;
    }
    
#if defined(UNITY_REVERSED_Z)
    cPos.z = 1.0;
#else
    cPos.z = -1.0;
#endif
    
    float3 temp0 = mul(Inverse((float3x3) mp), cPos.xyz - mp._m03_m13_m23);
    return mul(UNITY_MATRIX_I_V, float4(temp0, 1.0));
}

// 頂点シェーダーで実行したい場合は、すべての頂点シェーダーで cPos.w の値を同じにする必要がある
float3 WorldRayStartPos(float4 cPos)
{
    cPos.xy /= cPos.w;
    cPos.w = 1.0;
    
#if defined(UNITY_REVERSED_Z)
    cPos.z = 1.0;
#else
    cPos.z = -1.0;
#endif
    
    float4 temp = mul(Inverse(UNITY_MATRIX_P), cPos);
    return mul(UNITY_MATRIX_I_V, temp / temp.w);
}

// 頂点シェーダーで実行したい場合は、すべての頂点シェーダーで cPos.w の値を同じにする必要がある
float3 WorldRayEndPos(float4 cPos)
{
    cPos.xy /= cPos.w;
    cPos.w = 1.0;
    
#if defined(UNITY_REVERSED_Z)
    cPos.z = 0.0;
#else
    cPos.z = 1.0;
#endif
    
    float4 temp = mul(Inverse(UNITY_MATRIX_P), cPos);
    return mul(UNITY_MATRIX_I_V, temp / temp.w);
}



// https://discussions.unity.com/t/raycasting-through-a-custom-camera-projection-matrix/459472/9
// near clip面を考慮したRayの開始位置をView座標系で返す
// 正確だが負荷が高い FragmentShader専用
float4 ViewRayStartPos(float4 vPos)
{
    float4 cPos = mul(unity_CameraProjection, vPos);
    cPos.xy /= cPos.w;
    cPos.z = -1.0;
    cPos.w = 1.0;
    
    float4 result = mul(unity_CameraInvProjection, cPos);
    return result / result.w;
}

// 上記の処理をunity_CameraInvProjectionや平行投影用の逆行列の式で高速化
float4 ViewRayStartPos(float4 vPos)
{
    float4 cPos;
    float4 result;
    
#if defined(UNITY_PASS_SHADOWCASTER)
    float4x4 mp = UNITY_MATRIX_P;
    
    // 平行投影か判定
    // unity_OrthoParams.wはShadowCasterでは使えないので不採用
    if(all(mp[3] == float4(0.0, 0.0, 0.0, 1.0)))
    {
        cPos = mul(mp, vPos);
        //cPos.xy /= cPos.w;    平行投影だとcPos.w=1.0になるので必要ないかも
        
#if defined(UNITY_REVERSED_Z)
        cPos.z = 1.0;
#else
        cPos.z = -1.0;
#endif
        
        result.xyz = mul(Inverse((float3x3)mp), cPos.xyz - mp._m03_m13_m23);
        result.w = 1.0;
        return result;
    }
#endif
    
    cPos = mul(unity_CameraProjection, vPos);
    cPos.xy /= cPos.w;
    cPos.z = -1.0;
    cPos.w = 1.0;
    
    result = mul(unity_CameraInvProjection, cPos);
    return result / result.w;
}





// HLSLSupport.cginc

struct sampler1D_f
{
    Texture1D<float4> t;
    SamplerState s;
};
struct sampler2D_f
{
    Texture2D<float4> t;
    SamplerState s;
};
struct sampler3D_f
{
    Texture3D<float4> t;
    SamplerState s;
};
struct samplerCUBE_f
{
    TextureCube<float4> t;
    SamplerState s;
};

float4 tex1D(sampler1D_f x, float v)
{
    return x.t.Sample(x.s, v);
}
float4 tex2D(sampler2D_f x, float2 v)
{
    return x.t.Sample(x.s, v);
}
float4 tex3D(sampler3D_f x, float3 v)
{
    return x.t.Sample(x.s, v);
}
float4 texCUBE(samplerCUBE_f x, float3 v)
{
    return x.t.Sample(x.s, v);
}

float4 tex1Dbias(sampler1D_f x, in float4 t)
{
    return x.t.SampleBias(x.s, t.x, t.w);
}
float4 tex2Dbias(sampler2D_f x, in float4 t)
{
    return x.t.SampleBias(x.s, t.xy, t.w);
}
float4 tex3Dbias(sampler3D_f x, in float4 t)
{
    return x.t.SampleBias(x.s, t.xyz, t.w);
}
float4 texCUBEbias(samplerCUBE_f x, in float4 t)
{
    return x.t.SampleBias(x.s, t.xyz, t.w);
}

float4 tex1Dlod(sampler1D_f x, in float4 t)
{
    return x.t.SampleLevel(x.s, t.x, t.w);
}
float4 tex2Dlod(sampler2D_f x, in float4 t)
{
    return x.t.SampleLevel(x.s, t.xy, t.w);
}
float4 tex3Dlod(sampler3D_f x, in float4 t)
{
    return x.t.SampleLevel(x.s, t.xyz, t.w);
}
float4 texCUBElod(samplerCUBE_f x, in float4 t)
{
    return x.t.SampleLevel(x.s, t.xyz, t.w);
}

float4 tex1Dgrad(sampler1D_f x, float t, float dx, float dy)
{
    return x.t.SampleGrad(x.s, t, dx, dy);
}
float4 tex2Dgrad(sampler2D_f x, float2 t, float2 dx, float2 dy)
{
    return x.t.SampleGrad(x.s, t, dx, dy);
}
float4 tex3Dgrad(sampler3D_f x, float3 t, float3 dx, float3 dy)
{
    return x.t.SampleGrad(x.s, t, dx, dy);
}
float4 texCUBEgrad(samplerCUBE_f x, float3 t, float3 dx, float3 dy)
{
    return x.t.SampleGrad(x.s, t, dx, dy);
}

float4 tex1D(sampler1D_f x, float t, float dx, float dy)
{
    return x.t.SampleGrad(x.s, t, dx, dy);
}
float4 tex2D(sampler2D_f x, float2 t, float2 dx, float2 dy)
{
    return x.t.SampleGrad(x.s, t, dx, dy);
}
float4 tex3D(sampler3D_f x, float3 t, float3 dx, float3 dy)
{
    return x.t.SampleGrad(x.s, t, dx, dy);
}
float4 texCUBE(samplerCUBE_f x, float3 t, float3 dx, float3 dy)
{
    return x.t.SampleGrad(x.s, t, dx, dy);
}

float4 tex1Dproj(sampler1D_f s, in float2 t)
{
    return tex1D(s, t.x / t.y);
}
float4 tex1Dproj(sampler1D_f s, in float4 t)
{
    return tex1D(s, t.x / t.w);
}
float4 tex2Dproj(sampler2D_f s, in float3 t)
{
    return tex2D(s, t.xy / t.z);
}
float4 tex2Dproj(sampler2D_f s, in float4 t)
{
    return tex2D(s, t.xy / t.w);
}
float4 tex3Dproj(sampler3D_f s, in float4 t)
{
    return tex3D(s, t.xyz / t.w);
}
float4 texCUBEproj(samplerCUBE_f s, in float4 t)
{
    return texCUBE(s, t.xyz / t.w);
}








