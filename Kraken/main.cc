#include <cstdio>
#include <stdio.h>
#include <stdlib.h>
#include <wiringPi.h>
#include <wiringPiSPI.h>
#include "CtrlStruct_gr3.h"
#include "ctrl_main_gr3.h"
#include "regulation/speed_controller_gr3.h"
#include "regulation/speed_regulation_gr3.h"
#include "localization/triangulation_gr3.h"
#include "localization/lidar.h"
#include "localization/sensor_merging_gr3.h"
#include "useful/mytime.h"
#include "useful/getch_keyboard.h"
#include <pthread.h>
#include <SDL2/SDL.h>

#define LIDAR_ENABLED 1
#define KEYBOARD_COMMAND 10.0

void get_FPGA_data(CtrlStruct *cvs, unsigned char *buffer, SPI *spi)
{
    CtrlIn *inputs = cvs->inputs;

	//Data from motor encoders
	buffer[0] = 0x00; // motor encoder left wheel angle
	wiringPiSPIDataRW(channel, buffer, 5);
	inputs->motor_enc_l_wheel_angle = compute_angle_wheel_motor(spi->frombytes(5, buffer));
	//printf("motor_enc_l_wheel_angle: %lf \n", inputs->motor_enc_l_wheel_angle);

	buffer[0] = 0x01; // motor encoder right wheel angle
	wiringPiSPIDataRW(channel, buffer, 5);
	inputs->motor_enc_r_wheel_angle = -compute_angle_wheel_motor(spi->frombytes(5, buffer));
	//printf("motor_enc_r_wheel_angle: %lf \n", inputs->motor_enc_r_wheel_angle);
	
	buffer[0] = 0x03; // odometer encoder left wheel angle
	wiringPiSPIDataRW(channel, buffer, 5);
	inputs->odo_l_wheel_angle = compute_angle_wheel_odo(spi->frombytes(5, buffer));
	//printf("odo_l_wheel_angle: %lf \n", inputs->odo_l_wheel_angle);
		 
	buffer[0] = 0x02; // odometer encoder right wheel angle
	wiringPiSPIDataRW(channel, buffer, 5);
	inputs->odo_r_wheel_angle = compute_angle_wheel_odo(spi->frombytes(5, buffer));
	//printf("odo_r_wheel_angle: %lf \n", inputs->odo_r_wheel_angle);
			
	buffer[0] = 0x04; // motor encoder left wheel speed
	wiringPiSPIDataRW(channel, buffer, 5);
	inputs->motor_enc_l_wheel_speed = compute_speed_wheel_motor(spi->frombytes(5, buffer));
	//printf("motor_enc_l_wheel_speed: %lf \n", inputs->motor_enc_l_wheel_speed);

	buffer[0] = 0x05; // motor encoder right wheel speed
	wiringPiSPIDataRW(channel, buffer, 5);
	inputs->motor_enc_r_wheel_speed = -compute_speed_wheel_motor(spi->frombytes(5, buffer));
	//printf("motor_enc_r_wheel_speed: %lf \n", inputs->motor_enc_r_wheel_speed);
	
	buffer[0] = 0x07; // odometer encoder left wheel speed
	wiringPiSPIDataRW(channel, buffer, 5);
	inputs->odo_l_wheel_speed = compute_speed_wheel_odo(spi->frombytes(5, buffer));
	//printf("odo_l_wheel_speed: %lf \n", inputs->odo_l_wheel_speed);
	
	buffer[0] = 0x06; // odometer encoder right wheel speed
	wiringPiSPIDataRW(channel, buffer, 5);
	inputs->odo_r_wheel_speed = compute_speed_wheel_odo(spi->frombytes(5, buffer));
	//printf("odo_r_wheel_speed: %lf \n\n", inputs->odo_r_wheel_speed);

/*		
	//Pneumatic part
	buffer[0] = 0x08; // motor encoder right wheel speed
	wiringPiSPIDataRW(channel, buffer, 5);
*/
	

	


/*
	//data ultrasonic sensor
	buffer[0] = 0x06; // motor encoder right wheel speed
	wiringPiSPIDataRW(channel, buffer, 5);
	printf("U1 %lf \n",(spi->frombytes(5, buffer))); 
	
	buffer[0] = 0x07; // motor encoder right wheel speed
	wiringPiSPIDataRW(channel, buffer, 5);
	printf("U2 %lf \n",(spi->frombytes(5, buffer)));
	
	buffer[0] = 0x08; // motor encoder right wheel speed
	wiringPiSPIDataRW(channel, buffer, 5);
	printf("U3 %lf \n",(spi->frombytes(5, buffer)));
	
	buffer[0] = 0x09; // motor encoder right wheel speed
	wiringPiSPIDataRW(channel, buffer, 5);
	printf("U4 %lf \n \n",(spi->frombytes(5, buffer)));
*/	
}

