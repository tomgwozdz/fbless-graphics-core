module dump();
    initial begin
        $dumpfile ("vga_background.vcd");
        $dumpvars (0, vga_background);
        #1;
    end
endmodule
