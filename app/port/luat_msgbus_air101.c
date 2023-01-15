#include "luat_base.h"
#include "luat_msgbus.h"
#include "luat_malloc.h"
#include "wm_osal.h"
#include "FreeRTOS.h"
#include "rtosqueue.h"

static QueueHandle_t xQueue = {0};

void luat_msgbus_init(void) {
    if (!xQueue) {
        xQueue = xQueueCreate(256, sizeof(rtos_msg_t));
    }
}
uint32_t luat_msgbus_put(rtos_msg_t* msg, size_t timeout) {
    if (xQueue == NULL)
        return 1;
    return xQueueSendFromISR(xQueue, msg, NULL) == pdTRUE ? 0 : 1;
}
uint32_t luat_msgbus_get(rtos_msg_t* msg, size_t timeout) {
    if (xQueue == NULL)
        return 1;
    return xQueueReceive(xQueue, msg, timeout) == pdTRUE ? 0 : 1;
}
uint32_t luat_msgbus_freesize(void) {
    return 1;
}

