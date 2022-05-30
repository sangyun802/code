module d_cache(
    input clk,
    input reset_n,
    input readC,                //read cache
    input writeC,               //write cache
    input BG,
    input [15:0] address,
    inout [63:0] mem_data,      //from/to memory
    input [15:0] write_data,    //data from pipeline rt
    output reg [15:0] cache_data,   //output data from cache
    output hit,
    output reg readM,               //read memory
    output reg writeM,              //write memory
    output reg [15:0] mem_address,   //input to memory address
    output reg [1:0] mem_count
);
    integer count;                          //for cache reset
    wire[11:0] tag;
    wire[1:0] idx, bo;

    assign tag=address[15:4];
    assign idx=address[3:2];
    assign bo=address[1:0];

    reg [76:0] direct_mapped_cache [3:0];

    always@(*)begin
        //reset
        if(!reset_n)begin
            mem_count<=2'b00;
            for(count=0;count<4;count=count+1)
                direct_mapped_cache[count]=77'd0;
        end
    end
    
    wire[11:0] cache_tag=direct_mapped_cache[idx][76:65];
    wire cache_valid=direct_mapped_cache[idx][64];

    assign hit=(cache_tag==tag)&cache_valid;   //determine hit

    reg[63:0] to_mem_data;                     //input data to memory
    assign mem_data=writeM?to_mem_data:64'bz;

    always@(*) begin
        if(writeC)begin
            readM=0;
            writeM=1;
        end
        else if(!hit&readC)begin
            readM=1;
            writeM=0;
        end
        else begin
            readM=0;
            writeM=0;
        end
    end
    always@(negedge clk)begin
        if(reset_n)begin
            if(readM|writeM)begin
                if(!BG)
                    mem_count<=mem_count+1;
                //stall if DMA access to memory
                else
                    mem_count<=2'b01;
            end
            if(writeC) begin
                //input to memory
                mem_address=address;
                    to_mem_data={16'h0000, 16'h0000, 16'h0000, write_data};
            end        
            if(hit) begin
                if(readC)begin
                    //data to datapath
                    case(bo)
                        2'b00: cache_data<=direct_mapped_cache[idx][15:0];
                        2'b01: cache_data<=direct_mapped_cache[idx][31:16];
                        2'b10: cache_data<=direct_mapped_cache[idx][47:32];
                        2'b11: cache_data<=direct_mapped_cache[idx][63:48];
                    endcase
                end
                else if(writeC)begin
                    //cache update
                    case(bo)
                        2'b00: direct_mapped_cache[idx][15:0]<=write_data;
                        2'b01: direct_mapped_cache[idx][31:16]<=write_data;
                        2'b10: direct_mapped_cache[idx][47:32]<=write_data;
                        2'b11: direct_mapped_cache[idx][63:48]<=write_data;
                    endcase
                end
            end
            else begin
                if(readC)begin
                    //cache update
                    mem_address={address[15:2], 2'b00};
                end
                if(readC&(mem_count==2'b11)) begin
                    direct_mapped_cache[idx]<={tag, 1'b1,mem_data};
                    case(bo)
                        2'b00: cache_data<=mem_data[15:0];
                        2'b01: cache_data<=mem_data[31:16];
                        2'b10: cache_data<=mem_data[47:32];
                        2'b11: cache_data<=mem_data[63:48];
                    endcase
                end
            end
        end
    end

    always@(negedge BG) begin
        mem_count<=2'b00;
    end



endmodule