module tb_top #(
    parameter string PATTERN = "DVD" // One of, FRANCE, SQUARE, SQUARE_MV, DVD
) (
    input  var logic          clk,  
    input  var logic          rst,
    output var logic [16-1:0] SDL_sx,
    output var logic [16-1:0] SDL_sy,
    output var logic [8-1 :0] SDL_r,
    output var logic [8-1 :0] SDL_g,    
    output var logic [8-1 :0] SDL_b,
    output var logic          SDL_de 
);

    localparam shortint unsigned COLOR_DEPTH    = 4;
    localparam shortint unsigned H_PIXELS       = 640;
    localparam shortint unsigned V_PIXELS       = 480;
    localparam shortint unsigned H_PULSE        = 96;
    localparam shortint unsigned V_PULSE        = 2;
    localparam shortint unsigned H_F_PORCH      = 16;
    localparam shortint unsigned H_B_PORCH      = 48;
    localparam shortint unsigned V_F_PORCH      = 10;
    localparam shortint unsigned V_B_PORCH      = 33;
    localparam shortint unsigned H_TOTAL_PIXELS = H_PIXELS + H_PULSE + H_F_PORCH + H_B_PORCH;
    localparam shortint unsigned V_TOTAL_PIXELS = V_PIXELS + V_PULSE + V_F_PORCH + V_B_PORCH;
    localparam bit               H_POL          = 1'b1;
    localparam bit               V_POL          = 1'b1;

    shortint unsigned sx;
    shortint unsigned sy;
    logic             de;

    vga_vga #(
        .H_PIXELS  (H_PIXELS ),
        .V_PIXELS  (V_PIXELS ),
        .H_PULSE   (H_PULSE  ),
        .V_PULSE   (V_PULSE  ),
        .H_F_PORCH (H_F_PORCH),
        .H_B_PORCH (H_B_PORCH),
        .V_F_PORCH (V_F_PORCH),
        .V_B_PORCH (V_B_PORCH),
        .H_POL     (H_POL),
        .V_POL     (V_POL)
    ) display (
        .pxl_clk    (clk      ),
        .pxl_rst    (rst      ),
        .sx      (sx  ),
        .sy      (sy  ),
        .de (de   ),
        .hsync  (),
        .vsync  ()
    );

    // paint colour
    logic [3:0] paint_r, paint_g, paint_b;

    if (PATTERN == "SQUARE") begin
        // Square (fixed)
     :pattern

        vga_square #(
            .COLOR_DEPTH (COLOR_DEPTH),
            .H_PIXELS    (H_PIXELS   ),
            .V_PIXELS    (V_PIXELS   )
        ) painter (
            .sx (sx       ),
            .sy (sy       ),
            .de (de   ),
            .r  (paint_r  ),
            .g  (paint_g  ),
            .b  (paint_b  )
        );
    end else if (PATTERN == "FRANCE") begin :pattern
        // France flag
        vga_france #(
            .COLOR_DEPTH (COLOR_DEPTH),
            .H_PIXELS    (H_PIXELS   ),
            .V_PIXELS    (V_PIXELS   )
        ) painter (
            .sx (sx       ),
            .sy (sy       ),
            .de (de   ),
            .r  (paint_r  ),
            .g  (paint_g  ),
            .b  (paint_b  )
        );
    end else if (PATTERN == "SQUARE_MV") begin :pattern
        // Square (moving !)
        vga_square_mv #(
            .COLOR_DEPTH (COLOR_DEPTH),
            .H_PIXELS    (H_PIXELS   ),
            .V_PIXELS    (V_PIXELS   )
        ) painter (
            .clk (clk      ),
            .rst (rst      ),
            .sx  (sx       ),
            .sy  (sy       ),
            .de  (de       ),
            .r   (paint_r  ),
            .g   (paint_g  ),
            .b   (paint_b  )
        );
    end else if (PATTERN == "DVD") begin :pattern
        // DVD (moving !)
        vga_dvd #(
            .COLOR_DEPTH (COLOR_DEPTH),
            .H_PIXELS    (H_PIXELS   ),
            .V_PIXELS    (V_PIXELS   )
        ) painter (
            .clk (clk      ),
            .rst (rst      ),
            .sx  (sx       ),
            .sy  (sy       ),
            .de  (de       ),
            .r   (paint_r  ),
            .g   (paint_g  ),
            .b   (paint_b  )
        );
    end 
     
    // SDL: Output as 8 bits
    always_ff @ (posedge clk, negedge rst) begin
        SDL_sx      <= sx;
        SDL_sy      <= sy;
        SDL_de      <= de;
        SDL_r       <= {2{paint_r}};  // double signal width from 4 to 8 bits
        SDL_g       <= {2{paint_g}};
        SDL_b       <= {2{paint_b}};
    end

    final begin
        $finish;
    end 

endmodule