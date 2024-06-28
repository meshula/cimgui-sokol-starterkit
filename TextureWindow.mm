//
//  TextureWindow.cpp
//  demo
//
//  Created by Nick Porcino on 6/27/24.
//

#include "TextureWindow.h"
#import <Metal/Metal.h>

#include "cimgui/imgui/imgui.h"

#include "sokol_app.h"
#include "sokol_gfx.h"
#include "sokol_imgui.h"

#include "levr.h"

#include <vector>


//------------------------------------------------------------------------------
// levr demo
LEVR_Screen screen = {0};
LEVR_State state = {0};
LEVR_Grid grid = {0};
LEVR_MaterialSet ms = {0};
LEVR_Camera cam = {0};
LEVR_Scene scene = {0};
#define SCWIDTH 256
#define SCHEIGHT 144

void draw_pixel(LEVR_State* state, LEVR_Pixel* pixel){
    screen.pixels[pixel->x + pixel->y * screen.width] = pixel->color;
}

void CreateWalls()
{
    int i, j, k;
    for (i = 0; i < grid.width; i++)
    {
        grid.voxels[i*grid.width*grid.height + 1*grid.width + 1] = 3;
        grid.voxels[1*grid.width*grid.height + i*grid.width + 1] = 2;
        grid.voxels[1*grid.width*grid.height + 1*grid.width + i] = 1;

    }
}

void CreateGrid()
{
    grid.width = 512;
    grid.height = 512;
    grid.depth = 512;
    grid.voxels = (uint8_t*) malloc(grid.width * grid.height * grid.depth * sizeof(uint8_t));
    uint8_t *buf = (uint8_t*) malloc(256 * 256 * 256 * sizeof(uint8_t));

    FILE *file = fopen("/var/tmp/cimgui-sokol-starterkit/sponza.raw", "r");
    int c;
    int i = 0;
    int j = 0;
    int k = 0;
    while ((c = fgetc(file)) != EOF)
    {
        buf[i] = c - '0';
        i++;
    }
    fclose(file);
    for(i = 0; i < 256; i++){
        for(j = 0; j < 256; j++){
            for(k = 0; k < 256; k++){
                grid.voxels[(k)*grid.width*grid.height + (j)*grid.height + (i)] = buf[k*255*255 + j*255+i];
            }
        }
    }
    free(buf);

    grid.voxels[(50)*grid.width*grid.height + (20)*grid.height + (50)] = 4;
}

void InitMaterials(){
    ms.max_materials = 6;

    LEVR_Material air = {0};
    air.color = LEVR_rgb_to_u32(0, 0, 0);

    LEVR_Material red = {0};
    red.color = LEVR_rgb_to_u32(100, 0, 0);
    red.emittance = 0;
    red.ambient = 0.5;
    red.diffuse = 0;


    LEVR_Material green = {0};
    green.color = LEVR_rgb_to_u32(0, 100, 0);
    green.emittance = 0;
    green.ambient = 0.5;
    green.diffuse = 0;

    LEVR_Material blue = {0};
    blue.color = LEVR_rgb_to_u32(0, 0, 100);
    blue.emittance = 0;
    blue.ambient = 0.5;
    blue.diffuse = 0;

    LEVR_Material light = {0};
    light.color = 0xFFFFFF;
    light.emittance = 1.0;

    LEVR_Material yellow = {0};
    yellow.color = LEVR_rgb_to_u32(0, 100, 100);
    yellow.emittance = 0;
    yellow.ambient = 0.5;
    yellow.diffuse = 0;

    ms.materials = (LEVR_Material*) malloc(sizeof(LEVR_Material) * ms.max_materials);
    ms.materials[0] = air;
    ms.materials[1] = red;
    ms.materials[2] = green;
    ms.materials[3] = blue;
    ms.materials[4] = light;
    ms.materials[5] = yellow;
}

