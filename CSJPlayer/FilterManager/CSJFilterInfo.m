//
//  CSJFilterInfo.m
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/10/16.
//

#import "CSJFilterInfo.h"

@implementation CSJFilterInfo

- (NSString *)FilterNameWithType:(FilterType)filterType {
    
    NSString *filterName = @"";
    switch (filterType) {
        
    case FILTERTYPE_SATURATION: filterName = @"Saturation"; break;
    case FILTERTYPE_CONTRAST: filterName = @"Contrast"; break;
    case FILTERTYPE_BRIGHTNESS: filterName = @"Brightness"; break;
    case FILTERTYPE_LEVELS: filterName = @"Levels"; break;
    case FILTERTYPE_EXPOSURE: filterName = @"Exposure"; break;
    case FILTERTYPE_RGB: filterName = @"RGB"; break;
    case FILTERTYPE_HUE: filterName = @"Hue"; break;
    case FILTERTYPE_WHITEBALANCE: filterName = @"White balance"; break;
    case FILTERTYPE_MONOCHROME: filterName = @"Monochrome"; break;
    case FILTERTYPE_GRAYSCALE: filterName = @"Grayscale"; break;
    case FILTERTYPE_HISTOGRAM: filterName = @"Histogram"; break;
    case FILTERTYPE_AVERAGECOLOR: filterName = @"Average color"; break;
    case FILTERTYPE_LUMINOSITY: filterName = @"Average luminosity"; break;
    case FILTERTYPE_THRESHOLD: filterName = @"Threshold"; break;
    case FILTERTYPE_ADAPTIVETHRESHOLD: filterName = @"Adaptive threshold"; break;
    case FILTERTYPE_AVERAGELUMINANCETHRESHOLD: filterName = @"Average luminance threshold"; break;
    case FILTERTYPE_PIXELLATE: filterName = @"Pixellate"; break;
    case FILTERTYPE_POLARPIXELLATE: filterName = @"Polar pixellation"; break;
    case FILTERTYPE_PIXELLATE_POSITION: filterName = @"Pixellate (position)"; break;
    case FILTERTYPE_POLKADOT: filterName = @"Polka dot"; break;
    case FILTERTYPE_HALFTONE: filterName = @"Halftone"; break;
    case FILTERTYPE_CROSSHATCH: filterName = @"Crosshatch"; break;
    case FILTERTYPE_SOBELEDGEDETECTION: filterName = @"Sobel edge detection"; break;
    case FILTERTYPE_PREWITTEDGEDETECTION: filterName = @"Prewitt edge detection"; break;
    case FILTERTYPE_CANNYEDGEDETECTION: filterName = @"Canny edge detection"; break;
    case FILTERTYPE_THRESHOLDEDGEDETECTION: filterName = @"Threshold edge detection"; break;
    case FILTERTYPE_HARRISCORNERDETECTION: filterName = @"Harris corner detector"; break;
    case FILTERTYPE_NOBLECORNERDETECTION: filterName = @"Noble corner detector"; break;
    case FILTERTYPE_SHITOMASIFEATUREDETECTION: filterName = @"Shi-Tomasi feature detector"; break;
    case FILTERTYPE_HOUGHTRANSFORMLINEDETECTOR: filterName = @"Hough transform line detector"; break;
    case FILTERTYPE_BUFFER: filterName = @"Image buffer"; break;
    case FILTERTYPE_LOWPASS: filterName = @"Low pass"; break;
    case FILTERTYPE_HIGHPASS: filterName = @"High pass"; break;
    case FILTERTYPE_MOTIONDETECTOR: filterName = @"Motion detector"; break;
    case FILTERTYPE_XYGRADIENT: filterName = @"X-Y gradient"; break;
    case FILTERTYPE_SKETCH: filterName = @"Sketch"; break;
    case FILTERTYPE_THRESHOLDSKETCH: filterName = @"Threshold sketch"; break;
    case FILTERTYPE_TOON: filterName = @"Toon"; break;
    case FILTERTYPE_SMOOTHTOON: filterName = @"Smooth toon"; break;
    case FILTERTYPE_TILTSHIFT: filterName = @"Tilt shift"; break;
    case FILTERTYPE_CGA: filterName = @"CGA colorspace"; break;
    case FILTERTYPE_POSTERIZE: filterName = @"Posterize"; break;
    case FILTERTYPE_CONVOLUTION: filterName = @"3x3 convolution"; break;
    case FILTERTYPE_EMBOSS: filterName = @"Emboss"; break;
    case FILTERTYPE_LAPLACIAN: filterName = @"Laplacian (3x3)"; break;
    case FILTERTYPE_CHROMAKEYNONBLEND: filterName = @"Chroma key"; break;
    case FILTERTYPE_KUWAHARA: filterName = @"Kuwahara"; break;
    case FILTERTYPE_KUWAHARARADIUS3: filterName = @"Kuwahara (radius 3)"; break;
    case FILTERTYPE_VIGNETTE: filterName = @"Vignette"; break;
    case FILTERTYPE_FALSECOLOR: filterName = @"False color"; break;
    case FILTERTYPE_SHARPEN: filterName = @"Sharpen"; break;
    case FILTERTYPE_UNSHARPMASK: filterName = @"Unsharp mask"; break;
    case FILTERTYPE_TRANSFORM: filterName = @"Transform (2-D)"; break;
    case FILTERTYPE_TRANSFORM3D: filterName = @"Transform (3-D)"; break;
    case FILTERTYPE_CROP: filterName = @"Crop"; break;
    case FILTERTYPE_MASK: filterName = @"Mask"; break;
    case FILTERTYPE_GAMMA: filterName = @"Gamma"; break;
    case FILTERTYPE_TONECURVE: filterName = @"Tone curve"; break;
    case FILTERTYPE_HIGHLIGHTSHADOW: filterName = @"Highlights and shadows"; break;
    case FILTERTYPE_HAZE: filterName = @"Haze"; break;
    case FILTERTYPE_SEPIA: filterName = @"Sepia tone"; break;
    case FILTERTYPE_AMATORKA: filterName = @"Amatorka (Lookup)"; break;
    case FILTERTYPE_MISSETIKATE: filterName = @"Miss Etikate (Lookup)"; break;
    case FILTERTYPE_SOFTELEGANCE: filterName = @"Soft elegance (Lookup)"; break;
    case FILTERTYPE_COLORINVERT: filterName = @"Color invert"; break;
    case FILTERTYPE_GAUSSIAN: filterName = @"Gaussian blur"; break;
    case FILTERTYPE_GAUSSIAN_SELECTIVE: filterName = @"Gaussian selective blur"; break;
    case FILTERTYPE_GAUSSIAN_POSITION: filterName = @"Gaussian (centered)"; break;
    case FILTERTYPE_BOXBLUR: filterName = @"Box blur"; break;
    case FILTERTYPE_MEDIAN: filterName = @"Median (3x3)"; break;
    case FILTERTYPE_BILATERAL: filterName = @"Bilateral blur"; break;
    case FILTERTYPE_MOTIONBLUR: filterName = @"Motion blur"; break;
    case FILTERTYPE_ZOOMBLUR: filterName = @"Zoom blur"; break;
    case FILTERTYPE_SWIRL: filterName = @"Swirl"; break;
    case FILTERTYPE_BULGE: filterName = @"Bulge"; break;
    case FILTERTYPE_PINCH: filterName = @"Pinch"; break;
    case FILTERTYPE_SPHEREREFRACTION: filterName = @"Sphere refraction"; break;
    case FILTERTYPE_GLASSSPHERE: filterName = @"Glass sphere"; break;
    case FILTERTYPE_STRETCH: filterName = @"Stretch"; break;
    case FILTERTYPE_DILATION: filterName = @"Dilation"; break;
    case FILTERTYPE_EROSION: filterName = @"Erosion"; break;
    case FILTERTYPE_OPENING: filterName = @"Opening"; break;
    case FILTERTYPE_CLOSING: filterName = @"Closing"; break;
    case FILTERTYPE_PERLINNOISE: filterName = @"Perlin noise"; break;
    case FILTERTYPE_VORONOI: filterName = @"Voronoi"; break;
    case FILTERTYPE_MOSAIC: filterName = @"Mosaic"; break;
    case FILTERTYPE_LOCALBINARYPATTERN: filterName = @"Local binary pattern"; break;
    case FILTERTYPE_DISSOLVE: filterName = @"Dissolve blend"; break;
    case FILTERTYPE_CHROMAKEY: filterName = @"Chroma key blend (green)"; break;
    case FILTERTYPE_ADD: filterName = @"Add blend"; break;
    case FILTERTYPE_DIVIDE: filterName = @"Divide blend"; break;
    case FILTERTYPE_MULTIPLY: filterName = @"Multiply blend"; break;
    case FILTERTYPE_OVERLAY: filterName = @"Overlay blend"; break;
    case FILTERTYPE_LIGHTEN: filterName = @"Lighten blend"; break;
    case FILTERTYPE_DARKEN: filterName = @"Darken blend"; break;
    case FILTERTYPE_COLORBURN: filterName = @"Color burn blend"; break;
    case FILTERTYPE_COLORDODGE: filterName = @"Color dodge blend"; break;
    case FILTERTYPE_LINEARBURN: filterName = @"Linear burn blend"; break;
    case FILTERTYPE_SCREENBLEND: filterName = @"Screen blend"; break;
    case FILTERTYPE_DIFFERENCEBLEND: filterName = @"Difference blend"; break;
    case FILTERTYPE_SUBTRACTBLEND: filterName = @"Subtract blend"; break;
    case FILTERTYPE_EXCLUSIONBLEND: filterName = @"Exclusion blend"; break;
    case FILTERTYPE_HARDLIGHTBLEND: filterName = @"Hard light blend"; break;
    case FILTERTYPE_SOFTLIGHTBLEND: filterName = @"Soft light blend"; break;
    case FILTERTYPE_COLORBLEND: filterName = @"Color blend"; break;
    case FILTERTYPE_HUEBLEND: filterName = @"Hue blend"; break;
    case FILTERTYPE_SATURATIONBLEND: filterName = @"Saturation blend"; break;
    case FILTERTYPE_LUMINOSITYBLEND: filterName = @"Luminosity blend"; break;
    case FILTERTYPE_NORMALBLEND: filterName = @"Normal blend"; break;
    case FILTERTYPE_POISSONBLEND: filterName = @"Poisson blend"; break;
    case FILTERTYPE_OPACITY: filterName = @"Opacity adjustment"; break;
    case FILTERTYPE_NUMFILTERS: filterName = @""; break;
        
    }
    
    return filterName;
}

@end
