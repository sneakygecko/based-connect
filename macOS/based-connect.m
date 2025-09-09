#import <Cocoa/Cocoa.h>
#import <IOBluetooth/objc/IOBluetoothRFCOMMChannel.h>
#import <IOBluetooth/objc/IOBluetoothDevice.h>
#import <IOBluetooth/objc/IOBluetoothSDPUUID.h>
#import <IOBluetooth/objc/IOBluetoothSDPServiceRecord.h>

#include <getopt.h>

const char* USAGE_DECL = "Usage:\n\t./based-connect [options] <address>\n\taddress: The Bluetooth address of the device.\n\nOptions:\n\t-h, --help\n\t\tPrint the help message.\n\n\t-c <level>, --noise-cancelling=<level>\n\t\tChange the noise cancelling level.\n\t\tlevel: high, low, off\n\n\t-o <minutes>, --auto-off=<minutes>\n\t\tChange the auto-off time.\n\t\tminutes: never, 5, 20, 40, 60, 180\n\n\t-f, --firmware-version\n\t\tPrint the firmware version on the device.\n\n\t-s, --serial-number\n\t\tPrint the serial number of the device.\n\n\t-b, --battery-level\n\t\tPrint the battery level of the device as a percent.\n\n\t-a, --paired-devices\n\t\tPrint the devices currently connected to the device.\n\t\t!: indicates the current device\n\t\t*: indicates other connected devices";

#define ANY 0x00

#define NC_HIGH 0x01
#define NC_LOW 0x03
#define NC_OFF 0x00

#define VP_MASK 0x20

enum PromptLanguage {
    PL_EN = 0x21,
    PL_FR = 0x22,
    PL_IT = 0x23,
    PL_DE = 0x24,
    PL_ES = 0x26,
    PL_PT = 0x27,
    PL_ZH = 0x28,
    PL_KO = 0x29,
    PL_NL = 0x2e,
    PL_JA = 0x2f,
    PL_SV = 0x32
};

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    IOBluetoothRFCOMMChannel *mRFCOMMChannel;
    IOBluetoothDevice *targetDevice;
    NSString *deviceAddress;

    int numBytesToss;
    int displayCode; // 0 = don't display, 1 = display string, 2 = display uint8_t
    BOOL isInit;

    // Command line arguments storage
    int storedArgc;
    char **storedArgv;
}

