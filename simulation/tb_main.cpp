#include <SDL3/SDL.h>
#include <verilated.h>
#include "Vtb_top.h"

// screen dimensions
const int H_RES = 640;
const int V_RES = 480;

typedef struct Pixel
{              // for SDL texture
    uint8_t a; // transparency
    uint8_t b; // blue
    uint8_t g; // green
    uint8_t r; // red
} Pixel;

int main(int argc, char *argv[])
{
    Verilated::commandArgs(argc, argv);

    SDL_Window *sdl_window;
    SDL_Renderer *sdl_renderer;
    SDL_Texture *sdl_texture;
    SDL_Event sdl_event;

    if (!SDL_Init(SDL_INIT_VIDEO))
    {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't initialize SDL: %s", SDL_GetError());
        return 3;
    }

    Pixel screenbuffer[H_RES * V_RES]; 

    if (!SDL_CreateWindowAndRenderer("SDL", H_RES, V_RES, 0, &sdl_window, &sdl_renderer)) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't create window and renderer: %s", SDL_GetError());
        return 3;
    }

    sdl_texture = SDL_CreateTexture(sdl_renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_STREAMING, H_RES, V_RES);
    if (!sdl_texture)
    {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't create texture from surface: %s", SDL_GetError());
        return 3;
    }

    // initialize Verilog module
    Vtb_top *top = new Vtb_top;

    // reset
    top->rst = 0;
    top->clk = 0;
    top->eval();
    top->clk = 1;
    top->eval();
    top->rst = 1;
    top->clk = 0;
    top->eval();

    // initialize frame rate
    uint64_t start_ticks = SDL_GetPerformanceCounter();
    uint64_t frame_count = 0;

    // main loop
    while (1)
    {
        // Cycle the clock
        top->clk = 1;
        top->eval();
        top->clk = 0;
        top->eval();

        // Update pixel if not in blanking interval
        if (top->SDL_de)
        {
            Pixel *p = &screenbuffer[top->SDL_sy * H_RES + top->SDL_sx];
            p->a = 0xFF; // transparency
            p->b = top->SDL_b;
            p->g = top->SDL_g;
            p->r = top->SDL_r;
        }

        // update texture once per frame (in blanking)
        if (top->SDL_sy == V_RES && top->SDL_sx == 0)
        {
            SDL_UpdateTexture(sdl_texture, NULL, screenbuffer, H_RES * sizeof(Pixel));
            SDL_RenderClear(sdl_renderer);
            SDL_RenderTexture(sdl_renderer, sdl_texture, NULL, NULL);
            SDL_RenderPresent(sdl_renderer);
            frame_count++;

            // Poll events once per frame
            SDL_PollEvent(&sdl_event);
            if (sdl_event.type == SDL_EVENT_QUIT) {
                break;
            }
        }
    }

    // Calculate frame rate
    uint64_t end_ticks = SDL_GetPerformanceCounter();
    double duration = ((double)(end_ticks - start_ticks)) / SDL_GetPerformanceFrequency();
    double fps = (double)frame_count / duration;
    SDL_Log("Frames per second: %.1f\n", fps);

    top->final(); // simulation done

    // SDL Cleanup
    SDL_DestroyTexture(sdl_texture);
    SDL_DestroyRenderer(sdl_renderer);
    SDL_DestroyWindow(sdl_window);

    SDL_Quit();

    return 0;
}