//=======================================================
//  This code is generated by Terasic System Builder
//=======================================================

module DE0_NANO(

	//////////// CLOCK //////////
	CLOCK_50,

	//////////// LED //////////
	LED,

	//////////// KEY //////////
	KEY,

	//////////// SW //////////
	SW,

	//////////// SDRAM //////////
	DRAM_ADDR,
	DRAM_BA,
	DRAM_CAS_N,
	DRAM_CKE,
	DRAM_CLK,
	DRAM_CS_N,
	DRAM_DQ,
	DRAM_DQM,
	DRAM_RAS_N,
	DRAM_WE_N,

	//////////// EPCS //////////
	EPCS_ASDO,
	EPCS_DATA0,
	EPCS_DCLK,
	EPCS_NCSO,

	//////////// Accelerometer and EEPROM //////////
	G_SENSOR_CS_N,
	G_SENSOR_INT,
	I2C_SCLK,
	I2C_SDAT,

	//////////// ADC //////////
	ADC_CS_N,
	ADC_SADDR,
	ADC_SCLK,
	ADC_SDAT,

	//////////// 2x13 GPIO Header //////////
	GPIO_2,
	GPIO_2_IN,

	//////////// GPIO_0, GPIO_0 connect to GPIO Default //////////
	GPIO_0_PI,
	GPIO_0_PI_IN,

	//////////// GPIO_1, GPIO_1 connect to GPIO Default //////////
	GPIO_1,
	GPIO_1_IN 
);

//=======================================================
//  PARAMETER declarations
//=======================================================


//=======================================================
//  PORT declarations
//=======================================================

//////////// CLOCK //////////
input 		          		CLOCK_50;

//////////// LED //////////
output		     [7:0]		LED;

//////////// KEY //////////
input 		     [1:0]		KEY;

//////////// SW //////////
input 		     [3:0]		SW;

//////////// SDRAM //////////
output		    [12:0]		DRAM_ADDR;
output		     [1:0]		DRAM_BA;
output		          		DRAM_CAS_N;
output		          		DRAM_CKE;
output		          		DRAM_CLK;
output		          		DRAM_CS_N;
inout 		    [15:0]		DRAM_DQ;
output		     [1:0]		DRAM_DQM;
output		          		DRAM_RAS_N;
output		          		DRAM_WE_N;

//////////// EPCS //////////
output		          		EPCS_ASDO;
input 		          		EPCS_DATA0;
output		          		EPCS_DCLK;
output		          		EPCS_NCSO;

//////////// Accelerometer and EEPROM //////////
output		          		G_SENSOR_CS_N;
input 		          		G_SENSOR_INT;
output		          		I2C_SCLK;
inout 		          		I2C_SDAT;

//////////// ADC //////////
output		          		ADC_CS_N;
output		          		ADC_SADDR;
output		          		ADC_SCLK;
input 		          		ADC_SDAT;

//////////// 2x13 GPIO Header //////////
inout 		    [12:0]		GPIO_2;
input 		     [2:0]		GPIO_2_IN;

//////////// GPIO_0, GPIO_0 connect to GPIO Default //////////
inout 		    [33:0]		GPIO_0_PI;
input 		     [1:0]		GPIO_0_PI_IN;

//////////// GPIO_1, GPIO_1 connect to GPIO Default //////////
inout 		    [33:0]		GPIO_1;
input 		     [1:0]		GPIO_1_IN;


	
//=======================================================
//  Link between GPIO_ 1 and the components
//=======================================================

//logic laserSignal, laserSync, laserCodeA, laserCodeB;
//logic propMLA, propMLB, propMRA, propMRB;
//logic UART_TX, UART_RX, UART_DIR;

// Assignation entre les pins du GPIO 1 et GPIO 0 pour pouvoir connecter le tout au raspberry
// Used for 1-bit data, because the SPI communication is not worth in this case
assign GPIO_0_PI[1] = GPIO_1[8]; //laserSignal 
assign GPIO_0_PI[3] = GPIO_1[7]; //laserSync

//assign GPIO_0_PI[5] = GPIO_1[4]; //laserCodeA
//assign GPIO_0_PI[7] = GPIO_1[5]; //laserCodeB


//assign propMLA     = GPIO_1[0];
//assign propMLB     = GPIO_1_IN[0];
//assign propMRA     = GPIO_1[2];
//assign propMRB     = GPIO_1[1];enc_counterA

