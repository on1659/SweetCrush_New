struct VS_TEXTURED_OUTPUT {
	float4 position : SV_POSITION;
	float2 texCoord : TEXCOORD0;
};


//¥Ÿ¡ﬂ ∑ª¥ı≈∏∞Ÿ
VS_TEXTURED_OUTPUT main(float3 position : POSITION, float2 texCoord : TEXCOORD)
{
	VS_TEXTURED_OUTPUT output = (VS_TEXTURED_OUTPUT)0;
	output.position = float4(position, 1.0f);
	output.texCoord = texCoord;

	return(output);
}
