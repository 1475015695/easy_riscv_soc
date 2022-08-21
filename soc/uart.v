module uart (
    input clk,
    input reset,
    input [31:0] uart_write_address,
    input [31:0] uart_write_data,
    input uart_write_enable,
    input [31:0] uart_read_address,
    output reg [31:0] uart_read_data,
    output reg uart_tx_done,//keep 1 clock when tx done
    output reg uart_state,//0 idle 1 busy
    output reg uart_tx,
    (* mark_debug = "true" *)input uart_rx,
    output reg uart_rx_int_req,
    (* mark_debug = "true" *)output reg start_program,
    (* mark_debug = "true" *)output reg [31:0] flash_write_address,
    (* mark_debug = "true" *)output reg [31:0] flash_write_data,
    (* mark_debug = "true" *)output reg flash_write_enable,
    (* mark_debug = "true" *)output reg program_done
);
    localparam uart_csr_reg_address=32'hb000_0000,uart_buadrate_address=32'hb000_0001,uart_tx_data_address=32'hb000_0002,uart_rx_data_address=32'hb000_0003;
    localparam buadrate_9600=3'b000,buadrate_19200=3'b001,buadrate_38400=3'b010,buadrate_57600=3'b011,buadrate_115200=3'b100;
    localparam tx_buadrate_9600_count=16'd5207,tx_buadrate_19200_count=16'd2603,tx_buadrate_38400_count=16'd1301,tx_buadrate_57600_count=16'd867,tx_buadrate_115200_count=16'd433;//50M
    localparam rx_buadrate_9600_count=16'd5207,rx_buadrate_19200_count=16'd2603,rx_buadrate_38400_count=16'd1301,rx_buadrate_57600_count=16'd867,rx_buadrate_115200_count=16'd433;//50M
    localparam rx_buadrate_9600_d16_count=16'd324,rx_buadrate_19200_d16_count=16'd162,rx_buadrate_38400_d16_count=16'd80,rx_buadrate_57600_d16_count=16'd53,rx_buadrate_115200_d16_count=16'd28;//50M
    reg [31:0] uart_csr_reg=32'b0;//[0] tx_enable,[1] rx_enable,[2]tx_ing,[3]rx_ing,[4] rx_interrupt_enable
    reg [31:0] uart_buadrate_reg=32'hffff_ffff;
    reg [31:0] uart_tx_data=32'b0;
    reg [15:0] uart_tx_buadrate_counter=16'b0;
    // reg [15:0] uart_tx_buadrate_count=tx_buadrate_115200_count;
    wire [15:0] uart_tx_buadrate_count=uart_buadrate_reg[15:0];
    reg [15:0] uart_rx_buadrate_counter=16'b0;
    // reg [15:0] uart_rx_buadrate_count=rx_buadrate_115200_count;
    // reg [8:0] uart_rx_buadrate_d16_count=rx_buadrate_115200_d16_count;
    wire [8:0] uart_rx_buadrate_d16_count=uart_buadrate_reg[12:4];//16分频，右移4位
    reg [8:0] uart_rx_buadrate_d16_counter=9'b0;
    reg [3:0] uart_tx_phase;
    reg tx_send_frame;
    reg rx_save_frame;
    reg rx_byte_saved;

    
    reg uart_rx_buf1=1'b1,uart_rx_buf2=1'b1,uart_rx_state1=1'b1,uart_rx_state2=1'b1;
    wire rx_negedge=uart_rx_buf2&(!uart_rx_buf1);
    reg [3:0] rx_d16_phase=4'd0,rx_phase=4'd0;
    reg [7:0] rx_sample_cnt=8'b0;
    reg [1:0] rx_sample_startbit=2'b0;
    reg [1:0] rx_sample0=2'b0;
    reg [1:0] rx_sample1=2'b0;
    reg [1:0] rx_sample2=2'b0;
    reg [1:0] rx_sample3=2'b0;
    reg [1:0] rx_sample4=2'b0;
    reg [1:0] rx_sample5=2'b0;
    reg [1:0] rx_sample6=2'b0;
    reg [1:0] rx_sample7=2'b0;
    reg [1:0] rx_sample_stopbit=2'b0;
    (* mark_debug = "true" *)reg [7:0] rx_data=8'b0;
    reg rx_start_bit_valid=1'b0;
    reg rx_data_vaild=1'b0;
    
    reg rx_byte_saved_buf1=1'b0,rx_byte_saved_buf2=1'b0,rx_byte_saved_buf3=1'b0;
    // reg program_done=1'b0,start_program=1'b0;
    localparam wait_5a=4'd0,wait_a5=4'd1,wait_0f=4'd2,wait_f0=4'd3,is_start_frame=4'd4,wait_finish_f0=4'd5,wait_finish_0f=4'd6,wait_finish_a5=4'd7,wait_finish_5a=4'd8,is_end_frame=4'd9;
    reg [3:0] present=wait_5a,next=wait_5a;
    reg [2:0] instruction_byte_count=3'b0;
    reg [31:0] pre_instruction=32'b0;
    reg [31:0] flash_write_address_count=32'b0;
    // reg [31:0] flash_write_address=32'b0,flash_write_data=32'b0;
    // reg flash_write_enable;
    always @(posedge clk ) begin
        if(reset)begin
            uart_csr_reg<=32'b0;
            uart_buadrate_reg<=32'hffff_ffff;
        end
        else if(uart_write_enable)begin
            case(uart_write_address)
                uart_csr_reg_address:begin
                    uart_csr_reg<=uart_write_data;
                end
                uart_buadrate_address:begin
                    uart_buadrate_reg<=uart_write_data;
                end
                uart_tx_data_address:begin
                    uart_tx_data<=uart_write_data;
                end
            endcase
        end
        else if(start_program)begin//program
            uart_tx_data<=32'h1;
        end
        else if(program_done)begin//program
            uart_tx_data<=32'h2;
        end

    end
    always @(posedge clk ) begin
        if(reset)begin
            tx_send_frame<=1'b0;
        end
        else if(uart_write_enable&&(uart_write_address==uart_tx_data_address))begin
            tx_send_frame<=1'b1;
        end
        else if(start_program|program_done)begin//program
            tx_send_frame<=1'b1;
        end
        else if(uart_tx_phase==4'd10&&(uart_tx_buadrate_counter==uart_tx_buadrate_count))begin
            tx_send_frame<=1'b0;
        end
    end
    always @(posedge clk ) begin
        if(reset)begin
            uart_read_data<=32'b0;
        end
        else begin
            case(uart_read_address)
                uart_csr_reg_address:begin
                    uart_read_data<={uart_csr_reg[31:5],rx_save_frame,tx_send_frame,uart_csr_reg[1:0]};
                end
                uart_buadrate_address:begin
                    uart_read_data<=uart_buadrate_reg;
                end
                uart_tx_data_address:begin
                    uart_read_data<=uart_tx_data;
                end
                uart_rx_data_address:begin
                   uart_read_data<=(rx_data_vaild)?{24'b0,rx_data}:32'b0; 
                end
            endcase
        end
    end

    // always @(posedge clk ) begin
    //     if(reset)begin
    //         uart_tx_buadrate_count<=tx_buadrate_115200_count;
    //     end
    //     else begin
    //         case(uart_csr_reg[2:0])
    //             buadrate_9600:begin
    //                 uart_tx_buadrate_count<=tx_buadrate_9600_count;
    //             end
    //             buadrate_19200:begin
    //                 uart_tx_buadrate_count<=tx_buadrate_19200_count;
    //             end
    //             buadrate_38400:begin
    //                 uart_tx_buadrate_count<=tx_buadrate_38400_count;
    //             end
    //             buadrate_57600:begin
    //                 uart_tx_buadrate_count<=tx_buadrate_57600_count;
    //             end
    //             buadrate_115200:begin
    //                 uart_tx_buadrate_count<=tx_buadrate_115200_count;
    //             end
    //             default:begin
    //                 uart_tx_buadrate_count<=tx_buadrate_115200_count;
    //             end
    //         endcase
    //     end
    // end

    always @(posedge clk ) begin
        if(reset)begin
            uart_tx_buadrate_counter<=16'b0;
        end
        else if(uart_tx_buadrate_counter==uart_tx_buadrate_count)begin
                uart_tx_buadrate_counter<=16'b0;
        end
        else if(uart_csr_reg[0]&tx_send_frame)begin
            uart_tx_buadrate_counter<=uart_tx_buadrate_counter+1'b1;
        end
        else begin
            uart_tx_buadrate_counter<=uart_tx_buadrate_counter;
        end
    end
    
    always @(posedge clk ) begin
        if(reset)begin
            uart_tx_phase<=4'b0;
        end
        // else if(uart_write_enable&&(uart_write_address==uart_tx_data_address))begin//
        //     uart_tx_phase<=4'b0;
        // end
        else if((uart_tx_buadrate_count!=16'b0)&(uart_tx_buadrate_counter==uart_tx_buadrate_count))begin
            if(uart_tx_phase==4'd10)begin
                uart_tx_phase<=4'b0;
            end
            else begin
                uart_tx_phase<=uart_tx_phase+1'b1;
            end
        end
        else begin
            uart_tx_phase<=uart_tx_phase;
        end
    end

    always @(posedge clk ) begin
        if(reset)begin
            uart_tx<=1'b1;
        end
        else if(uart_csr_reg[0])begin
            case(uart_tx_phase)
                4'd0:begin
                    uart_tx<=1'b1;
                end
                4'd1:begin
                    uart_tx<=1'b0;//start bit
                end
                4'd2:begin
                    uart_tx<=uart_tx_data[0];//
                end
                4'd3:begin
                    uart_tx<=uart_tx_data[1];//
                end
                4'd4:begin
                    uart_tx<=uart_tx_data[2];
                end
                4'd5:begin
                    uart_tx<=uart_tx_data[3];
                end
                4'd6:begin
                    uart_tx<=uart_tx_data[4];
                end
                4'd7:begin
                    uart_tx<=uart_tx_data[5];
                end
                4'd8:begin
                    uart_tx<=uart_tx_data[6];
                end
                4'd9:begin
                    uart_tx<=uart_tx_data[7];
                end
                4'd10:begin
                    uart_tx<=1'b1;//stop bit
                end
            endcase
        end
    end
//-------------------------------------------------------------------rx
    
    always @(posedge clk ) begin
        if(reset)begin
            uart_rx_buf1<=1'b1;
            uart_rx_buf2<=1'b1;
        end
        else begin
            uart_rx_buf1<=uart_rx;
            uart_rx_buf2<=uart_rx_buf1;
        end
    end
    always @(posedge clk ) begin
        if(reset)begin
            uart_rx_state1<=1'b1;
            uart_rx_state2<=1'b1;
        end
        else begin
            uart_rx_state1<=uart_rx_buf2;
            uart_rx_state2<=uart_rx_state1;
        end
    end

    // always @(posedge clk ) begin
    //     if(reset)begin
    //         uart_rx_buadrate_count<=rx_buadrate_115200_count;
    //     end
    //     else begin
    //         case(uart_csr_reg[2:0])
    //             buadrate_9600:begin
    //                 uart_rx_buadrate_count<=rx_buadrate_9600_count;
    //             end
    //             buadrate_19200:begin
    //                 uart_rx_buadrate_count<=rx_buadrate_19200_count;
    //             end
    //             buadrate_38400:begin
    //                 uart_rx_buadrate_count<=rx_buadrate_38400_count;
    //             end
    //             buadrate_57600:begin
    //                 uart_rx_buadrate_count<=rx_buadrate_57600_count;
    //             end
    //             buadrate_115200:begin
    //                 uart_rx_buadrate_count<=rx_buadrate_115200_count;
    //             end
    //             default:begin
    //                 uart_rx_buadrate_count<=rx_buadrate_115200_count;
    //             end
    //         endcase
    //     end
    // end
    // always @(posedge clk ) begin
    //     if(reset)begin
    //         uart_rx_buadrate_d16_count<=rx_buadrate_115200_d16_count;
    //     end
    //     else begin
    //         case(uart_csr_reg[2:0])
    //             buadrate_9600:begin
    //                 uart_rx_buadrate_d16_count<=rx_buadrate_9600_d16_count;
    //             end
    //             buadrate_19200:begin
    //                 uart_rx_buadrate_d16_count<=rx_buadrate_19200_d16_count;
    //             end
    //             buadrate_38400:begin
    //                 uart_rx_buadrate_d16_count<=rx_buadrate_38400_d16_count;
    //             end
    //             buadrate_57600:begin
    //                 uart_rx_buadrate_d16_count<=rx_buadrate_57600_d16_count;
    //             end
    //             buadrate_115200:begin
    //                 uart_rx_buadrate_d16_count<=rx_buadrate_115200_d16_count;
    //             end
    //             default:begin
    //                 uart_rx_buadrate_d16_count<=rx_buadrate_115200_d16_count;
    //             end
    //         endcase
    //     end
    // end
    always @(posedge clk ) begin
        if(reset)begin
            rx_save_frame<=1'b0;
        end
        else if(rx_negedge)begin
            rx_save_frame<=1'b1;
        end
        else if((uart_rx_buadrate_d16_counter==uart_rx_buadrate_d16_count)&(uart_rx_buadrate_d16_counter!=0))begin
            if(rx_sample_cnt==8'd14&(!rx_start_bit_valid))begin
                rx_save_frame<=1'b0; 
            end
            else if(rx_sample_cnt==8'd159)begin
                rx_save_frame<=1'b0; 
            end
        end
    end
    always @(posedge clk ) begin
        if(reset)begin
            uart_rx_buadrate_d16_counter<=9'b0;
        end
        // else if(uart_csr_reg[4]&rx_save_frame)begin//program 需要，一直接收使能
        else if(rx_save_frame)begin
            if(uart_rx_buadrate_d16_counter==uart_rx_buadrate_d16_count)begin
                uart_rx_buadrate_d16_counter<=9'b0;
            end
            else begin
                uart_rx_buadrate_d16_counter<=uart_rx_buadrate_d16_counter+1'b1;
            end
        end
    end
    always @(posedge clk ) begin
        if(reset)begin
            rx_sample_cnt<=8'b0;
        end
        else if((uart_rx_buadrate_d16_counter==uart_rx_buadrate_d16_count)&(uart_rx_buadrate_d16_count!=0))begin
            if(rx_sample_cnt==8'd14&(!rx_start_bit_valid))begin
                rx_sample_cnt<=8'b0;
            end
            else if((rx_sample_cnt==8'd159))begin
                rx_sample_cnt<=8'b0;
            end
            else begin
                rx_sample_cnt<=rx_sample_cnt+1'b1; 
            end
        end
    end

    // always @(posedge clk ) begin
    //     if(reset)begin
    //         uart_rx_buadrate_counter<=16'b0;
    //     end
    //     else if(uart_csr_reg[4]&rx_save_frame)begin
    //         if(uart_rx_buadrate_counter==uart_rx_buadrate_count)begin
    //             uart_rx_buadrate_counter<=16'b0;
    //         end
    //         else begin
    //             uart_rx_buadrate_counter<=uart_rx_buadrate_counter+1'b1;
    //         end
    //     end
    // end
    // always @(posedge clk ) begin
    //     if(reset)begin
    //         rx_phase<=4'b0;
    //     end
    //     else if((uart_rx_buadrate_d16_counter==uart_rx_buadrate_d16_count)&(uart_rx_buadrate_d16_counter!=0))begin
    //         if(rx_phase==4'd9)begin
    //             rx_phase<=4'd0;
    //         end
    //         else begin
    //             case(rx_sample_cnt)
    //                 14,29,44,59,74,89,104,119,134:begin
    //                     rx_phase<=rx_phase+1'b1; 
    //                 end
    //                 149:
    //                     rx_phase<=4'b0;
    //             endcase
               
    //         end
    //     end
        
    // end

    
    always @(posedge clk ) begin
        if(reset)begin
            rx_sample_startbit=2'b0;
        end
        else if(rx_phase==4'd0&rx_save_frame)begin
            case(rx_sample_cnt)
                6,7,8:begin
                    rx_sample_startbit<=rx_sample_startbit+uart_rx_buf2;
                end
            endcase
        end
    end
    always @(posedge clk ) begin
        if(reset)begin
            rx_start_bit_valid<=1'b0;
        end
        else if(rx_sample_cnt==8'd13&(uart_rx_buadrate_d16_counter==uart_rx_buadrate_d16_count)&(uart_rx_buadrate_d16_counter!=16'b0))begin
            if(rx_sample_startbit==2'd0)begin//提前一个samplecnt判断起始帧是否有效
                rx_start_bit_valid<=1'b1;
            end
        end
        else if(rx_sample_cnt==8'd159&(uart_rx_buadrate_d16_counter==uart_rx_buadrate_d16_count)&(uart_rx_buadrate_d16_counter!=16'b0))begin
            rx_start_bit_valid<=1'b0;
        end
    end

    always @(posedge clk ) begin
        if(reset|(!rx_start_bit_valid))begin
            rx_sample_stopbit=2'b0;
            rx_sample0<=2'b0;
            rx_sample1<=2'b0;
            rx_sample2<=2'b0;
            rx_sample3<=2'b0;
            rx_sample4<=2'b0;
            rx_sample5<=2'b0;
            rx_sample6<=2'b0;
            rx_sample7<=2'b0;
        end
        else if((uart_rx_buadrate_d16_counter==uart_rx_buadrate_d16_count)&(uart_rx_buadrate_d16_count!=0))begin
            case(rx_sample_cnt)
                21,22,23:begin
                    rx_sample0<=rx_sample0+uart_rx_buf2;
                end
                37,38,39:begin
                    rx_sample1<=rx_sample1+uart_rx_buf2;
                end
                53,54,55:begin
                    rx_sample2<=rx_sample2+uart_rx_buf2;
                end
                68,69,70:begin
                    rx_sample3<=rx_sample3+uart_rx_buf2;
                end
                84,85,86:begin
                    rx_sample4<=rx_sample4+uart_rx_buf2;
                end
                99,100,101:begin
                    rx_sample5<=rx_sample5+uart_rx_buf2;
                end
                115,116,117:begin
                    rx_sample6<=rx_sample6+uart_rx_buf2;
                end
                130,131,132:begin
                    rx_sample7<=rx_sample7+uart_rx_buf2;
                end
                146,147,148:begin
                    rx_sample_stopbit<=rx_sample_stopbit+uart_rx_buf2;
                end
            endcase
            if((uart_rx_buadrate_d16_counter==uart_rx_buadrate_d16_count)&(uart_rx_buadrate_d16_counter!=0)&rx_sample_cnt==8'd159)begin
                rx_sample0<=2'b0;
                rx_sample1<=2'b0;
                rx_sample2<=2'b0;
                rx_sample3<=2'b0;
                rx_sample4<=2'b0;
                rx_sample5<=2'b0;
                rx_sample6<=2'b0;
                rx_sample7<=2'b0;
                rx_sample_stopbit<=2'b0;
            end
        end
        
    end

    always @(posedge clk ) begin
        if(reset)begin
            rx_data<=8'b0;
            rx_data_vaild<=1'b0;
        end
        else if((uart_rx_buadrate_d16_counter==uart_rx_buadrate_d16_count)&(uart_rx_buadrate_d16_counter!=0)&rx_sample_cnt==8'd159)begin
            if(rx_sample_stopbit==2'd3)begin
                rx_data[0]<=rx_sample0[1];
                rx_data[1]<=rx_sample1[1];
                rx_data[2]<=rx_sample2[1];
                rx_data[3]<=rx_sample3[1];
                rx_data[4]<=rx_sample4[1];
                rx_data[5]<=rx_sample5[1];
                rx_data[6]<=rx_sample6[1];
                rx_data[7]<=rx_sample7[1]; 
                rx_data_vaild<=1'b1;
            end
            else begin
                rx_data_vaild<=1'b0;
            end
        end
    end
//-------------------------------------------------------------------interrupt
    always @(posedge clk ) begin
        if(reset)begin
            rx_byte_saved<=1'b0;
            uart_rx_int_req<=1'b0;
        end
        else if((uart_rx_buadrate_d16_counter==uart_rx_buadrate_d16_count)&(uart_rx_buadrate_d16_counter!=0)&(rx_sample_cnt==8'd159)&(rx_sample_stopbit==2'd3))begin
            rx_byte_saved<=1'b1;
            if(uart_csr_reg[4])begin
                uart_rx_int_req<=1'b1;
            end//interrupt enable
        end
        else begin
            rx_byte_saved<=1'b0;
            uart_rx_int_req<=1'b0;
        end
        
    end


    // always @(posedge clk ) begin
    //     if(reset)begin
    //         uart_rx_int_req<=1'b0;
    //     end
    //     else if()
    // end
//-----------------------------------------------------------------------progrma
//rx byte saved：更新next
//rx_byte_saved_buf1：更新present
//rx_byte_saved_buf2：根据present当前状态做相应工作，比如把rx data写到相应指令处
//rx_byte_saved_buf3：处理present处理完后的结果，比如更新指令，写指令       

always @(posedge clk ) begin
    if(reset)begin
        rx_byte_saved_buf1<=1'b0;
        rx_byte_saved_buf2<=1'b0;
        rx_byte_saved_buf3<=1'b0;
    end
    else begin
        rx_byte_saved_buf1<=rx_byte_saved;
        rx_byte_saved_buf2<=rx_byte_saved_buf1;
        rx_byte_saved_buf3<=rx_byte_saved_buf2;
    end
end


always @(posedge clk ) begin
    if(reset)begin
        next<=wait_5a;
    end
    else if(rx_byte_saved)begin
        case(present)
            wait_5a:next<=(rx_data==8'h5a)?wait_a5:wait_5a;
            wait_a5:next<=(rx_data==8'ha5)?wait_0f:wait_5a;
            wait_0f:next<=(rx_data==8'h0f)?wait_f0:wait_5a;
            wait_f0:next<=(rx_data==8'hf0)?is_start_frame:wait_5a;

            is_start_frame:next<=wait_finish_f0;

            wait_finish_f0:next<=(rx_data==8'hf0)?wait_finish_0f:wait_finish_f0;
            wait_finish_0f:next<=(rx_data==8'h0f)?wait_finish_a5:wait_finish_f0;
            wait_finish_a5:next<=(rx_data==8'ha5)?wait_finish_5a:wait_finish_f0;
            wait_finish_5a:next<=(rx_data==8'h5a)?is_end_frame:wait_finish_f0;

            is_end_frame:next<=wait_5a;

        endcase
    end
end

always @(posedge clk ) begin
    if(reset)begin
        instruction_byte_count<=3'b0;
    end
    else if(((present==wait_finish_f0)|(present==wait_finish_0f)|(present==wait_finish_a5)|(present==wait_finish_5a))&(rx_byte_saved_buf2))begin
        if(instruction_byte_count==3'd3)begin
            instruction_byte_count<=3'd0;
        end
        else begin
            instruction_byte_count<=instruction_byte_count+1'b1;
        end
    end
    else if(present==is_end_frame)begin
        instruction_byte_count<=3'd0;
    end
end

always @(posedge clk ) begin
    if(reset)begin
        present<=wait_5a;
    end
    else begin
        present<=next;
        if(((present>4'd4)&(present!=4'd9))&(rx_byte_saved_buf2))begin
            case(instruction_byte_count)
                3'd3:pre_instruction[7:0]<=rx_data;
                3'd2:pre_instruction[15:8]<=rx_data;
                3'd1:pre_instruction[23:16]<=rx_data;
                3'd0:pre_instruction[31:24]<=rx_data;
            endcase
        end
    end
end
always @(posedge clk ) begin
    if(reset)begin
        start_program<=1'b0;
    end
    else if((present==is_start_frame)&(rx_byte_saved_buf2))begin
        start_program<=1'b1;
    end
    else begin
        start_program<=1'b0;
    end
end
always @(posedge clk ) begin
    if(reset)begin
        program_done<=1'b0;
    end
    else if((present==is_end_frame)&(rx_byte_saved_buf2))begin
        program_done<=1'b1;
    end
    else begin
        program_done<=1'b0;
    end
end

always @(posedge clk ) begin
    if(reset)begin
        flash_write_address_count<=32'b0;
    end
    else if(flash_write_enable)begin
        flash_write_address_count<=flash_write_address_count+1'b1;
    end
    else if(present==is_end_frame)begin
        flash_write_address_count<=32'b0;
    end
end

always @(posedge clk ) begin
    if(reset)begin
        flash_write_address<=32'b0;
        flash_write_data<=32'b0;
        flash_write_enable<=1'b0;
    end
    else if((instruction_byte_count==3'd0)&(rx_byte_saved_buf3)&(present>4'd4)&(present!=4'd9))begin
        flash_write_address<=flash_write_address_count;
        flash_write_data<=pre_instruction;
        flash_write_enable<=1'b1;
    end
    else begin
        flash_write_enable<=1'b0;
    end
end
endmodule //uart