//assign UART_TX     = GPIO_1[26];
//assign UART_RX     = GPIO_1[24];
//assign UART_DIR    = GPIO_1[22];


assign reset = GPIO_0_PI[0];


//=======================================================
//  SPI
//=======================================================

logic	spi_clk, spi_cs, spi_mosi, spi_miso;
logic MemWriteM;
logic [31:0] DataAdrM, WriteDataM, spi_data;

assign MemWriteM = 1; //This is used to always update the value from the output register.

spi_slave spi_slave_instance(
	.SPI_CLK    (spi_clk),
	.SPI_CS     (spi_cs),
	.SPI_MOSI   (spi_mosi),
	.SPI_MISO   (spi_miso),
	.Data_WE    (MemWriteM & cs_spi),
	.Data_Addr  (DataAdrM),
	.Data_Write (WriteDataM),
	.Data_Read  (spi_data),
	.Clk        (clk)
);

assign spi_clk  		= GPIO_0_PI[11];	// SCLK = pin 16 = GPIO_11
assign spi_cs   		= GPIO_0_PI[9];	// CE0  = pin 14 = GPIO_9
assign spi_mosi     	= GPIO_0_PI[15];	// MOSI = pin 20 = GPIO_15, send data from PI

assign GPIO_0_PI[13] = spi_cs ? 1'bz : spi_miso;  // MISO = pin 18 = GPIO_13, received data from PI
	
//=======================================================
//  Encoder declaration
//=======================================================

logic [31:0]	enc_counter_LEFT_WHEEL, enc_counter_RIGHT_WHEEL, enc_counter_TURRET;
logic 			reset_enc_LEFT_WHEEL, reset_enc_RIGHT_WHEEL, reset_enc_TURRET;

// LEFT motor position
quadrature_decoder encoder_decoderLEFT_WHEEL(CLOCK_50, reset_enc_LEFT_WHEEL, GPIO_1[1], GPIO_1[2], enc_counter_LEFT_WHEEL);

// RIGHT motor position
quadrature_decoder encoder_decoderRIGHT_WHEEL(CLOCK_50, reset_enc_RIGHT_WHEEL, GPIO_1[0], GPIO_1_IN[0], enc_counter_RIGHT_WHEEL);

// TURRET motor position : 7200 per turn
quadrature_decoder encoder_decoderTURRET(CLOCK_50, reset_enc_TURRET, GPIO_1[4], GPIO_1[5], enc_counter_TURRET);



//=======================================================
//  Oject detection and angle computations
//=======================================================
logic[31:0] angleIn,angleOut,deltaAngle,angleTargeted;
always_ff@(posedge GPIO_1[8])
angleOut <= enc_counter_TURRET;


always_ff@(negedge GPIO_1[8])
angleIn <= enc_counter_TURRET;

//=======================================================
//  Speed computations
//=======================================================

logic [31:0]	speed_LEFT_WHEEL, speed_RIGHT_WHEEL, speed_TURRET;
logic 			reset_speed_LEFT_WHEEL, reset_speed_RIGHT_WHEEL, reset_speed_TURRET;

// LEFT motor position
rotation_speed rotation_speedLEFT_WHEEL(CLOCK_50, reset_speed_LEFT_WHEEL, enc_counter_LEFT_WHEEL, speed_LEFT_WHEEL);

// RIGHT motor position
rotation_speed rotation_speedRIGHT_WHEEL(CLOCK_50, reset_speed_RIGHT_WHEEL, enc_counter_RIGHT_WHEEL, speed_RIGHT_WHEEL);

// TURRET motor position : 7200 per turn
rotation_speed rotation_speedTURRET(CLOCK_50, reset_speed_TURRET, enc_counter_TURRET, speed_TURRET);


//=======================================================
//  Actions to be done
//=======================================================

logic clk,reset;
logic [31:0] ReadDataM;
logic [7:0] led_reg;

assign clk = CLOCK_50;

assign MemWriteM = 1'b1; 

//Signaux de la tourelle assign??s au led
//assign led_reg[3] = GPIO_1[5];
//assign led_reg[2] = GPIO_1[4];
//assign led_reg[2] = GPIO_1[7];

//Reset Signal
//assign led_reg[1] = reset_enc_LEFT_WHEEL_SPI;
assign led_reg[0] = reset_enc_TURRET_SPI;

