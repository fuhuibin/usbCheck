//
//  main.m
//  usbCheck
//
//  Created by Louis on 13-7-27.
//  Copyright (c) 2013年 Louis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UartComm.h"

typedef enum
{
    Error_1 = 1,
} ErrorCode ;

int main(int argc, const char * argv[])
{
    if (argc !=3)
    {
        NSLog(@" Error Format:usbCheck [index] [DP]") ;
        return 1 ;
    }
    
    const char *index = argv[1] ;
    const char *dp   = argv[2] ;
    @autoreleasepool
    {
        // insert code here...
        NSString *strIndex = [NSString stringWithFormat:@"%s",index] ;
        NSString *strDP = [NSString stringWithFormat:@"%s",dp] ;
        
        ///dev/cu.usbserial-UUT1-MCU
        NSString *portName = [NSString stringWithFormat:@"/dev/cu.usbserial-UUT%d-%@",strIndex.intValue+1,strDP.uppercaseString] ;
        ///dev/cu.usbserial-MCUA  ,/dev/cu.usbserial-UUT_UARTA
#if 0
         NSArray *arrUart = [UartComm ScanPort] ;
        NSLog(@" scan port :%@",arrUart) ;
        NSMutableArray *scanUart = [NSMutableArray arrayWithArray:arrUart] ;
        for (int i=0; i<scanUart.count; i++)
        {
            NSString *uartName = [scanUart objectAtIndex:i] ;
            NSRange range  = [uartName rangeOfString:@"cu.usbserial"] ;
            if (range.location==NSNotFound) //invalid uart
            {
                [scanUart removeObject:uartName] ;
                continue ;
            }
            
            //here is valid uart ..
            NSRange range1 = [uartName rangeOfString:@"-MCU"] ;
            NSRange range2 = [uartName rangeOfString:@"-UUT_UART"] ;
            if (range1.location!=NSNotFound || range2.location!=NSNotFound) //uut or mcu uart
            {
                [scanUart removeObject:uartName] ;
                continue ;
            }
        }
        
        if (index.intValue >=scanUart.count)
            return 1 ; //not exist uart ...
#endif
        UartComm *uartComm = [[UartComm alloc] init] ;
        if ([uartComm OpenPort:portName BaudRate
                          :BAUDRATE_115200 DataBits:DATA_BITS_8 StopBit
                          :STOP_BITS_2 Parity
                          :PARITY_ODD FlowControl:FLOW_CONTROL_NONE]==FALSE)
        {
            [uartComm release] ;
            NSLog([NSString stringWithFormat:@"fail for port[%@],open fail",portName]) ;
            return 2 ;//open fail
        }
        
        const char sendBuffer[] = "123456789" ;
        //send
        [uartComm SendData:[NSData dataWithBytes:sendBuffer length:sizeof(sendBuffer)]] ;
        usleep(1000*300) ;
        NSData *dataRece = [uartComm ReceiveData] ;
        if (dataRece==nil || dataRece.length==0)
        {
            [uartComm ClosePort] ;
            [uartComm release] ;
            NSLog([NSString stringWithFormat:@"fail for port[%@] ,can't receivd data",portName]) ;
            return 3 ; //RECE LEN=0
        }else
        {
            if ([dataRece isEqualToData:[NSData dataWithBytes:sendBuffer length:sizeof(sendBuffer)]])
            {
                [uartComm ClosePort] ;
                [uartComm release] ;
                NSLog([NSString stringWithFormat:@"Successful for port[%@]",portName]) ;
                return 0 ;
            }else
            {
                [uartComm ClosePort] ;
                [uartComm release] ;
                NSLog([NSString stringWithFormat:@"fail for: port[%@] ,send:%s,received:%s",portName,sendBuffer,dataRece.bytes]) ;
                return 4 ;//SEND DATA NOT EQUAL RECE DATA
            }
        }
    }
    return 0;
}

