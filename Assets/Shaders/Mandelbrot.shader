﻿Shader "Unlit/Mandelbrot"
{
	Properties
	{
		[Toggle(DOUBLE_PRECISION)] _DP("Double Precision", Float) = 0 // the name of the property (_Thingy in this case) doesn't seem to be relevant
	}
		SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma target 4.5
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			//#pragma multi_compile_fog
			#pragma multi_compile __ DOUBLE_PRECISION

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				//UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;// TRANSFORM_TEX(v.uv, _MainTex);
				//UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

#if defined(DOUBLE_PRECISION)
			int Compute(double2 c, int threshold)
			{
				double
#else
			int Compute(float2 c, int threshold)
			{
				float
#endif
					r = 0, i = 0, rsqr = 0, isqr = 0;

				int iter = 0;
				const float MAX_MAG_SQUARED = 10;

				while ((iter < threshold) && (rsqr + isqr < MAX_MAG_SQUARED))
				{
					rsqr = r * r;
					isqr = i * i;
					i = 2 * i * r + c.y;
					r = rsqr - isqr + c.x;
					iter++;
				}

				return iter;
			}

			float Band(float center, float width, float t)
			{
				return saturate(1 - abs((-center + t) / width));
			}

//#if defined(DOUBLE_PRECISION)
//			double4 _PositionBounds;
//#else
			float4 _PositionBounds;
//#endif

			fixed4 frag(v2f i) : SV_Target
			{
				const int threshold = 100;

#if defined(DOUBLE_PRECISION)
				double2 position = _PositionBounds.xy;
				double2 bounds = _PositionBounds.zw;

				double2 coord = position + bounds * i.uv;
				int p = Compute(coord, threshold);
				double v = saturate(p * 1.0 / threshold);
#else
				float2 position = _PositionBounds.xy;
				float2 bounds = _PositionBounds.zw;

				float2 coord = position + bounds * i.uv;
				int p = Compute(coord, threshold);
				float v = saturate(p * 1.0 / threshold);
#endif

				fixed r = Band(0.33f, 0.33f, v) + Band(1, 0.33f, v);
				fixed g = Band(0.5f, 0.33f, v) + Band(1, 0.33f, v);
				fixed b = Band(0.66f, 0.33f, v) + Band(1, 0.33f, v);

				fixed4 col = fixed4(r, g, b, 1);

				// apply fog
				//UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