//assign led_reg = count[24:17];

// Chip Select logic
// For the moment we only use SPI, need a logic if we want to read a value from an input register
assign cs_spi    = 1'b1;  

// Read Data
always_comb // Not very useful yet, can become useful is we want to readData from multiple sources
	if (cs_spi) ReadDataM = spi_data;
	else ReadDataM = 32'b0;

// Adress for the SPIRegister
// The count goes up to 16 to link the 16 register, can be increased if needed
assign DataAdrM = {26'd0, registerCount, 2'd0}; 

// Update output register from the SPI
logic [3:0] registerCount;
counter SpiCounter(clk, reset, registerCount); 

// This code updates the data on the registers in misoRAM with counter
always_comb
	case (registerCount) 
		4'd0:  WriteDataM = enc_counter_TURRET; 		// turret position R0
		4'd1:  WriteDataM = enc_counter_LEFT_WHEEL; 	// motor left wheel position R1
		4'd2:  WriteDataM = enc_counter_RIGHT_WHEEL;	// motor right wheel position R2
		4'd3:  WriteDataM = speed_TURRET;
		4'd4:  WriteDataM = speed_LEFT_WHEEL;
		4'd5:  WriteDataM = speed_RIGHT_WHEEL;
		4'd6:  WriteDataM = angleIn; 					//angle measured on the beacon
	   4'd7:  WriteDataM = angleOut;
		// 4'd8:  WriteDataM = 
		// 4'd9:  WriteDataM = 
		// 4'd10:  WriteDataM = 
		// 4'd11:  WriteDataM = 
		// 4'd12:  WriteDataM = 
		// 4'd13:  WriteDataM = 
		4'd14:  WriteDataM = {31'd0, GPIO_1[8]}; // laserSignal R14 (normally transfered directly to the PI)    
		4'd15:  WriteDataM = {31'd0, GPIO_1[7]}; // laserSync  R15 (normally transfered directly to the PI) 
		default: WriteDataM = 32'h00000000;
	endcase

logic reset_enc_LEFT_WHEEL_SPI;
logic reset_enc_RIGHT_WHEEL_SPI;
logic reset_enc_TURRET_SPI;

// This code updates the data from the input register in mosiRAM with counter
always_ff @(posedge clk)
	case (registerCount)
		4'd0:  reset_enc_TURRET_SPI = ReadDataM[0]; // reset signal for the TURRET R0
		4'd1:  reset_enc_LEFT_WHEEL_SPI = ReadDataM[0]; // reset signal for the LEFT wheel R1      
		4'd2:  reset_enc_RIGHT_WHEEL_SPI = ReadDataM[0]; // reset signal for the RIGHT wheel R2
	endcase
	
always_ff @ (posedge clk, posedge reset) 
	if (reset)
		begin // Reset the counter and light on all the led to see that it is well reset
			LED = 8'hff;
			reset_enc_LEFT_WHEEL = 1'b1;
			reset_enc_RIGHT_WHEEL = 1'b1;
			reset_enc_TURRET = 1'b1;
			reset_speed_LEFT_WHEEL = 1'b1;
			reset_speed_RIGHT_WHEEL = 1'b1;
			reset_speed_TURRET = 1'b1;
		end		
	else
		begin 
			LED = led_reg;
			reset_enc_LEFT_WHEEL = reset_enc_LEFT_WHEEL_SPI;
			reset_enc_RIGHT_WHEEL = reset_enc_RIGHT_WHEEL_SPI;
			reset_enc_TURRET = reset_enc_TURRET_SPI; // reset soit par SPI soit par le capteur;
			//reset_enc_TURRET = (reset_enc_TURRET_SPI|~GPIO_1[7]); // reset soit par SPI soit par le capteur;
			reset_speed_LEFT_WHEEL = 1'b0;
			reset_speed_RIGHT_WHEEL = 1'b0;
			reset_speed_TURRET = 1'b0;
		end
	
endmodule

// This counter is used to update each register (n = 16): thus it requires n clock cycles to update each reg
module counter(input clk,
					input reset,
					output[3:0] counter);
					
always_ff @(posedge clk, posedge reset)
	if(reset) 
		counter <= 4'b0;
	else 
		counter <= counter + 1;
	
endmodule
		
