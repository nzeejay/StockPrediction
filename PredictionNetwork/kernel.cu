﻿//Kernel code:
extern "C"
{
	__device__ int getIndex(int x, int y, int z, int X, int Y) {
		return (x + (y * Y)) + (z * X * Y);
	}

	__device__ float sigmoid(float f) {
		return 1 / (1 + __expf(-f));
	}

	__device__ float sigmoidDer(float f) {
		return f * (1 - f);
	}

	//activations
	__global__ void Sigmoid(float*bpData, float* data) {
		int ID = getIndex(blockIdx.x, blockIdx.y, blockIdx.z, gridDim.x, gridDim.y);

		data[ID] = sigmoid(bpData[ID]);
	}

	// Device code
	__global__ void Forward(float* data, float* weights, float* prev) {

		//__shared__ float thisNode;
		//
		//__syncthreads();

		int thisLayerID = getIndex(blockIdx.x, blockIdx.y, blockIdx.z, gridDim.x, gridDim.y);

		int prevLayerID = getIndex(threadIdx.x, threadIdx.y, threadIdx.z, blockDim.x, blockDim.y);

		int weightID = thisLayerID * (blockDim.x * blockDim.y * blockDim.z) + prevLayerID;

		float val = prev[prevLayerID] * weights[weightID];

		//printf("%f \r\n", val);

		atomicAdd(&data[thisLayerID], val);

		//__syncthreads();
		//
		////activation function
		//if (threadIdx.x + threadIdx.y + threadIdx.z == 0) 
		//	data[thisLayerID] = sigmoid(thisNode);

	}

	__global__ void Backprop(float* data, float* bpData, float* weights, float* prev, float* error, float* prevError, float step) {
		int blockSize = (blockDim.x * blockDim.y * blockDim.z);

		int thisLayerID = getIndex(blockIdx.x, blockIdx.y, blockIdx.z, gridDim.x, gridDim.y);

		int prevLayerID = getIndex(threadIdx.x, threadIdx.y, threadIdx.z, blockDim.x, blockDim.y);

		int weightID = thisLayerID * blockSize + prevLayerID;

		float prevActGD = weights[weightID] * sigmoidDer(bpData[prevLayerID]) * error[thisLayerID];
		atomicAdd(&prevError[prevLayerID], prevActGD);

		float weightGD = prev[prevLayerID] * sigmoidDer(bpData[prevLayerID]) * error[thisLayerID];
		weights[weightID] += -step * weightGD;
		
		//printf("%i %i %i %f %f\r\n", thisLayerID, prevLayerID, weightID, weightGD, prevActGD);
	}

	__global__ void Clear(float* data, float* bpData, float* error) {
		int ID = getIndex(blockIdx.x, blockIdx.y, blockIdx.z, gridDim.x, gridDim.y);
		
		data[ID] = 0.f;
		bpData[ID] = 0.f;
		error[ID] = 0.f;
	}
}