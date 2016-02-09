module rle (
	clk, 		
	nreset, 	
	start,
	message_addr,	
	message_size, 	
	rle_addr, 	
	rle_size, 	
	done, 		
	port_A_clk,
        port_A_data_in,
        port_A_data_out,
        port_A_addr,
        port_A_we
	);

input	clk;
input	nreset;
// Initializes the RLE module

input	start;
// Tells RLE to start compressing the given frame

input 	[31:0] message_addr;
// Starting address of the plaintext frame
// i.e., specifies from where RLE must read the plaintext frame

input	[31:0] message_size;
// Length of the plain text in bytes

input	[31:0] rle_addr;
// Starting address of the ciphertext frame
// i.e., specifies where RLE must write the ciphertext frame

input   [31:0] port_A_data_out;
// read data from the dpsram (plaintext)

output  [31:0] port_A_data_in;
// write data to the dpsram (ciphertext)

output  [15:0] port_A_addr;
// address of dpsram being read/written

output  port_A_clk;
// clock to dpsram (drive this with the input clk)

output  port_A_we;
// read/write selector for dpsram

output	[31:0] rle_size;
// Length of the compressed text in bytes

output	done; // done is a signal to indicate that encryption of the frame is complete



// State Machine  
parameter IDLE = 2'b00, CALCULATE = 2'b01, PRECALC = 2'b10, FINISH = 2'b11;

reg [7:0] byte_read;		// Tracks the bytes reading in
reg [7:0] similar_byte_count;  	// Counts the number of same bytes read in
reg [1:0] STATE;		// Tracks the state we are in
reg [31:0] write_address_var;  	// Register to store write adress
reg [31:0] read_address_var;	// Register to store read address
reg [31:0] write_buff, newData; // Registers to store what needs to be written and read in
reg [7:0] rle_counter;
reg [7:0] byte_written;
reg [1:0] byte_tracker;
reg lsb_half;			// Write to the first half of the write buffer
reg write, read;		// Flags to keep track if we should read or write now
reg doneFlag;

reg [2:0] shift_count;		// Counter to keep track of how many bits have been shifted

wire [31:0] read_count;		// Wire that holds the updated values of the new read address 
wire [31:0] write_count;	// Wire that holds the updated values of the new write address
wire [7:0] update_rle_counter;
wire [2:0] update_shift_count;
wire [7:0] update_similar_byte_count;
wire [7:0] update_byte_written;
wire [1:0] update_byte_tracker;
wire shift_count_compare;
wire similar_byte_compare;
wire byte_tracker_compare;
wire reach_msg_size;

assign read_count = read_address_var + 4;
assign write_count = write_address_var + 4;
assign update_rle_counter = rle_counter + 1;
assign update_shift_count = shift_count + 1;
assign update_similar_byte_count = similar_byte_count + 1;
assign update_byte_written = byte_written + 2;
assign update_byte_tracker = byte_tracker + 1;

assign shift_count_compare = (shift_count == 4);
assign similar_byte_compare = (similar_byte_count == 0);
assign byte_tracker_compare = (byte_tracker == 2);
assign reach_msg_size = (rle_counter == message_size);

// Need to assign module outputs. They should be wires.
assign port_A_clk = clk;	//Clarified in the Piazza post
assign port_A_addr = (write) ? write_address_var : read_address_var;
assign port_A_we = write;
assign port_A_data_in = write_buff;


assign rle_size = byte_written;
assign done = (doneFlag && STATE == IDLE);

always @ (posedge clk or negedge nreset)
begin
	if(!nreset)
	begin
		STATE <= IDLE;
		byte_read <= 8'b0;
		shift_count <= 3'b0;
		similar_byte_count <= 8'b0;
		write <= 1'b0;
		write_address_var <= 32'b0;
		read_address_var <= 32'b0;
		byte_written <= 8'b0;
		rle_counter <= 8'b0;
		write_buff <= 32'b0;
		lsb_half <= 1'b1;
		read <= 1'b0;
		doneFlag <= 1'b0;
		byte_tracker <= 2'b0;
	end
	
	else
		case(STATE)
			IDLE:
				if(start)
				begin
					write <= 1'b0;
					read_address_var <= message_addr;
					write_address_var <= rle_addr;
					shift_count <= 3'b0;
					byte_written <= 8'b0;
					rle_counter <= 8'b0;
					byte_read <= 8'b0;
					similar_byte_count <= 8'b0;
					write_buff <= 32'b0;
					lsb_half <= 1'b1;
					read <= 1'b0;
					doneFlag <= 1'b0;
					byte_tracker <= 2'b0;
					STATE <= PRECALC;
				end

			// Stage to update the read address after  writing
			PRECALC: 	begin
				 	read_address_var <= read_count;
					read <= 1'b1;
					STATE <= CALCULATE;
					end

			CALCULATE:	
					if(read)
					begin
						read <= 0;
						write <= 1'b0;
						newData <= port_A_data_out;
						STATE <= CALCULATE;
					end
					else 
					begin
						// After we shift four times, we want to read next line
						if(shift_count_compare)
						begin
							shift_count <= 0;
							STATE <= PRECALC;
						end
						else
						begin						
							read <= 1'b0;
							STATE <= CALCULATE;
						end
				
						// If we aren't writing, shift read bits
						if(!write && shift_count != 4)
						begin
							if(similar_byte_compare || byte_read == newData[7:0])
							begin
								byte_read <= newData[7:0]; 
								newData <= newData >> 8;
								rle_counter <= update_rle_counter;
								shift_count <= update_shift_count;
								similar_byte_count <= update_similar_byte_count;
							end

							else
							begin
								write <= 1'b1;
								read <= 1'b0;

							end	
						end // end of if(!write) statment
						
						else if(write)
						begin
							if(byte_tracker_compare)
							begin
								write <= 1'b0;
								byte_tracker <= 0;
								lsb_half <= 1'b1;
								write_address_var <= write_count;
							end
							else begin
								if(lsb_half)
								begin
									write_buff [7:0] <= similar_byte_count;
									write_buff [15:8] <= byte_read;
									//write <= 1'b0;
									//byte_written <= update_byte_written;
									//byte_tracker <= update_byte_tracker;
									lsb_half <= 1'b0;
								end

								else
								begin
									write_buff [23:16] <= similar_byte_count;
									write_buff [31:24] <= byte_read;
									//byte_written <= update_byte_written;
									//byte_tracker <= update_byte_tracker;
									//write <= 1'b0;
									lsb_half <= 1'b1;
								end

								byte_written <= update_byte_written;
								byte_tracker <= update_byte_tracker;
								write <= 1'b0;

								if(reach_msg_size)
								begin
									STATE <= FINISH;
									write <= 1'b1;	
									if(lsb_half)
									begin
										$display ("Hi");
										write_buff [7:0] <= similar_byte_count;
										write_buff [15:8] <= byte_read;
										write_buff [31:16] <= 16'd0;
									end

									else
									begin
										$display ("wWrld");
										write_buff [23:16] <= similar_byte_count;
										write_buff [31:24] <= byte_read;
									end
								end
								else
								begin
									similar_byte_count <= 8'b0;
								end
							end

						end
					end // End of else after if(!write)
			FINISH: begin			
					write_address_var <= write_count;	
					doneFlag <= 1'b1;
					write <= 1'b0;
					STATE <= IDLE;
					
				end
		endcase
	
end

endmodule
