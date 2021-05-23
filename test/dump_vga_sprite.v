module dump();
    initial begin
        $dumpfile ("vga_sprite.vcd");
        $dumpvars (0, vga_sprite);
        #1;
    end
endmodule
