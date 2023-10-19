// Ver5 2023/10/20 07:01

Shader "HuwaShader/HuwaFur3"
{
	Properties
	{
		[NoScaleOffset]
		_MainTex("Main Texture", 2D) = "white" {}
		[NoScaleOffset][Normal]
		_FurDirectionTex("Fur Direction Texture", 2D) = "bump" {}
		[NoScaleOffset]
		_FurLengthTex("Fur Length Texture", 2D) = "white" {}
		[NoScaleOffset]
		_AreaDataTex("Area Data Texture", 2D) = "white" {}

		[Header(Geometry Settings)]
		[Space(12)]

		_FurLength("Fur Length", Float) = 0.05
		_FurWidth("Fur Width", Range(0, 1)) = 0.1
		_FurRandomLength("Fur Random Length", Range(0, 1)) = 0.25
		_FurRandomDirection("Fur Random Direction", Range(0, 1)) = 0.25
		_FurDensity("Fur Density", Float) = 200.0
		_FurSplit("Fur Split", Int) = 4

		[Header(Lighting Settings)]
		[Space(12)]

		_FurAbsorption("Fur Absorption", Range(0, 1)) = 0.5
		_DiffuseOffset("Diffuse offset", Range(-1.0, 1.0)) = 0.5
		_BaseColorStrength("Base color strength", Range(-1.0, 2.0)) = 0.0
	}

	SubShader
	{
		Tags
		{
			"Queue" = "AlphaTest+1"
			"RenderType" = "TransparentCutout"
		}

		Pass
		{
			Tags
			{
				"LightMode" = "ForwardBase"
			}

			Cull Off

			CGPROGRAM

			#include "HuwaFur.hlsl"

			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight

			#pragma vertex VertexShaderStage_Skin
			#pragma fragment FragmentShaderStage_Skin

			ENDCG
		}

		Pass
		{
			Tags
			{
				"LightMode" = "ForwardBase"
			}

			Stencil
			{
				Ref 226
				Comp always
				Pass replace
			}

			Cull Off

			CGPROGRAM

			#include "HuwaFur.hlsl"

			#pragma require tessellation
			#pragma require geometry
			
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight

			#pragma vertex VertexShaderStage_Fur
			#pragma hull HullShaderStage_Fur
			#pragma domain DomainShaderStage_Fur
			#pragma geometry GeometryShaderStage_Fur
			#pragma fragment FragmentShaderStage_Fur

			ENDCG
		}

		// UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
		Pass
		{
			Name "ShadowCaster"

			Tags
			{
				"LightMode" = "ShadowCaster"
			}

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile_instancing // allow instanced shadow pass for most of the shaders
			
			#include "UnityCG.cginc"

			struct v2f
			{
				V2F_SHADOW_CASTER;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			v2f vert( appdata_base v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}

			float4 frag( v2f i ) : SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i)
			}

			ENDCG
		}
	}

	FallBack Off
}
