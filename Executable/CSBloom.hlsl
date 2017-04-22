
cbuffer DownScaleConstants : register(b0) 
{
	//다운 스케일 해상도 계산 x 너비, y 높이
	uint2 Res : packoffset(c0);
	//다운스케일 이미지의 총 픽셀 수
	uint Domain : packoffset(c0.z);
	//첫번째 pass에 적용된 그룹 수
	uint GroupSize : packoffset(c0.w);
	//적응값
	float Adaptation : packoffset(c1);
	//bloom 임계값 비율
	float fBloomThreshold : packoffset(c1.y);
}

Texture2D<float4> HDRDownScaleTex : register(t0);
StructuredBuffer<float> AvgLum : register(t1);
RWTexture2D<float4> Bloom : register(u0);

static const float4 LUM_FACTOR = float4(0.299, 0.587, 0.114, 0);

[numthreads(1024, 1, 1)]
void main( uint3 dispatchThreadId : SV_DispatchThreadID ){
	uint2 CurPixel = uint2(dispatchThreadId.x % Res.x, dispatchThreadId.x / Res.x);

	//픽셀 결합 생략.. ? ???/ later 연구
	if (CurPixel.y < Res.y) {
		float4 color = HDRDownScaleTex.Load(int3(CurPixel, 0));
		float Lum = dot(color, LUM_FACTOR);
		float avgLum = AvgLum[0];

		//Find the color scale
		float colorScale = saturate(Lum - avgLum * fBloomThreshold);

		Bloom[CurPixel.xy] = color * colorScale;
		//Bloom[CurPixel.xy] = float4(AvgLum[0], AvgLum[0], AvgLum[0], 1.0);
	}
}