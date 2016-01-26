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

reg [31:0] port_A_data_in;
reg [31:0] port_A_addr;
reg [31:0] rle_size;

reg [7:0] two_char_value;		//Each character is 8 bits = 1 byte = 2 hexadecimal
reg [3:0] char_value = 4'd0;
reg [31:0] num_of_chars; 	//Counter for number character being counted
reg [31:0] addr_tracker;	//Tracks the address to be read from


always @ (*)		//Work on the computation outside of the clock cycle
begin
	//Start at the starting address of the file: "message_addr"
	assign addr_tracker = message_addr;
	
	//Specify the address of dpsram being read from to "port_A_addr"
	assign port_A_addr = addr_tracker;
	
	//Signify we are reading the value with output "port_A_we == 0"
	assign port_A_we = 1;
	//Save the char_value of the first character in hexidecimal, "port_A_data_out"
		//"port_A_data_out" is 32 bits long, have to read in each 4 bits at a time
		//since each data in the text file is a hexidecimal representation
	for(i = 0; i < 32; i = i + 4)
	begin
		if(char_value == port_A_data_out[i+4:i])
		begin
			//Count and compare the first character with the second character
			//Loop through this and count the number of times they are the same
			char_value <= port_A_data_out[i+4:i];
			num_of_chars = num_of_chars + 1;
		end
		
		//Once the next value is different, output the num_of_chars and the char_value
		//into the starting address of the writing frame "rle_addr" (remember little endian)
		//When you output, output the results into "port_A_data_in"
			//and specify which address it is being written to in "port_A_addr"
		//When outputting, output "post_A_we == 1"
		else
		begin
			
		end
	end
	
	
	
	//Once the next value is different, output the num_of_chars and the char_value into the
	//starting address of the writing frame "rle_addr" (remember little endian)
		//When you output, output the results into "port_A_data_in"
			//and specify which address it is being written to in "port_A_addr"
		//When outputting, output "post_A_we == 1"
	
	//Save the next char_value and start the iteration again
	
	//Check that the length of the "message_size" is on par with
	//our compressed size "rle_size"
		//If so, output "rle_size" and signal "done == 1"
		//Reset all counting factors to be zero
end

always @ (posedge clk)
begin
	if(!nreset)
	begin
		//Want to reset all counting factors to "0"
		char_value <= 0;
		num_of_chars <= 0;
	end
	
	else if (start)
	begin
		//want to do the computation
	end

end



//wait until start == 1 before you start the computation