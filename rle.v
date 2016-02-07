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
parameter IDLE = 3'b000, CALCULATE = 3'b001, PRECALC = 3'b010;

reg [7:0] byte;			// Tracks the bytes reading in
reg [7:0] similar_byte_count;  	// Counts the number of same bytes read in
reg [2:0] STATE;		// Tracks the state we are in
reg [31:0] write_address_var;  	// Register to store write adress
reg [31:0] read_address_var;	// Register to store read address
reg [31:0] write_buff, newData; // Registers to store what needs to be written and read in
reg [31:0] rle_counter;
reg [31:0] byte_written;
reg lsb_half;			// Write to the first half of the write buffer
reg write, read;		// Flags to keep track if we should read or write now
reg doneFlag;

integer shift_count;		// Counter to keep track of how many bits have been shifted

wire [31:0] read_count;		// Wire that holds the updated values of the new read address 
wire [31:0] write_count;	// Wire that holds the updated values of the new write address

assign read_count = read_address_var + 4;
assign write_count = write_address_var + 4;

// Need to assign module outputs. They should be wires.
assign port_A_clk = clk;	//Clarified in the Piazza post
assign port_A_addr = (write) ? write_address_var : read_address_var;
assign port_A_we = write;
assign port_A_data_in = write_buff;

// Do later
assign rle_size = byte_written;
assign done = doneFlag;

always @ (posedge clk or negedge nreset)
begin
	if(!nreset)
	begin
		STATE <= IDLE;
		byte <= 8'b0;
		shift_count <= 0;
		similar_byte_count <= 8'b0;
		write <= 1'b0;
		write_address_var <= 32'b0;
		read_address_var <= 32'b0;
		byte_written <= 32'b0;
		rle_counter <= 32'b0;
		write_buff <= 32'b0;
		lsb_half <= 1'b1;
		read <= 1'b0;
		doneFlag <= 1'b0;
	end
	
	else
		case(STATE)
			IDLE:
				if(start)
				begin
					write <= 1'b0;
					read_address_var <= message_addr;
					write_address_var <= rle_addr;
					shift_count <= 0;
					byte_written <= 32'b0;
					rle_counter <= 32'b0;
					byte <= 8'b0;
					similar_byte_count <= 8'b0;
					write_buff <= 32'b0;
					lsb_half <= 1'b1;
					read <= 1'b0;
					doneFlag <= 1'b0;
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
						newData <= port_A_data_out;
					end
					else
					begin
						// After we shift four times, we want to read next line
						if(shift_count == 4)
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
							if(similar_byte_count == 0)
							begin
								byte <= newData[7:0]; 
								$display ("Entered ELSE IF ONE");
								$display ("newData: %h", newData);
								$display ("byte: %h", byte);
								newData <= newData >> 8;
								rle_counter <= rle_counter + 1;
								shift_count <= shift_count + 1;
								similar_byte_count <= similar_byte_count + 1;
							end

							else if(byte == newData[7:0])
							begin
								$display ("Entered ELSE IF TWO");
								$display ("newData: %h", newData);
								$display ("byte: %h", byte);
								newData <= newData >> 8;
								rle_counter <= rle_counter + 1;
								shift_count <= shift_count + 1;
								similar_byte_count <= similar_byte_count + 1;
							end

							else
							begin
								$display ("Entered ELSE");
								write <= 1'b1;
								read <= 1'b0;
								$display ("newData: %h", newData);
								$display ("byte: %h", byte);
							end	
						end // end of if(!write) statment
							
						else if(write)
						begin
							if(lsb_half)
							begin
								write_buff [7:0] <= similar_byte_count;
								write_buff [15:8] <= byte;
								write <= 1'b0;
								byte_written <= byte_written + 2;
								lsb_half <= 1'b0;
							end

							else
							begin
								write_buff [23:16] <= similar_byte_count;
								write_buff [31:24] <= byte;
								byte_written <= byte_written + 2;
								write <= 1'b0;
								lsb_half <= 1'b1;
							end
							similar_byte_count <= 8'b0;
							write_address_var <= write_count;
							if(rle_counter == message_size)
							begin
								doneFlag <= 1'b1;
								write <= 1'b0;	
								STATE <= IDLE;
							end
							$display("In writing stage");
						end
					end // End of else after if(!write)
		endcase
	
end

endmodule
