Shader "Custom/GrabPassOnly"
{
	SubShader
	{
		Tags
		{
			"Queue" = "AlphaTest+49"
			"DisableBatching" = "True"
			"IgnoreProjector" = "True"
		}

		GrabPass
		{
			"GrabPassOnly_GrabPass"
		}

		Pass
		{
			Tags
			{
				"LightMode" = "Never"
			}
		}
	}
}
