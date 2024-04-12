// Ver1 2023-12-18 02:29

// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)
// Created based on Unity 2022.3.8f1 Standard.shader

Shader "Custom/RewriteStandardShader"
{
    Properties
    {
        [Header(_            SrcBlend  DstBlend          ZWrite  AlphaMode            RenderQueue)]
        [Header(Opaque       One       Zero              On      ALPHA_OFF               0 to 5000)]
        [Header(Cutout       One       Zero              On      ALPHATEST_ON            0 to 5000)]
        [Header(Fade         SrcAlpha  OneMinusSrcAlpha  Off     ALPHABLEND_ON        2501 to 5000)]
        [Header(Transparent  One       OneMinusSrcAlpha  Off     ALPHAPREMULTIPLY_ON  2501 to 5000)]
        
        [Space(18)]

        [Enum(One, 1, SrcAlpha, 5)]
        _SrcBlend ("SrcBlend", Int) = 1

        [Enum(Zero, 0, OneMinusSrcAlpha, 10)]
        _DstBlend ("DstBlend", Int) = 0

        [Enum(On, 1, Off, 0)]
        _ZWrite ("ZWrite", Int) = 1
        
        [KeywordEnum(ALPHA_OFF, ALPHATEST_ON, ALPHABLEND_ON, ALPHAPREMULTIPLY_ON)]
        _Mode ("Alpha Mode", Int) = 0

        [Space(18)]

        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        [Space(18)]

        _Color("Color", Color) = (1,1,1)
        [NoScaleOffset]
        _MainTex("Albedo", 2D) = "white" {}
        
        [Space(18)]
        
        [Toggle]
        _UseMetallicGlossMap("Use Metallic Gloss Map", Int) = 0
        [Gamma]
        _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        _Glossiness("Smoothness (Glossiness)", Range(0.0, 1.0)) = 0.5
        [NoScaleOffset]
        _MetallicGlossMap("Metallic Gloss Map", 2D) = "white" {}

        [Space(18)]

        _BumpScale("Normal Scale", Float) = 1.0
        [NoScaleOffset][Normal]
        _BumpMap("Normal Map", 2D) = "bump" {}
        
        [Space(18)]

        _Parallax ("Height Scale", Range (0.0, 0.08)) = 0.02
        [NoScaleOffset]
        _ParallaxMap ("Height Map", 2D) = "black" {}
        
        [Space(18)]

        _OcclusionStrength("Occlusion Strength", Range(0.0, 1.0)) = 1.0
        [NoScaleOffset]
        _OcclusionMap("Occlusion Map", 2D) = "white" {}
        
        [Space(18)]

        [Gamma][HDR]
        _EmissionColor("Emission Color", Color) = (0,0,0)
        [NoScaleOffset]
        _EmissionMap("Emission Map", 2D) = "white" {}
    }

    SubShader
    {
        Tags
        {
            "LightMode" = "ForwardBase"
        }

        Pass
        {
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]

            CGPROGRAM
            
            #pragma target 3.0

            #pragma multi_compile_local _MODE_ALPHA_OFF _MODE_ALPHATEST_ON _MODE_ALPHABLEND_ON _MODE_ALPHAPREMULTIPLY_ON
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight

            #pragma vertex VertexShaderStage
            #pragma fragment FragmentShaderStage
            
            #define UNITY_PASS_FORWARDBASE 1

            #include "RewriteStandardShader.hlsl"

            ENDCG
        }

        Pass
        {
            Tags
            {
                "LightMode" = "ForwardAdd"
            }

            Blend [_SrcBlend] One
            ZWrite Off

            CGPROGRAM

            #pragma target 3.0
            
            #pragma multi_compile_local _MODE_ALPHA_OFF _MODE_ALPHATEST_ON _MODE_ALPHABLEND_ON _MODE_ALPHAPREMULTIPLY_ON
            #pragma multi_compile_fwdadd_fullshadows

            #pragma vertex VertexShaderStage
            #pragma fragment FragmentShaderStage
            
            #define UNITY_PASS_FORWARDADD 1

            #include "RewriteStandardShader.hlsl"

            ENDCG
        }

        Pass
        {
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            CGPROGRAM

            #pragma target 3.0
            
            #pragma multi_compile_local _MODE_ALPHA_OFF _MODE_ALPHATEST_ON _MODE_ALPHABLEND_ON _MODE_ALPHAPREMULTIPLY_ON

            #pragma vertex VertexShaderStage_ShadowCaster
            #pragma fragment FragmentShaderStage_ShadowCaster
            
            #define UNITY_PASS_SHADOWCASTER 1

            #include "RewriteStandardShader.hlsl"

            ENDCG
        }
    }
}
