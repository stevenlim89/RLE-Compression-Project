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




assign port_A_clk = clk;	//Clarified in the Piazza post


reg done;
reg port_A_we;
reg [15:0] port_A_addr;
reg [31:0] port_A_data_in;
reg [31:0] rle_size;


reg [7:0] byte;			//Tracks the bytes reading in
wire [31:0] data_in;	//Copies the data from "port_A_data_out"
reg [2:0] STATE;		//Tracks the state we are in
//reg [31:0] write_address;	//Copies "rle_adder" write address
reg [31:0] write_address_var;
//reg [31:0] read_address;	//Copies "message_addr" read address
reg [31:0] read_address_var;
reg [31:0] byte_count = 32'd0;		//Counts the number of same bytes read in
reg lsb_half = 1'b1;
reg tempReg = 1'b1;
reg [2:0] shift_count = 3'd0;

wire [31:0] rd_addr;

reg [31:0] newData;


assign data_in = port_A_data_out;
//assign rd_addr = read_address_var + 4;

//assign port_A_we = 

parameter IDLE = 3'b000; //READ = 3'b001, WRITE = 3'b010, CALCULATE = 3'b011;	//States
parameter CALCULATE = 3'b001, FINISH = 3'b010;
parameter PRECALC = 3'b100;


always @ (posedge clk or negedge nreset)
begin
	if(!nreset)
	begin
		STATE <= IDLE;
		byte <= 8'd0;
		//newData <= 32'd0;
		done <= 1'b0;
	end
	
	else
		case(STATE)
			IDLE:
					if(start)
						begin
						port_A_we <= 1'b0;
						read_address_var <= message_addr;
						port_A_addr <= message_addr;
						write_address_var <= rle_addr;
						newData <= data_in;
						STATE <= PRECALC;
						end
			PRECALC: begin
				 if(newData != data_in)
					begin
					newData <= data_in;
					$display ("This is newData: %h", newData);
					STATE <= PRECALC;
					end
				 else 
				 begin
				 	STATE <= CALCULATE;
				 end
				 end

			CALCULATE:	begin
						
						if(!port_A_we)
						begin
						
						$display ("INSIDE CALCULATE NOW");
						$display ("data_in: %h", data_in);
						//data_in <= port_A_data_out;
							if(shift_count == 4)
							begin	
							$display ("Entered IF");
							//read_address_var <= rd_addr;
							port_A_addr <= read_address_var + 4;
							shift_count <= 0;
							port_A_we <= 1'b1;
							end

							else if(byte_count == 0)
							begin
							byte <= newData[7:0]; 		//Saves the initial data
							$display ("Entered ELSE IF ONE");
							//data_in <= data_in >> 8;
							$display ("newData: %h", newData);
							$display ("byte: %h", byte);
							newData <= newData >> 8;
							shift_count <= shift_count + 1;
							byte_count <= byte_count + 1;
							end


							else if(byte == newData[7:0])
							begin
							$display ("Entered ELSE IF TWO");
							//data_in <= data_in >> 8;
							newData <= newData >> 8;
							shift_count <= shift_count + 1;
							byte_count <= byte_count + 1;
							end

							else
							begin
							$display ("Entered ELSE");
							port_A_we <= 1'b1;
							//byte <= newData[7:0];
							$display ("newData: %h", newData);
							$display ("byte: %h", byte);
							end
$display ("\n");
							
						end
						
						

						else
						begin
							if(lsb_half)
							begin
							port_A_addr <= write_address_var;
							port_A_data_in [7:0] <= byte_count;
							port_A_data_in [15:8] <= byte;
							port_A_we <= 1'b0;
							lsb_half <= 1'b0;
							end

							else
							begin
							port_A_addr <= write_address_var;
							port_A_data_in [23:16] <= byte_count;
							port_A_data_in [31:24] <= byte;
							port_A_we <= 1'b0;
							lsb_half <= 1'b1;
							write_address_var <= write_address_var + 4;
							end

							byte_count <= 0;
							//port_A_addr <= read_address_var;
						end
						STATE <= CALCULATE;
					end
							
			/*TEMP:	begin
				port_A_addr <= read_address_var;
				STATE <= CALCULATE;
				end*/
			FINISH: STATE <= IDLE;
		
		endcase
	
end

endmodule
