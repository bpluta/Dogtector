//
//  Detector.hpp
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

#ifndef Detector_hpp
#define Detector_hpp

typedef struct {
    unsigned int classId;
    float observationPrecission;
    float precission;
    float x;
    float y;
    float width;
    float height;
} Yolo5ObjectObservation;

typedef struct {
    unsigned int class_amount;
    float confidence_threshold;

    unsigned int channel_stride;
    unsigned int vertical_stride;
    unsigned int horizontal_stride;
    
    unsigned int boxes;
    unsigned int rows;
    unsigned int cols;
    
    float vertical_block_size;
    float horizontal_block_size;
} Yolo5LayerSetup;

#endif /* Detector_hpp */
