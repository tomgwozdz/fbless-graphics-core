module dump();
    initial begin
        $dumpfile ("vga_core.vcd");
        $dumpvars (0, vga_core);
        #1;
    end
endmodule
