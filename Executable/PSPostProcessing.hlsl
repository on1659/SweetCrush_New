
static const float3 LUM_FACTOR = float3(0.299, 0.587, 0.114);

//StructuredBuffer<float> AverageValues1D : register(t2);

cbuffer FinalPassConstants : register(b0) {
	float MiddleGrey : packoffset(c0);
	float LumWhiteSqr : packoffset(c0.y);
	float BloomScale : packoffset(c0.z);
}

SamplerState        gssSamplerState		: register(s0);

Texture2D           gtxtLightedTexture	: register(t0);
StructuredBuffer<float> AvgLum			: register(t1);
Texture2D<float4> BloomTexture			: register(t2);

Texture2D test			: register(t3);

struct VS_TEXTURED_OUTPUT {
	float4 position : SV_POSITION;
	float2 texCoord : TEXCOORD0;
};

float3 ToneMapping(float3 HDRColor) {
	float LScale = dot(HDRColor, LUM_FACTOR);
	LScale *= MiddleGrey / AvgLum[0];
	LScale = (LScale + LScale*LScale / LumWhiteSqr) / (1.0 + LScale);

	return HDRColor * LScale;
}

float4 main(VS_TEXTURED_OUTPUT input) : SV_Target{

	//return float4(AvgLum[0],AvgLum[0],AvgLum[0],1.0);
	
	float3 cColor = gtxtLightedTexture.Sample(gssSamplerState, input.texCoord);

	cColor += BloomScale * BloomTexture.Sample(gssSamplerState, input.texCoord).xyz;
	//bloom분포 추가


	
	
	return(float4(ToneMapping(cColor), 1.0));
	
	//float4 cTestColor = gtxtLightedTexture.Sample(gssSamplerState, input.texCoord);
	//
	//return cTestColor;
}