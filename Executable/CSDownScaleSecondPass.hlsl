cbuffer DownScaleConstants : register(b0) {
	//다운 스케일 해상도 계산 x 너비, y 높이
	uint2 Res : packoffset(c0);
	//다운스케일 이미지의 총 픽셀 수
	uint Domain : packoffset(c0.z);
	//첫번째 pass에 적용된 그룹 수
	uint GroupSize : packoffset(c0.w);
	//적응값
	float Adaptation : packoffset(c1);
}

StructuredBuffer<float> AverageValues1D : register(t1);
//이전 평균 휘도 값
StructuredBuffer<float> PrevAvgLum : register(t2);


//결과 group개수 만큼의 AverageLum
RWStructuredBuffer<float> AverageLum : register(u0);

#define MAX_GROUPS 64

groupshared float SharedAvgFinal[MAX_GROUPS];

[numthreads(MAX_GROUPS, 1, 1)]
void main(uint3 groupId : SV_GroupID, uint3 groupThreadId : SV_GroupThreadID, uint3 dispatchThreadId : SV_DispatchThreadID, uint groupIndex : SV_GroupIndex) {
	float avgLum = 0.0;
	if (dispatchThreadId.x < GroupSize) {
		avgLum = AverageValues1D[dispatchThreadId.x];
	}
	SharedAvgFinal[dispatchThreadId.x] = avgLum;

	//Sync
	GroupMemoryBarrierWithGroupSync();

	//64 - 16
	if (dispatchThreadId.x % 4 == 0) {
		float stepAvgLum = avgLum;
		stepAvgLum += dispatchThreadId.x + 1 < GroupSize ? SharedAvgFinal[dispatchThreadId.x + 1] : avgLum;
		stepAvgLum += dispatchThreadId.x + 2 < GroupSize ? SharedAvgFinal[dispatchThreadId.x + 2] : avgLum;
		stepAvgLum += dispatchThreadId.x + 3 < GroupSize ? SharedAvgFinal[dispatchThreadId.x + 3] : avgLum;

		avgLum = stepAvgLum;
		SharedAvgFinal[dispatchThreadId.x] = stepAvgLum;
	}
	GroupMemoryBarrierWithGroupSync();

	//16 - 4
	if (dispatchThreadId.x % 16 == 0) {
		float stepAvgLum = avgLum;
		stepAvgLum += dispatchThreadId.x + 4 < GroupSize ? SharedAvgFinal[dispatchThreadId.x + 4] : avgLum;
		stepAvgLum += dispatchThreadId.x + 8 < GroupSize ? SharedAvgFinal[dispatchThreadId.x + 8] : avgLum;
		stepAvgLum += dispatchThreadId.x + 16 < GroupSize ? SharedAvgFinal[dispatchThreadId.x + 16] : avgLum;

		avgLum = stepAvgLum;
		SharedAvgFinal[dispatchThreadId.x] = stepAvgLum;
	}

	GroupMemoryBarrierWithGroupSync();

	if (dispatchThreadId.x == 0) {
		float fFinalLumValue = avgLum;
		fFinalLumValue += dispatchThreadId.x + 16 < GroupSize ? SharedAvgFinal[dispatchThreadId.x + 16] : avgLum;
		fFinalLumValue += dispatchThreadId.x + 32 < GroupSize ? SharedAvgFinal[dispatchThreadId.x + 32] : avgLum;
		fFinalLumValue += dispatchThreadId.x + 48 < GroupSize ? SharedAvgFinal[dispatchThreadId.x + 48] : avgLum;
		fFinalLumValue /= 64.0;

		//AverageLum[0] = max(fFinalLumValue, 0.0001);
		//float preAvgLum = max(PrevAvgLum[0], 0.0001);
		float fAdaptedAverageLum = lerp(PrevAvgLum[0], fFinalLumValue, Adaptation);
		AverageLum[0] = max(fAdaptedAverageLum, 0.0001);
	}
}