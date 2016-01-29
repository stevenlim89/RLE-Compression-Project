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


reg [31:0] byte;		//Tracks the bytes reading in
reg [31:0] data_in;	//Copies the data from "port_A_data_out"
reg [2:0] STATE;		//Tracks the state we are in
reg [31:0] write_address;	//Copies "rle_adder" write address
reg [31:0] write_address_var;
reg [31:0] read_address;	//Copies "message_addr" read address
reg [31:0] read_address_var;

parameter IDLE = 3'b000; //READ = 3'b001, WRITE = 3'b010, CALCULATE = 3'b011;	//States
parameter CALCULATE = 3'b001, FINISH = 3'b010;

//assign read_address = message_addr;
//assign write_address = rle_adder;

always @ (posedge clk or negedge nreset)
begin
	if(!nreset)
	begin
		STATE <= IDLE;
		byte <= 32'd0;
		data_in <= 32'd0;
		done <= 1'b0;
	end
	
	else
		case(STATE)
			IDLE:
					if(start)
						begin
						port_A_we <= 1'b0;
						data_in <= port_A_data_out;
						$display ("port_A_data_out: %h", port_A_data_out);
						read_address_var <= message_addr;
						$display ("read_address_var: %h", read_address_var);
						write_address_var <= rle_addr;
						STATE <= CALCULATE;
						//STATE <= READ;
						end
			
			CALCULATE:	begin
						$display ("INSIDE CALCULATE NOW");
						$display ("read_address_var: %h", read_address_var);
						$display ("port_A_data_out: %h", port_A_data_out);
						byte <= port_A_data_out;
						$display ("byte: %h", byte);
						port_A_we <= 1'b1;
						//STATE <= WRITE;	//When finished calculating, write the data
						
						port_A_addr <= read_address_var;
						read_address_var <= read_address_var + 4;
						STATE <= CALCULATE;
							
							
						//STATE <= FINISH;
						end
							
			FINISH: STATE <= IDLE;
		
		endcase
	
end

endmodule
