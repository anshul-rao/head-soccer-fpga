#include <stdio.h>
#include "platform.h"
#include "lw_usb/GenericMacros.h"
#include "lw_usb/GenericTypeDefs.h"
#include "lw_usb/HID.h"
#include "lw_usb/MAX3421E.h"
#include "lw_usb/USB.h"
#include "xparameters.h"
#include "xgpio.h"

static XGpio Gpio;

static BOOT_KBD_REPORT kbd_buf;

void USB_init(void);
void USB_Task(void);
BYTE GetUsbTaskState(void);

#ifndef rcodeNO_ERROR
#define rcodeNO_ERROR 0
#endif

extern HID_DEVICE hid_device;

#define KEY_A       0x04
#define KEY_D       0x07
#define KEY_W       0x1A
#define KEY_E       0x08

#define KEY_LEFT    0x50
#define KEY_RIGHT   0x4F
#define KEY_UP      0x52
#define KEY_SLASH   0x38

#define KEY_R       0x15
#define KEY_1       0x1E
#define KEY_2       0x1F

int main() {
    init_platform();
    XGpio_Initialize(&Gpio, XPAR_GPIO_USB_KEYCODE_DEVICE_ID);

    XGpio_SetDataDirection(&Gpio, 1, 0x00000000);
    XGpio_SetDataDirection(&Gpio, 2, 0x00000000);

    MAX3421E_init();
    USB_init();

    while (1) {
        MAX3421E_Task();
        USB_Task();

        if (GetUsbTaskState() == USB_STATE_RUNNING) {
            if (kbdPoll(&kbd_buf) == rcodeNO_ERROR) {

                u8 p1_control_mask = 0;
                u8 p2_control_mask = 0;

                for (int i = 0; i < 6; i++) {
                    u8 key = kbd_buf.keycode[i];

                    if (key == KEY_A)     p1_control_mask |= 0x01;
                    if (key == KEY_D)     p1_control_mask |= 0x02;
                    if (key == KEY_W)     p1_control_mask |= 0x04;
                    if (key == KEY_E)     p1_control_mask |= 0x08;

                    if (key == KEY_LEFT)  p2_control_mask |= 0x01;
                    if (key == KEY_RIGHT) p2_control_mask |= 0x02;
                    if (key == KEY_UP)    p2_control_mask |= 0x04;
                    if (key == KEY_SLASH) p2_control_mask |= 0x08;

                    if (key == KEY_R)     p2_control_mask |= 0x10;
                    if (key == KEY_1)     p2_control_mask |= 0x20;
                    if (key == KEY_2)     p2_control_mask |= 0x40;
                }

                XGpio_DiscreteWrite(&Gpio, 1, p1_control_mask);
                XGpio_DiscreteWrite(&Gpio, 2, p2_control_mask);
            }
        }
        else if (GetUsbTaskState() == USB_STATE_ERROR) {
             xil_printf("USB Error State\r\n");
        }
    }
    cleanup_platform();
    return 0;
}
