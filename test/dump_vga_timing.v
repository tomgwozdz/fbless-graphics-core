module dump();
    initial begin
        $dumpfile ("vga_timing.vcd");
        $dumpvars (0, vga_timing);
        #1;
    end
endmodule