void *LIDAR_task(void *ptr) {

	printf("START: LIDAR task\n");

	CtrlStruct *cvs = (CtrlStruct*) ptr;
	CtrlIn *inputs = cvs->inputs;

	init_LIDAR(cvs);

	while(!cvs->stop_lidar) {
		//printf("LIDAR loop\n");
		get_LIDAR_data(cvs);
		triangulation_mean_data(cvs);
		triangulation_angles(cvs);
		//mergeSensorData(cvs);
	}

	free_LIDAR(cvs);

	return 0;

}

/*
void *web_task(void *ptr) {

	printf("START: WEB task\n");

	CtrlStruct *cvs = (CtrlStruct*) ptr;
	CtrlIn *inputs = cvs->inputs;

	

	return 0;

}
*/

void *keyboard_task(void *ptr) {

	printf("START: keyboard\n");

	CtrlStruct *cvs = (CtrlStruct*) ptr;
	unsigned char buffer[100];
	SPI *spi = cvs->spi;
	
	double start_time = get_time();
	
	SDL_Init(SDL_INIT_VIDEO);
    SDL_Window * window = SDL_CreateWindow("Kraken - ELME2002", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 320, 240, 0);


	printf("KEYBOARD mode\n");

    SDL_Event event;  
    int quit;
    double V = 0.0;
    double W = 0.0;
    
    quit = 0;
    
    while(quit != 2){
        while(SDL_PollEvent(&event)){
            switch(event.type)
            {
                case SDL_KEYDOWN:
                    switch(event.key.keysym.sym)
                    {
                        case SDLK_ESCAPE:
                            quit = 1;
                            break;
                        case SDLK_UP:
							V = KEYBOARD_COMMAND;
                            break;
                        case SDLK_DOWN:
							V = -KEYBOARD_COMMAND;   
                            break;
                        case SDLK_RIGHT:
							W = - KEYBOARD_COMMAND / 2.0;
                            break;
                        case SDLK_LEFT:
							W = KEYBOARD_COMMAND / 2.0;
                            break;
                        case SDLK_q:
                            cvs->keyboard = 1;
                            quit++;
                            break;
                        default : break;
                    }
                    break;
                case SDL_KEYUP:
                    switch(event.key.keysym.sym)
                    {
                        case SDLK_UP:
                            V = 0;
                            break;
                        case SDLK_DOWN:
                            V = 0;     
                            break;
                        case SDLK_RIGHT:
                            W = 0;
                            break;
                        case SDLK_LEFT:
                            W = 0;
                            break;
                        default : break;
                    }
                    break;
                default : break;
		    }
			printf("V_l = %lf   V_r = %lf\n", V + W, V - W);
        }
		if (quit == 1) {	
			cvs->inputs->t = get_time() - start_time;
			get_FPGA_data(cvs, buffer, spi);
			speed_regulation(cvs, V + W, V - W);
			//printf("Wheel commands: %1.3f %1.3f\n", cvs->outputs->wheel_commands[R_ID], cvs->outputs->wheel_commands[L_ID]);
			cvs->can->push_PropDC(10+cvs->outputs->wheel_commands[R_ID], 10-cvs->outputs->wheel_commands[L_ID]);
		}
    }



	printf("END: keyboard\n");
	
	cvs->stop_lidar = 1;
	
	return 0;

}


void *main_task(void *ptr) {
	printf("START: main task\n");

	CtrlStruct *cvs = (CtrlStruct*) ptr;

	//setup the motor
	cvs->can->ctrl_motor(1);
	unsigned char buffer[100];

	double start_time = get_time();

	CtrlIn *inputs = cvs->inputs;
	SPI *spi = cvs->spi;

	double t;

		

	while(cvs->keyboard == 0) {
		t = get_time() - start_time;
		inputs->t = t;
		printf("Time: %f\n", t);
		
		get_FPGA_data(cvs, buffer, spi);
		
		controller_loop(cvs);
		
		cvs->can->push_PropDC(10+cvs->outputs->wheel_commands[R_ID], 10-cvs->outputs->wheel_commands[L_ID]);
	}

	printf("END: main task\n");

	return 0;

}

int main()
{

	// Initialisation of the robot

	CtrlIn *inputs = (CtrlIn*) malloc(sizeof(CtrlIn));
	CtrlOut *outputs = (CtrlOut*) malloc(sizeof(CtrlOut));
	CtrlStruct *cvs = init_CtrlStruct(inputs, outputs);
	controller_init(cvs);
	printf("Kraken fully initialized \n");

	pthread_t keyboard_thread;
	pthread_create(&keyboard_thread, NULL, keyboard_task, (void*) cvs);

	pthread_t main_thread;
	pthread_create(&main_thread, NULL, main_task, (void*) cvs);

	//pthread_t web_thread;
	//pthread_create(&web_thread, NULL, web_task, (void*) cvs);

	if (LIDAR_ENABLED) {
		pthread_t LIDAR_thread;
		pthread_create(&LIDAR_thread, NULL, LIDAR_task, (void*) cvs);
		pthread_join(LIDAR_thread, NULL); 
	}

	pthread_join(main_thread, NULL);
	pthread_join(keyboard_thread, NULL);

	controller_finish(cvs);
	free_CtrlStruct(cvs);
	printf("Kraken freed\n");
	return 0;

}

