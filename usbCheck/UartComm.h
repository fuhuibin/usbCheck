//
//  UartComm.h
//  qt_simulator
//
//  Created by diags on 3/4/10.
//  Copyright 2010 Foxconn. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <sys/socket.h>
#import "termios.h"
#include <IOKit/IOKitLib.h>
#include <IOKit/IOMessage.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/usb/IOUSBLib.h>
//baudrate default

enum BaudRate
{
    BAUDRATE_4800   = B4800,
	BAUDRATE_9600   = B9600,
	BAUDRATE_19200  = B19200,
	BAUDRATE_38400  = B38400,
	BAUDRATE_76800  = B76800, 	
	BAUDRATE_115200 = B115200,
	BAUDRATE_230400 = B230400,
	BAUDRATE_DEFAULT= BAUDRATE_115200,
};

//data bit defined
enum DataBits
{
	DATA_BITS_5,
	DATA_BITS_6,
	DATA_BITS_7,
	DATA_BITS_8,
	DATA_BITS_DEFAULT =DATA_BITS_8,
};

//parity bit define
enum Parity
{
	PARITY_EVEN,
	PARITY_ODD,
	PARITY_NONE,
	PARITY_DEFAULT = PARITY_NONE,
};

//stop bit define
enum StopBit
{
	STOP_BITS_1,
	STOP_BITS_2,
	STOP_BITS_DEFAULT = STOP_BITS_1,
};

//flow control
enum FlowControl
{
	FLOW_CONTROL_HANDWARE,
	FLOW_CONTROL_SOFTWARE,
	FLOW_CONTROL_NONE,
	FLOW_CONTROL_DEFAULT = FLOW_CONTROL_NONE ,
};

enum CommType
{
	TYPE_UART,
	TYPE_SOCKET,
    TYPE_USBCLI,
};

@interface UartComm : NSObject {
	NSMutableData *receDataBuffer ; //it is used to save data received 
	NSMutableData *sendDataBuffer ; //it is used to save data sended 
	
	enum CommType commType ;
	int fileDesc ;
	int listenSocket ;
	
	//NSFileHandle *fileHandle ;
	unsigned long  portStatus  ;
	struct termios serialOption ; //file description structure
	NSString *portID ; //it is used to identify the serial port .
	
	NSThread *UartCommThread ;
}
+(NSArray*)ScanPort ;
+(NSArray*)ScanBaudRate ;
+(NSArray*)ScanDataBit ;
+(NSArray*)ScanStopBit ;
+(NSArray*)ScanParity ;
+(NSArray*)ScanFlowControl;
+(NSArray*)SCanUSBDevice ;
+(BOOL) generateUSBSiblingsParaMeter ;


-(bool)OpenPort:(NSString*)portName BaudRate
			   :(enum BaudRate)baudRate DataBits   
			   :(enum DataBits)dataBits StopBit
               :(enum StopBit)stopBit   Parity
			   :(enum Parity)parity     FlowControl
               :(enum FlowControl)flowControl ;
-(bool)IsOpen;
-(void)ClosePort;
-(void)SetBaudRate:(enum BaudRate)baudRate;
-(void)SetDataBit:(enum DataBits)dataBits ;
-(void)SetParity:(enum Parity)parity ;
-(void)SetStopBit:(enum StopBit)stopBit ;
-(void)SetFlowControl:(enum FlowControl)flowControl;

//send  and received data
-(NSData*)ReceiveData ;
-(bool)SendData:(NSData*) sendBuffer ;

//set port id
-(void)setPortID:(NSString*) nsstrTmp;


///socket comm function as belowed 
-(bool)Socket_OpenPort:(NSString*)strIP PortID
                      :(int)iPortID ;
-(bool)Socket_IsOpen; 
-(void)Socket_ClosePort;
-(NSData*)Socket_ReceiveData ;
-(bool)Socket_SendData:(NSData*) sendBuffer ;

//here is USB CLI function 
-(bool)USBCLI_Open ;
-(bool)USBCLI_IsOpen ;
-(bool)USBCLI_Close;
-(NSData*)USBCLI_ReceiveResult ;
-(bool)USBCLI_SendCmd:(NSData*)execCmd ;//execute the cli command .
-(bool)USBCLI_GetResultData:(NSString*)strFileName ;

@end