void CreateCamera(){
    cam.width = SCWIDTH;
    cam.height = SCHEIGHT;

    LEVR_vec3 pos = {9, 9, 9};
    LEVR_vec3 dir = {0.1, 0.1, 0};
    LEVR_vec3 up = {0, 1, 0};
    cam.pos = pos;
    cam.dir = dir;
    cam.up = up;
    cam.fov = 70;
}

LEVR_vec3 forward = {0, 0, 1};
LEVR_vec3 right = {1, 0, 0};
LEVR_vec3 up = {0, 1, 0};
LEVR_REAL speed = 2;
bool initLevr = true;

simgui_image_t sg_ig_levr_image;
ImTextureID levr_tex_id;
sg_image sg_levr_image;

void InitLevr(int width, int height) {
    LEVR_screen_resize(&screen, SCWIDTH, SCHEIGHT);
    LEVR_screen_flush(&screen, 0xffffff);
    CreateCamera();
    CreateGrid();
    //CreateWalls();
    InitMaterials();
    int cell = 0;
    scene.grid = grid;
    scene.max_lights = 2;
    scene.lights = (LEVR_vec3i*) malloc(scene.max_lights * sizeof(LEVR_vec3i));
    scene.lights[0] = (LEVR_vec3i){50, 20, 50};
    scene.lights[1] = (LEVR_vec3i){30, 10, 60};
    state.set_pixel = &draw_pixel;
    state.flags = 0;

    sg_image_desc image_desc;
    memset(&image_desc, 0, sizeof(image_desc));
    image_desc.width = width;
    image_desc.height = height;
    image_desc.pixel_format = SG_PIXELFORMAT_RGBA8;
    image_desc.usage = SG_USAGE_DYNAMIC;
 /*   image_desc.data.subimage[0][0] = {
        .ptr = checkerboard.data(),
        .size = checkerboard.size()
    };*/
    sg_levr_image = sg_make_image(&image_desc);

    sg_sampler_desc sampler_desc = {};
    sampler_desc.min_filter = SG_FILTER_NEAREST;
    sampler_desc.mag_filter = SG_FILTER_NEAREST;
    sampler_desc.wrap_u = SG_WRAP_CLAMP_TO_EDGE;
    sampler_desc.wrap_v = SG_WRAP_CLAMP_TO_EDGE;

    sg_sampler smp = sg_make_sampler(&sampler_desc);

    simgui_image_desc_t ig_desc = {
        .image = sg_levr_image,
        .sampler = smp,
    };

    sg_ig_levr_image = simgui_make_image(&ig_desc);
    levr_tex_id = simgui_imtextureid(sg_ig_levr_image);
}


void DrawLevr(int width, int height) {
    if (initLevr) {
        initLevr = false;
        InitLevr(width, height);
    }

    LEVR_render(&state, cam, scene, ms);

    sg_image_data image_data = {};
    image_data.subimage[0][0] = {
        .ptr = screen.pixels,
        .size = screen.width * screen.height * 4
    };

    sg_update_image(sg_levr_image, &image_data);
}


extern "C"
void LevrWindow() {
    ImGui::Begin("Levr");

    const int width = SCWIDTH;
    const int height = SCHEIGHT;

    DrawLevr(width, height);
    ImVec2 textureSize(width * 2, height * 2);
    ImGui::Image(levr_tex_id, textureSize);

    ImGui::End();
}








// Declare global Metal objects
id<MTLDevice> g_device = nil;
id<MTLCommandQueue> g_commandQueue = nil;
id<MTLTexture> g_checkerboardTexture = nil;
ImTextureID g_textureID = nullptr;
sg_image sg_checkerboard_image;
simgui_image_t sg_ig_checkerboard_image;
ImTextureID tex_id;

void InitializeMetal() {
    g_device = MTLCreateSystemDefaultDevice();
    g_commandQueue = [g_device newCommandQueue];
}

