// #include "luat_conf_bsp.h"
#include "luat_base.h"
#include "luat_fs.h"
#define LUAT_LOG_TAG "fs"
#include "luat_log.h"
#include "lfs_port.h"
#include "wm_include.h"
#include "luat_timer.h"
#include "stdio.h"
#include "luat_ota.h"
#include "wm_internal_flash.h"

extern struct lfs_config lfs_cfg;
extern lfs_t lfs;

// 分区信息

// KV -- 64k
// luadb -- N k
// lfs - (112 + 64 - N)k
uint32_t kv_addr;
uint32_t kv_size_kb = 64;
uint32_t luadb_addr;
uint32_t luadb_size_kb;
uint32_t lfs_addr;
uint32_t lfs_size_kb;

#ifndef FLASH_FS_REGION_SIZE
#define FLASH_FS_REGION_SIZE 112
#endif

extern const struct luat_vfs_filesystem vfs_fs_lfs2;
extern const char luadb_inline_sys[];
extern const struct luat_vfs_filesystem vfs_fs_luadb;
extern const struct luat_vfs_filesystem vfs_fs_ram;
extern size_t luat_luadb_act_size;

#ifdef LUAT_USE_LVGL
#include "lvgl.h"
void luat_lv_fs_init(void);
// void lv_bmp_init(void);
// void lv_png_init(void);
void lv_split_jpeg_init(void);
#endif

// 调整LUADB文件系统大小, 必须是 48+64*N, N为整数. 例如 48+64, 48+128
#ifndef LUAT_FS_SIZE
#define LUAT_FS_SIZE (48)
#endif

void luat_fs_update_addr(void) {
    //luat_timer_mdelay(1000);
#if (defined(AIR103) || defined(AIR601))
    luadb_addr =  0x0E0000 - (FLASH_FS_REGION_SIZE - 112) * 1024U;
#else
    luadb_addr =  0x1E0000 - (FLASH_FS_REGION_SIZE - 112) * 1024U;
#endif
    //LLOGD("luadb_addr 0x%08X", luadb_addr);
    //LLOGD("luadb_addr ptr %p", ptr);
#if (defined(AIR103) || defined(AIR601))
        lfs_addr = 0x0FC000 - (LUAT_FS_SIZE*1024);
        lfs_size_kb = LUAT_FS_SIZE;
#else
        lfs_addr = 0x1FC000 - (LUAT_FS_SIZE*1024);
        lfs_size_kb = LUAT_FS_SIZE;
#endif
        kv_addr = luadb_addr - kv_size_kb*1024U;
    // }

    //LLOGD("lfs addr4 %p", &lfs_addr);
    //LLOGD("lfs addr5 0x%08X", lfs_addr);
    //LLOGD("luadb_addr 0x%08X", luadb_addr);
}

int luat_fs_init(void) {
    uint8_t *ptr = (uint8_t*)(luadb_addr + 0x8000000); //0x80E0000
    LFS_Init();
    luat_vfs_reg(&vfs_fs_lfs2);
	luat_fs_conf_t conf = {
		.busname = &lfs,
		.type = "lfs2",
		.filesystem = "lfs2",
		.mount_point = "/"
	};
	luat_fs_mount(&conf);

    luat_vfs_reg(&vfs_fs_ram);
    luat_fs_conf_t conf3 = {
		.busname = NULL,
		.type = "ram",
		.filesystem = "ram",
		.mount_point = "/ram/"
	};
	luat_fs_mount(&conf3);
    
	luat_vfs_reg(&vfs_fs_luadb);
	luat_fs_conf_t conf2 = {
		.busname = (char*)(ptr),
		.type = "luadb",
		.filesystem = "luadb",
		.mount_point = "/luadb/",
	};
	luat_fs_mount(&conf2);
    luat_luadb_act_size = (FLASH_FS_REGION_SIZE - 112);

	#ifdef LUAT_USE_LVGL
	luat_lv_fs_init();
	// lv_bmp_init();
	// lv_png_init();
	lv_split_jpeg_init();
	#endif

	return 0;
}
