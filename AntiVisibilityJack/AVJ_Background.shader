Shader "AntiVisibilityJack/Background"
{
	SubShader
	{
		Tags
		{
			"Queue" = "Overlay-1"
			"RenderType" = "Transparent"
		}

		GrabPass
		{
			"_AVJ_BackgroundTexture"
		}

		Pass
		{
			ZWrite Off
			ColorMask 0
		}
	}
}