// Function to create the checkerboard pattern
extern "C"
void CreateCheckerboard(int width, int height) {
    if (!g_device)
        InitializeMetal();
    
    std::vector<uint8_t> checkerboard(width * height * 4);
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            int index = (y * width + x) * 4;
            if ((x / 16 + y / 16) % 2 == 0) {
                checkerboard[index] = 255;     // R
                checkerboard[index + 1] = 255; // G
                checkerboard[index + 2] = 255; // B
                checkerboard[index + 3] = 255; // A
            } else {
                checkerboard[index] = 0;       // R
                checkerboard[index + 1] = 0;   // G
                checkerboard[index + 2] = 0;   // B
                checkerboard[index + 3] = 255; // A
            }
        }
    }
    MTLTextureDescriptor *textureDesc = [[MTLTextureDescriptor alloc] init];
    textureDesc.pixelFormat = MTLPixelFormatRGBA8Unorm;
    textureDesc.width = width;
    textureDesc.height = height;
    textureDesc.usage = MTLTextureUsageShaderRead;

    g_checkerboardTexture = [g_device newTextureWithDescriptor:textureDesc];
    MTLRegion region = {{0, 0, 0}, {(NSUInteger) width, (NSUInteger) height, 1}};
    [g_checkerboardTexture replaceRegion:region
                             mipmapLevel:0
                               withBytes:checkerboard.data()
                             bytesPerRow:width * 4];

    sg_image_desc image_desc;
    memset(&image_desc, 0, sizeof(image_desc));
    image_desc.width = width;
    image_desc.height = height;
    image_desc.pixel_format = SG_PIXELFORMAT_RGBA8;
    image_desc.usage = SG_USAGE_DYNAMIC;
 /*   image_desc.data.subimage[0][0] = {
        .ptr = checkerboard.data(),
        .size = checkerboard.size()
    };*/
    sg_checkerboard_image = sg_make_image(&image_desc);

    sg_sampler_desc sampler_desc = {};
    sampler_desc.min_filter = SG_FILTER_NEAREST;
    sampler_desc.mag_filter = SG_FILTER_NEAREST;
    sampler_desc.wrap_u = SG_WRAP_CLAMP_TO_EDGE;
    sampler_desc.wrap_v = SG_WRAP_CLAMP_TO_EDGE;

    sg_sampler smp = sg_make_sampler(&sampler_desc);

    simgui_image_desc_t ig_desc = {
        .image = sg_checkerboard_image,
        .sampler = smp,
    };

    sg_ig_checkerboard_image = simgui_make_image(&ig_desc);
    tex_id = simgui_imtextureid(sg_ig_checkerboard_image);
}

void UpdateCheckerboardTexture(int width, int height) {
    std::vector<uint8_t> checkerboard(width * height * 4);

    static uint8_t flick = 0;

    // Modify the checkerboard pattern or update it in some way
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            int index = (y * width + x) * 4;
            if ((x / 16 + y / 16) % 2 == 0) {
                checkerboard[index] = 255;     // R
                checkerboard[index + 1] = flick; // G
                checkerboard[index + 2] = flick; // B
                checkerboard[index + 3] = 255; // A
            } else {
                checkerboard[index] = 0;       // R
                checkerboard[index + 1] = 0;   // G
                checkerboard[index + 2] = 0;   // B
                checkerboard[index + 3] = 255; // A
            }
        }
    }

    flick += 1;

    sg_image_data image_data = {};
    image_data.subimage[0][0] = {
        .ptr = checkerboard.data(),
        .size = checkerboard.size()
    };

    sg_update_image(sg_checkerboard_image, &image_data);
}


extern "C"
void CheckerBoardWindow() {
    ImGui::Begin("Checkerboard");

    const int width = SCWIDTH;
    const int height = SCHEIGHT;

    if (!g_checkerboardTexture) {
        CreateCheckerboard(width, height);
        //if (g_checkerboardTexture)
        //    g_textureID = ImGui_ImplMetal_AddTexture(g_checkerboardTexture);
    }
    else {
        UpdateCheckerboardTexture(width, height);
    }
    if (g_checkerboardTexture) {
    //if (g_textureID) {
        ImVec2 textureSize(width, height);
        //ImGui::Image(g_textureID, textureSize);
        ImGui::Image(tex_id, textureSize);
    }

    ImGui::End();
}