@property(assign) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (instancetype)init
{
    self = [super init];
    if (self) {
        numBytesToss = 0;
        displayCode = 0;
        isInit = NO;
        deviceAddress = nil;
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Store command line arguments
    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
    storedArgc = (int)[arguments count];
    storedArgv = malloc(storedArgc * sizeof(char*));

    for (int i = 0; i < storedArgc; i++) {
        NSString *arg = [arguments objectAtIndex:i];
        const char *cString = [arg UTF8String];
        storedArgv[i] = malloc(strlen(cString) + 1);
        strcpy(storedArgv[i], cString);
    }

    [self parseArgumentsAndConnect];
}

- (void)parseArgumentsAndConnect
{
    const char *short_opt = "hc:o:fsba";
    struct option long_opt[] = {
        {"help", no_argument, NULL, 'h'},
        {"noise-cancelling", required_argument, NULL, 'c'},
        {"auto-off", required_argument, NULL, 'o'},
        {"firmware-version", no_argument, NULL, 'f'},
        {"serial-number", no_argument, NULL, 's'},
        {"battery-level", no_argument, NULL, 'b'},
        {"paired-devices", no_argument, NULL, 'a'},
        {NULL, 0, NULL, 0}
    };

    // Reset getopt
    optind = 1;

    int c;
    while ((c = getopt_long(storedArgc, storedArgv, short_opt, long_opt, NULL)) != -1) {
        if (c == 'h') {
            printf("%s\n", USAGE_DECL);
            [NSApp terminate:nil];
            return;
        }
        if (c == 'a') {
            [self get_paired_devices];
            [NSApp terminate:nil];
            return;
        }
    }

    if (optind >= storedArgc) {
        fprintf(stderr, "Missing address argument.\n");
        printf("%s\n", USAGE_DECL);
        [NSApp terminate:nil];
        return;
    }
    
    deviceAddress = [NSString stringWithUTF8String:storedArgv[optind]];

    [self discover];
}

- (void)init_connection
{
    const unsigned char bytes[] = {0x00, 0x01, 0x01, 0x00};
    NSData *dt = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    numBytesToss = 4;
    displayCode = 1;
    isInit = YES;
    [self sendMessage:dt];
}

- (void)get_battery_level
{
    const unsigned char bytes[] = {0x02, 0x02, 0x01, 0x00};
    NSData *dt = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    numBytesToss = 4;
    displayCode = 2;
    isInit = NO;
    [self sendMessage:dt];
}

- (void)get_serial_number
{
    const unsigned char bytes[] = {0x00, 0x07, 0x01, 0x00};
    NSData *dt = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    numBytesToss = 4;
    displayCode = 1;
    isInit = NO;
    [self sendMessage:dt];
}





- (void)set_noise_cancelling:(char)newLevel
{
    const unsigned char bytes[] = {0x01, 0x06, 0x02, 0x01, newLevel};
    NSData *dt = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    numBytesToss = 3;
    displayCode = 5;
    isInit = NO;
    [self sendMessage:dt];
}

- (void)set_auto_off:(int)minutes
{
    const unsigned char bytes[] = {0x01, 0x04, 0x02, 0x01, minutes};
    NSData *dt = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    numBytesToss = 4;
    displayCode = 7;
    isInit = NO;
    [self sendMessage:dt];
}



- (void)get_paired_devices
{
    NSArray *pairedDevices = [IOBluetoothDevice pairedDevices];
    printf("Paired devices:\n");
    for (IOBluetoothDevice *device in pairedDevices) {
        printf("  %s (%s)\n", [[device nameOrAddress] UTF8String], [[device addressString] UTF8String]);
    }
    [NSApp terminate:nil];
}

- (void)get_firmware_version
{
    const unsigned char bytes[] = {0x00, 0x05, 0x01, 0x00};
    NSData *dt = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    numBytesToss = 4;
    displayCode = 1;
    isInit = NO;
    [self sendMessage:dt];
}

- (void)sendMessage:(NSData *)dataToSend
{
    if (mRFCOMMChannel && [mRFCOMMChannel isOpen]) {

        


        IOReturn result = [mRFCOMMChannel writeSync:(void *)dataToSend.bytes length:dataToSend.length];
        if (result != kIOReturnSuccess) {
            printf("Error sending message: %08x\n", result);
        }
    } else {
        printf("Error: RFCOMM channel not open\n");
        [NSApp terminate:nil];
    }
}

- (void)log:(NSString *)text
{
    printf("%s", [text UTF8String]);
}

- (void)dispatchAction
{
    // Reset getopt for second pass
    optind = 1;

    int c;
    const char *short_opt = "hc:o:fsba";
    struct option long_opt[] = {
        {"help", no_argument, NULL, 'h'},
        {"noise-cancelling", required_argument, NULL, 'c'},
        {"auto-off", required_argument, NULL, 'o'},
        {"firmware-version", no_argument, NULL, 'f'},
        {"serial-number", no_argument, NULL, 's'},
        {"battery-level", no_argument, NULL, 'b'},
        {"paired-devices", no_argument, NULL, 'a'},
        {NULL, 0, NULL, 0}
    };

    while ((c = getopt_long(storedArgc, storedArgv, short_opt, long_opt, NULL)) != -1) {
        switch (c) {
            case -1:
            case 0:
                break;

            case 'b':
                [self get_battery_level];
                return;

            case 's':
                [self get_serial_number];
                return;

            case 'f':
                [self get_firmware_version];
                return;

            

            case 'h':
                printf("%s\n", USAGE_DECL);
                [NSApp terminate:nil];
                return;

            case 'c':
                if (optarg) {
                    if (!strcmp(optarg, "high")) {
                        [self set_noise_cancelling:NC_HIGH];
                    } else if (!strcmp(optarg, "low")) {
                        [self set_noise_cancelling:NC_LOW];
                    } else {
                        [self set_noise_cancelling:NC_OFF];
                    }
                    return;
                }
                break;

            case 'o':
                if (optarg) {
                    int minutes = 0;
                    if (strcmp(optarg, "never") == 0) {
                        minutes = 0;
                    } else {
                        minutes = atoi(optarg);
                        // Basic validation
                        if (minutes != 5 && minutes != 20 && minutes != 40 && minutes != 60 && minutes != 180) {
                            fprintf(stderr, "Invalid auto-off value. Use one of: never, 5, 20, 40, 60, 180\n");
                            [NSApp terminate:nil];
                            return;
                        }
                    }
                    [self set_auto_off:minutes];
                    return;
                }
                break;

            case ':':
            case '?':
                fprintf(stderr, "Try `--help' for more information.\n");
                [NSApp terminate:nil];
                return;

            default:
                fprintf(stderr, "invalid option -- %c\n", c);
                fprintf(stderr, "Try `--help' for more information.\n");
                [NSApp terminate:nil];
                return;
        }
    }

    // If no command was provided, it's fine, just exit.
    [NSApp terminate:nil];
}

- (void)discover
{
    

    NSArray *pairedDevices = [IOBluetoothDevice pairedDevices];
    IOBluetoothDevice *boseDevice = nil;

    // Look for Bose device
    for (IOBluetoothDevice *device in pairedDevices) {
        NSString *name = [device nameOrAddress];
        NSString *address = [device addressString];

        // Check if this is a Bose device or matches specified address
        if (deviceAddress) {
            if ([address caseInsensitiveCompare:deviceAddress] == NSOrderedSame) {
                boseDevice = device;
                break;
            }
        } else {
            // Look for Bose devices by name
            if ([name containsString:@"Bose QC35"] ||
                [name containsString:@"QuietComfort"] ||
                [name containsString:@"QC35"]) {
                boseDevice = device;
                break;
            }
        }
    }

    if (!boseDevice) {
        if (deviceAddress) {
            printf("Error: Could not find device with address %s\n", [deviceAddress UTF8String]);
        } else {
            printf("Error: Could not find Bose QC35 device. Make sure it's paired and powered on.\n");
            printf("Available paired devices:\n");
            for (IOBluetoothDevice *device in pairedDevices) {
                printf("  %s (%s)\n", [[device nameOrAddress] UTF8String], [[device addressString] UTF8String]);
            }
            printf("\nUse -a or --address option to specify exact MAC address.\n");
        }
        [NSApp terminate:nil];
        return;
    }

    

    // Get SPP service
    IOBluetoothSDPUUID *sppServiceUUID = [IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16ServiceClassSerialPort];
    IOBluetoothSDPServiceRecord *sppServiceRecord = [boseDevice getServiceRecordForUUID:sppServiceUUID];

    if (sppServiceRecord == nil) {
        [self log:@"Error - no SPP service found in device\n"];
        [NSApp terminate:nil];
        return;
    }

    // Get RFCOMM channel ID
    UInt8 rfcommChannelID;
    if ([sppServiceRecord getRFCOMMChannelID:&rfcommChannelID] != kIOReturnSuccess) {
        [self log:@"Error - could not get RFCOMM channel ID\n"];
        [NSApp terminate:nil];
        return;
    }

    

    // Open RFCOMM channel
    IOBluetoothRFCOMMChannel *channel;
    IOReturn result = [boseDevice openRFCOMMChannelAsync:&channel
                                           withChannelID:rfcommChannelID
                                                delegate:self];

    if (result != kIOReturnSuccess) {
        printf("Error - failed to initiate RFCOMM connection: %08x\n", result);
        [NSApp terminate:nil];
        return;
    }

    mRFCOMMChannel = channel;
    targetDevice = boseDevice;
}

- (void)rfcommChannelOpenComplete:(IOBluetoothRFCOMMChannel *)rfcommChannel status:(IOReturn)error
{
    if (error != kIOReturnSuccess) {
        printf("Error - failed to open RFCOMM channel: %08x\n", error);
        [NSApp terminate:nil];
        return;
    }

    
    [self init_connection];
}

- (void)rfcommChannelData:(IOBluetoothRFCOMMChannel *)rfcommChannel data:(void *)dataPointer length:(size_t)dataLength
{
    if (isInit) {
        [self dispatchAction];
        return;
    }

    if ((int)dataLength <= numBytesToss) {
        printf("Error: Received data too short (got %zu, need >%d)\n", dataLength, numBytesToss);
        [NSApp terminate:nil];
        return;
    }

    size_t messageLength = dataLength - numBytesToss;
    void *messageData = ((char *)dataPointer + numBytesToss);

    

    if (displayCode == 1) {
        // Display as string
        NSString *message = [[NSString alloc] initWithBytes:messageData
                                                     length:messageLength
                                                   encoding:NSUTF8StringEncoding];
        if (message) {
            printf("%s\n", [message UTF8String]);
        } else {
            printf("Error: Could not decode string\n");
        }
    } else if (displayCode == 4) {
        // Display noise cancelling status from getnc (device status dump)
        const unsigned char pattern[] = {0x01, 0x06, 0x03, 0x02};
        char val = -1;
        for (size_t i = 0; i < dataLength - sizeof(pattern); i++) {
            if (memcmp((char *)dataPointer + i, pattern, sizeof(pattern)) == 0) {
                val = ((char *)dataPointer)[i + sizeof(pattern)];
                break;
            }
        }

        if (val != -1) {
            printf("NC status byte: 0x%02x -> ", (unsigned char)val);
            if (val == NC_HIGH) {
                printf("High\n");
            } else if (val == NC_LOW) {
                printf("Low\n");
            } else {
                printf("Off\n");
            }
        } else {
            printf("Error: Could not find NC status in response\n");
        }
    } else if (displayCode == 5) {
        // Display noise cancelling status from setnc
        if (messageLength > 1) {
            char val = ((char *)messageData)[1];
            printf("NC status byte: 0x%02x -> ", (unsigned char)val);
            if (val == NC_HIGH) {
                printf("High\n");
            } else if (val == NC_LOW) {
                printf("Low\n");
            }
            else {
                printf("Off\n");
            }
        }
    } else if (displayCode == 6) {
        // Display auto-off status from getsleep (device status dump)
        const unsigned char pattern[] = {0x01, 0x04, 0x03, 0x01};
        char val = -1;
        for (size_t i = 0; i < dataLength - sizeof(pattern); i++) {
            if (memcmp((char *)dataPointer + i, pattern, sizeof(pattern)) == 0) {
                val = ((char *)dataPointer)[i + sizeof(pattern)];
                break;
            }
        }

        if (val != -1) {
            printf("Auto-off minutes: %d\n", val);
        } else {
            printf("Error: Could not find auto-off status in response\n");
        }
    } else if (displayCode == 7) {
        // Display auto-off status from set_auto_off
        if (messageLength > 0) {
            unsigned char val = *(unsigned char *)messageData;
            printf("Auto-off set to: %d minutes\n", val);
        }
    } else if (displayCode == 2) {
        // Display as number
        if (messageLength > 0) {
            unsigned char val = *(unsigned char *)messageData;
            printf("Response: %u (0x%02x)\n", val, val);
        }
    }

    [NSApp terminate:nil];
}

- (void)rfcommChannelClosed:(IOBluetoothRFCOMMChannel *)rfcommChannel
{
    printf("RFCOMM channel closed\n");
    mRFCOMMChannel = nil;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    if (mRFCOMMChannel && [mRFCOMMChannel isOpen]) {
        [mRFCOMMChannel closeChannel];
    }

    // Clean up allocated memory
    if (storedArgv) {
        for (int i = 0; i < storedArgc; i++) {
            if (storedArgv[i]) {
                free(storedArgv[i]);
            }
        }
        free(storedArgv);
    }
}

@end

int main(int argc, char *argv[])
{
    if (argc == 1 || (argc == 2 && (!strcmp(argv[1], "-h") || !strcmp(argv[1], "--help")))) {
        printf("%s\n", USAGE_DECL);
        return 0;
    }

    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        AppDelegate *delegate = [[AppDelegate alloc] init];
        [app setDelegate:delegate];
        [app run];
    }

    return 0;
}
