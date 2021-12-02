//
//  Detector.metal
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

#include <metal_stdlib>
#include "Detector.hpp"

using namespace metal;

/*
 
 Full Metal processor
 - Fastest solution (does not require further processing on CPU)
 - Returns filtered objects which confidence is above defined threshold
 - Designed for iOS Family 4 GPU and newer (with non-uniform thread grid support)
 
 */
kernel void decode_yolo5(const device float* data [[ buffer(0) ]],
                         const device Yolo5LayerSetup& layer_setup [[ buffer(1) ]],
                         const device float* anchors [[ buffer(2) ]],
                         device Yolo5ObjectObservation* output [[ buffer(3) ]],
                         device atomic_int& output_size [[ buffer(4) ]],
                         const uint3 threadgroup_position_in_grid [[ threadgroup_position_in_grid ]],
                         const uint3 threads_per_threadgroup [[ threads_per_threadgroup ]],
                         const uint3 thread_position_in_threadgroup [[ thread_position_in_threadgroup ]]) {
    
    uint3 thread_position_in_grid = (threadgroup_position_in_grid * threads_per_threadgroup) + thread_position_in_threadgroup;
    
    uint col = thread_position_in_grid.x;
    uint row = thread_position_in_grid.y;
    uint box = thread_position_in_grid.z;
    
    uint data_index = box * layer_setup.channel_stride + row * layer_setup.vertical_stride + col * layer_setup.horizontal_stride;
    uint class_precission_index = data_index + 5;
    
    uint xIndex = data_index;
    uint yIndex = data_index + 1;
    uint wIndex = data_index + 2;
    uint hIndex = data_index + 3;
    uint pIndex = data_index + 4;
    
    uint wAnchorIndex = 2 * box;
    uint hAnchorIndex = 2 * box + 1;
    
    Yolo5ObjectObservation observation;
    observation.observationPrecission =  1.0 / (1.0 + exp(-data[pIndex]));
    
    if (observation.observationPrecission <= layer_setup.confidence_threshold) { return; }
    
    observation.x = ((1.0 / (1.0 + exp(-data[xIndex]))) * 2.0 - 0.5 + col) * layer_setup.horizontal_block_size;
    observation.y = ((1.0 / (1.0 + exp(-data[yIndex]))) * 2.0 - 0.5 + row) * layer_setup.vertical_block_size;
    observation.width = pow((1.0 / (1.0 + exp(-data[wIndex]))) * 2.0, 2) * anchors[wAnchorIndex];
    observation.height = pow((1.0 / (1.0 + exp(-data[hIndex]))) * 2.0, 2) * anchors[hAnchorIndex];
    
    for (uint object_class = 0; object_class < layer_setup.class_amount; object_class++) {
        uint classIndex = class_precission_index + object_class;
        float class_precission = 1.0 / (1.0 + exp(-data[classIndex]));
        float score = observation.observationPrecission * class_precission;
        
        if (score >= layer_setup.confidence_threshold) {
            Yolo5ObjectObservation object_observation = observation;
            object_observation.classId = object_class;
            object_observation.precission = class_precission;
            int index = atomic_fetch_add_explicit(&output_size, 1, memory_order_relaxed);
            output[index] = object_observation;
        }
    }
}

/*
 
 Hybrid processor:
 - Walkaround for iOS GPU Family 3 issue with atomic operations within loop
 - Just processing output matrix (filtering on CPU required)
 - Support for devices with only uniform GPU thread grids
 
 */
kernel void decode_yolo5_hybrid(device float* data [[ buffer(0) ]],
                                const device Yolo5LayerSetup& layer_setup [[ buffer(1) ]],
                                const device float* anchors [[ buffer(2) ]],
                                const uint3 threadgroup_position_in_grid [[ threadgroup_position_in_grid ]],
                                const uint3 threads_per_threadgroup [[ threads_per_threadgroup ]],
                                const uint3 thread_position_in_threadgroup [[ thread_position_in_threadgroup ]]) {
    
    uint3 thread_position_in_grid = (threadgroup_position_in_grid * threads_per_threadgroup) + thread_position_in_threadgroup;
    
    uint col = thread_position_in_grid.x;
    uint row = thread_position_in_grid.y;
    uint box = thread_position_in_grid.z;
    
    if (col >= layer_setup.cols || row >= layer_setup.rows || box >= layer_setup.boxes) { return; }
    
    uint data_index = box * layer_setup.channel_stride + row * layer_setup.vertical_stride + col * layer_setup.horizontal_stride;
    uint class_precission_index = data_index + 5;
    
    uint xIndex = data_index;
    uint yIndex = data_index + 1;
    uint wIndex = data_index + 2;
    uint hIndex = data_index + 3;
    uint pIndex = data_index + 4;
    
    uint wAnchorIndex = 2 * box;
    uint hAnchorIndex = 2 * box + 1;
    
    float detection_precission = 1.0 / (1.0 + exp(-data[pIndex]));
    
    data[xIndex] = ((1.0 / (1.0 + exp(-data[xIndex]))) * 2.0 - 0.5 + col) * layer_setup.horizontal_block_size;
    data[yIndex] = ((1.0 / (1.0 + exp(-data[yIndex]))) * 2.0 - 0.5 + row) * layer_setup.vertical_block_size;
    data[wIndex] = pow((1.0 / (1.0 + exp(-data[wIndex]))) * 2.0, 2) * anchors[wAnchorIndex];
    data[hIndex] = pow((1.0 / (1.0 + exp(-data[hIndex]))) * 2.0, 2) * anchors[hAnchorIndex];
    data[pIndex] = detection_precission;
    
    for (uint object_class = 0; object_class < layer_setup.class_amount; object_class++) {
        uint classIndex = class_precission_index + object_class;
        float class_precission = 1.0 / (1.0 + exp(-data[classIndex]));
        float score = detection_precission * class_precission;
        data[classIndex] = score;
    }
}
