set_project("AIR101")
set_xmakever("2.6.3")

-- set_version("0.0.2", {build = "%Y%m%d%H%M"})
add_rules("mode.debug", "mode.release")

local AIR10X_VERSION
local luatos = "../LuatOS/"
local TARGET_NAME
local AIR10X_FLASH_FS_REGION_SIZE

toolchain("csky")
    set_kind("cross")
    -- on load
    on_load(function (toolchain)
        -- load basic configuration of cross toolchain
        toolchain:load_cross_toolchain()
    end)
toolchain_end()

package("csky")
    set_kind("toolchain")
    set_homepage("https://occ.t-head.cn/community/download?id=3885366095506644992")
    set_description("GNU Csky Embedded Toolchain")

    if is_host("windows") then
        set_urls("http://cdndownload.openluat.com/xmake/toolchains/csky/csky-elfabiv2-tools-mingw-minilibc-$(version).tar.gz")
        add_versions("20210423", "e7d0130df26bcf7b625f7c0818251c04e6be4715ed9b3c8f6303081cea1f058b")
    elseif is_host("linux") then
        set_urls("http://cdndownload.openluat.com/xmake/toolchains/csky/csky-elfabiv2-tools-x86_64-minilibc-$(version).tar.gz")
        add_versions("20210423", "8b9a353c157e4d44001a21974254a21cc0f3c7ea2bf3c894f18a905509a7048f")
    end
    on_install("@windows", "@linux", function (package)
        os.vcp("*", package:installdir())
    end)
package_end()

add_requires("csky 20210423")
set_toolchains("csky@csky")

local flto = ""

--add macro defination
add_defines("GCC_COMPILE=1","TLS_CONFIG_CPU_XT804=1","NIMBLE_FTR=1","__LUATOS__")

set_warnings("all")
set_optimize("fastest")
-- set language: c99
set_languages("c99")
add_asflags(flto .. "-DTLS_CONFIG_CPU_XT804=1 -DGCC_COMPILE=1 -mcpu=ck804ef -std=gnu99 -c -mhard-float -Wa,--gdwarf2 -fdata-sections -ffunction-sections")
add_cflags(flto .. "-DTLS_CONFIG_CPU_XT804=1 -DGCC_COMPILE=1 -mcpu=ck804ef -std=gnu99 -c -mhard-float -Wall -fdata-sections -ffunction-sections")
add_cxflags(flto .. "-DTLS_CONFIG_CPU_XT804=1 -DGCC_COMPILE=1 -mcpu=ck804ef -std=gnu99 -c -mhard-float -Wall -fdata-sections -ffunction-sections")

set_dependir("$(buildir)/.deps")
set_objectdir("$(buildir)/.objs")

set_policy("build.across_targets_in_parallel", false)

target("app")
    set_kind("static")
    set_plat("cross")
    set_arch("c-sky")

    add_includedirs("app/port",{public = true})

    add_files("src/app/**.c")
    remove_files("src/app/btapp/**.c")

    add_includedirs(os.dirs(path.join(os.scriptdir(),"src/app/**")))
    add_includedirs(os.dirs(path.join(os.scriptdir(),"src/bt/blehost/**")))

    add_includedirs("include",{public = true})
    add_includedirs("include/app",{public = true})
    add_includedirs("include/driver",{public = true})
    add_includedirs("include/os",{public = true})
    add_includedirs("include/bt",{public = true})
    add_includedirs("include/platform",{public = true})
    add_includedirs("platform/common/params",{public = true})
    add_includedirs("include/wifi",{public = true})
    add_includedirs("include/arch/xt804",{public = true})
    add_includedirs("include/arch/xt804/csi_core",{public = true})
    add_includedirs("include/net",{public = true})
    add_includedirs("demo",{public = true})
    add_includedirs("platform/inc",{public = true})

target_end()

target("wmarch")
    set_kind("static")
    set_plat("cross")
    set_arch("c-sky")
    set_targetdir("$(projectdir)/lib")

    add_files("platform/arch/**.c")
    add_files("platform/arch/**.S")
    add_includedirs("include",{public = true})
    add_includedirs("include/driver",{public = true})
    add_includedirs("include/os",{public = true})
    add_includedirs("include/arch/xt804",{public = true})
    add_includedirs("include/arch/xt804/csi_core",{public = true})

    after_load(function (target)
        for _, sourcebatch in pairs(target:sourcebatches()) do
            if sourcebatch.sourcekind == "as" then -- only asm files
                for idx, objectfile in ipairs(sourcebatch.objectfiles) do
                    sourcebatch.objectfiles[idx] = objectfile:gsub("%.S%.o", ".o")
                end
            end
        end
    end)

target_end()

target("blehost")
    set_kind("static")
    set_plat("cross")
    set_arch("c-sky")

    add_files("src/bt/blehost/**.c")
    add_includedirs(os.dirs(path.join(os.scriptdir(),"src/bt/blehost/**")))
    add_includedirs("src/app/bleapp",{public = true})
    add_includedirs("src/os/rtos/include",{public = true})
    add_includedirs("include",{public = true})
    add_includedirs("include/bt",{public = true})
    add_includedirs("include/platform",{public = true})
    add_includedirs("include/os",{public = true})
    add_includedirs("include/arch/xt804",{public = true})
    add_includedirs("include/arch/xt804/csi_core",{public = true})

target_end()

target("lvgl")
    set_kind("static")
    set_plat("cross")
    set_arch("c-sky")

    on_load(function (target)
        local conf_data = io.readfile("$(projectdir)/app/port/luat_conf_bsp.h")
        local LVGL_CONF = conf_data:find("\r#define LUAT_USE_LVGL") or conf_data:find("\n#define LUAT_USE_LVGL")
        if LVGL_CONF then target:set("default", true) else target:set("default", false) end
    end)

    add_files(luatos.."components/lvgl/**.c")

    add_includedirs("app/port",{public = true})
    add_includedirs("include",{public = true})
    add_includedirs(luatos.."lua/include",{public = true})
    add_includedirs(luatos.."luat/include",{public = true})
    add_includedirs(luatos.."components/lcd",{public = true})
    add_includedirs(luatos.."components/lvgl",{public = true})
    add_includedirs(luatos.."components/lvgl/binding",{public = true})
    add_includedirs(luatos.."components/lvgl/gen",{public = true})
    add_includedirs(luatos.."components/lvgl/src",{public = true})
    add_includedirs(luatos.."components/lvgl/font",{public = true})
    add_includedirs(luatos.."components/u8g2",{public = true})
    add_includedirs(luatos.."components/qrcode",{public = true})

    set_targetdir("$(buildir)/lib")
target_end()

target("u8g2")
    set_kind("static")
    set_plat("cross")
    set_arch("c-sky")

    add_files(luatos.."components/u8g2/*.c")

    add_includedirs("app/port",{public = true})
    add_includedirs("include",{public = true})
    add_includedirs(luatos.."lua/include",{public = true})
    add_includedirs(luatos.."luat/include",{public = true})
    add_includedirs(luatos.."components/u8g2",{public = true})
    add_includedirs(luatos.."components/gtfont")
    add_includedirs(luatos.."components/qrcode",{public = true})

    set_targetdir("$(buildir)/lib")
target_end()

target("air10x")
    -- set kind
    set_kind("binary")
    set_plat("cross")
    set_arch("c-sky")
    set_targetdir("$(buildir)/out")
    on_load(function (target)
        local conf_data = io.readfile("$(projectdir)/app/port/luat_conf_bsp.h")
        AIR10X_FLASH_FS_REGION_SIZE = conf_data:match("#define FLASH_FS_REGION_SIZE (%d+)")
        AIR10X_VERSION = conf_data:match("#define LUAT_BSP_VERSION \"(%w+)\"")
        local LVGL_CONF = conf_data:find("\r#define LUAT_USE_LVGL") or conf_data:find("\n#define LUAT_USE_LVGL")
        if LVGL_CONF then target:add("deps", "lvgl") end
        local custom_data = io.readfile("$(projectdir)/app/port/luat_conf_bsp.h")
        local TARGET_CONF = custom_data:find("#define AIR101")
        if TARGET_CONF == nil then TARGET_NAME = "AIR103" else TARGET_NAME = "AIR101" end
        local FDB_CONF = conf_data:find("\r#define LUAT_USE_FDB") or conf_data:find("\n#define LUAT_USE_FDB")

        local fs_size = AIR10X_FLASH_FS_REGION_SIZE and tonumber(AIR10X_FLASH_FS_REGION_SIZE) or 112
        if FDB_CONF or fs_size > 112 then
            local ld_data = io.readfile("./ld/"..TARGET_NAME..".ld")
            local I_SRAM_LENGTH = ld_data:match("I-SRAM : ORIGIN = 0x08010800 , LENGTH = 0x(%x+)")
            local sram_size = tonumber('0X'..I_SRAM_LENGTH)
            if FDB_CONF then
                sram_size = sram_size - 64*1024
            end
            if fs_size > 112 then
                sram_size = sram_size - (fs_size - 112) *1024
            end
            print("I_SRAM", sram_size // 1024)
            local I_SRAM_LENGTH_N = string.format("%X", sram_size)
            local ld_data_n = ld_data:gsub(I_SRAM_LENGTH,I_SRAM_LENGTH_N)
            io.writefile("./ld/air101_103.ld", ld_data_n)
        else
            os.cp("./ld/"..TARGET_NAME..".ld", "./ld/air101_103.ld")
        end

        target:set("filename", TARGET_NAME..".elf")
        target:add("ldflags", flto .. "-Wl,--gc-sections -Wl,-zmax-page-size=1024 -Wl,--whole-archive ./lib/libwmarch.a ./lib/libgt.a ./lib/libwlan.a ./lib/libdsp.a ./lib/libbtcontroller.a -Wl,--no-whole-archive -mcpu=ck804ef -nostartfiles -mhard-float -lm -Wl,-T./ld/air101_103.ld -Wl,-ckmap=./build/out/"..TARGET_NAME..".map ",{force = true})
    end)

    add_deps("app")
    -- add_deps("wmarch")
    add_deps("blehost")
    add_deps("u8g2")

    -- add files
    add_files("app/*.c")
    add_files("app/port/*.c")
    add_files("app/custom/*.c")
    add_files("platform/sys/*.c")
    add_files("platform/drivers/**.c")
    add_files("src/os/**.c")
    add_files("src/os/**.S")
    add_files("platform/common/**.c")

    add_includedirs("src/app/mbedtls/include",{public = true})
    add_includedirs("platform/arch",{public = true})
    add_includedirs("include/os",{public = true})
    add_includedirs("include/wifi",{public = true})
    add_includedirs("include/arch/xt804",{public = true})
    add_includedirs("include/arch/xt804/csi_core",{public = true})
    add_includedirs("include/app",{public = true})
    add_includedirs("include/net",{public = true})
    add_includedirs("demo",{public = true})
    add_includedirs("platform/inc",{public = true})

    add_includedirs("demo/console")
    add_includedirs("include/arch/xt804/csi_dsp")
    add_includedirs("platform/sys")
    add_includedirs("src/app/mbedtls/ports")
    add_includedirs("src/app/fatfs")

    add_files(luatos.."lua/src/*.c")
    add_files(luatos.."luat/modules/*.c")
    add_files(luatos.."luat/vfs/*.c")
    remove_files(luatos.."luat/vfs/luat_fs_posix.c")

    add_files(luatos.."components/lcd/*.c")
    add_files(luatos.."components/sfd/*.c")
    add_files(luatos.."components/nr_micro_shell/*.c")
    add_files(luatos.."components/luf/*.c")
    add_files(luatos.."components/eink/*.c")
    add_files(luatos.."components/epaper/*.c")
    remove_files(luatos.."components/epaper/GUI_Paint.c")
    add_files(luatos.."components/iconv/*.c")
    add_files(luatos.."components/lfs/*.c")
    add_files(luatos.."components/lua-cjson/*.c")
    add_files(luatos.."components/minmea/*.c")
    add_files(luatos.."luat/weak/*.c")

    add_includedirs(luatos.."lua/include",{public = true})
    add_includedirs(luatos.."luat/include",{public = true})
    add_includedirs(luatos.."components/lcd",{public = true})
    add_includedirs(luatos.."components/lvgl",{public = true})
    add_includedirs(luatos.."components/lvgl/binding",{public = true})
    add_includedirs(luatos.."components/lvgl/gen",{public = true})
    add_includedirs(luatos.."components/lvgl/src",{public = true})
    add_includedirs(luatos.."components/lvgl/font",{public = true})

    add_includedirs(luatos.."components/eink")
    add_includedirs(luatos.."components/epaper")
    add_includedirs(luatos.."components/iconv")
    add_includedirs(luatos.."components/lfs")
    add_includedirs(luatos.."components/lua-cjson")
    add_includedirs(luatos.."components/minmea")

    add_files(luatos.."components/sfud/*.c")
    add_includedirs(luatos.."components/sfud")

    add_files(luatos.."components/statem/*.c")
    add_includedirs(luatos.."components/statem")

    add_files(luatos.."components/coremark/*.c")
    add_includedirs(luatos.."components/coremark")

    add_files(luatos.."components/cjson/*.c")
    add_includedirs(luatos.."components/cjson")

    -- gtfont
    add_includedirs(luatos.."components/gtfont")
    add_files(luatos.."components/gtfont/*.c")

    add_files(luatos.."components/luatfonts/*.c")
    add_includedirs(luatos.."components/luatfonts")

    add_files(luatos.."components/zlib/*.c")
    add_includedirs(luatos.."components/zlib")

    add_files(luatos.."components/mlx90640-library/*.c")
    add_includedirs(luatos.."components/mlx90640-library")

    add_files(luatos.."components/i2c-tools/*.c")
    add_includedirs(luatos.."components/i2c-tools")

    add_files(luatos.."components/tjpgd/*.c")
    add_includedirs(luatos.."components/tjpgd")

    -- ble
    add_includedirs("src/app/bleapp", "src/bt/blehost/nimble/include", "src/bt/blehost/nimble/host/include", "include/bt")
    add_includedirs("src/bt/blehost/nimble/transport/uart/include", "src/bt/blehost/porting/xt804/include")
    add_includedirs("src/bt/blehost/ext/tinycrypt/include", "src/bt/blehost/nimble/host/util/include")

    add_includedirs(luatos.."components/nr_micro_shell")

    -- flashdb & fal
    add_includedirs(luatos.."components/fal/inc")
    add_files(luatos.."components/fal/src/*.c")
    add_includedirs(luatos.."components/flashdb/inc")
    add_files(luatos.."components/flashdb/src/*.c")

    -- shell & cmux
    add_includedirs(luatos.."components/shell",{public = true})
    add_includedirs(luatos.."components/cmux",{public = true})
    add_files(luatos.."components/shell/*.c")
    add_files(luatos.."components/cmux/*.c")

    -- ymodem
    add_includedirs(luatos.."components/ymodem",{public = true})
    add_files(luatos.."components/ymodem/*.c")

    -- qrcode
    add_includedirs(luatos.."components/qrcode",{public = true})
    add_files(luatos.."components/qrcode/*.c")

    -- lora
    add_includedirs(luatos.."components/lora",{public = true})
    add_files(luatos.."components/lora/**.c")

    -- c_common
    add_includedirs(luatos.."components/common",{public = true})
    add_files(luatos.."components/common/*.c")

    -- network
    add_includedirs(luatos.."components/network/adapter",{public = true})
    add_files(luatos.."components/network/adapter/*.c")

    -- w5500
    add_includedirs(luatos.."components/ethernet/common",{public = true})
    add_files(luatos.."components/ethernet/common/*.c")
    add_includedirs(luatos.."components/ethernet/w5500",{public = true})
    add_files(luatos.."components/ethernet/w5500/*.c")

	after_build(function(target)
        sdk_dir = target:toolchains()[1]:sdkdir().."/"
        os.exec(sdk_dir .. "bin/csky-elfabiv2-objcopy -O binary $(buildir)/out/"..TARGET_NAME..".elf $(buildir)/out/"..TARGET_NAME..".bin")
        io.writefile("$(buildir)/out/"..TARGET_NAME..".asm", os.iorun(sdk_dir .. "bin/csky-elfabiv2-objdump -d $(buildir)/out/"..TARGET_NAME..".elf"))
        io.writefile("$(buildir)/out/"..TARGET_NAME..".list", os.iorun(sdk_dir .. "bin/csky-elfabiv2-objdump -h -S $(buildir)/out/"..TARGET_NAME..".elf"))
        io.writefile("$(buildir)/out/"..TARGET_NAME..".size", os.iorun(sdk_dir .. "bin/csky-elfabiv2-size $(buildir)/out/"..TARGET_NAME..".elf"))
        io.cat("$(buildir)/out/"..TARGET_NAME..".size")
        -- if TARGET_NAME == "AIR101" then
        --     os.exec("./tools/xt804/wm_tool"..(is_plat("windows") and ".exe" or "").." -b $(buildir)/out/"..TARGET_NAME..".bin -fc 0 -it 1 -ih 8020000 -ra 8020400 -ua 8010000 -nh 0 -un 0 -vs G01.00.02 -o $(buildir)/out/"..TARGET_NAME.."")
        --     os.exec("./tools/xt804/wm_tool"..(is_plat("windows") and ".exe" or "").." -b  ./tools/xt804/xt804_secboot.bin -fc 0 -it 0 -ih 8002000 -ra 8002400 -ua 8010000 -nh 8020000 -un 0 -o ./tools/xt804/"..TARGET_NAME.."_secboot")
        -- elseif TARGET_NAME == "AIR103" then
            os.exec("./tools/xt804/wm_tool"..(is_plat("windows") and ".exe" or "").." -b $(buildir)/out/"..TARGET_NAME..".bin -fc 0 -it 1 -ih 8010400 -ra 8010800 -ua 8010000 -nh 0 -un 0 -vs G01.00.02 -o $(buildir)/out/"..TARGET_NAME.."")
            os.exec("./tools/xt804/wm_tool"..(is_plat("windows") and ".exe" or "").." -b  ./tools/xt804/xt804_secboot.bin -fc 0 -it 0 -ih 8002000 -ra 8002400 -ua 8010000 -nh 8010400 -un 0 -o ./tools/xt804/"..TARGET_NAME.."_secboot")
        -- end
        os.cp("./tools/xt804/"..TARGET_NAME.."_secboot.img", "$(buildir)/out/"..TARGET_NAME..".fls")
        local img = io.readfile("$(buildir)/out/"..TARGET_NAME..".img", {encoding = "binary"})
        local fls = io.open("$(buildir)/out/"..TARGET_NAME..".fls", "a+")
        if fls then fls:write(img) fls:close() end
        -- if is_mode("debug") then
        --     os.cd("./mklfs")
        --     os.exec("./luac_536_32bits.exe -s -o ./disk/main.luac ../main.lua")
        --     os.exec("./mklfs.exe -size 112")
        --     os.cd("../")
        --     os.mv("./mklfs/disk.fs", "$(buildir)/out/script.bin")
        --     if TARGET_NAME == "AIR101" then
        --         os.exec("./tools/xt804/wm_tool"..(is_plat("windows") and ".exe" or "").." -b  $(buildir)/out/script.bin -it 1 -fc 0 -ih 20008000 -ra 81E0000 -ua 0 -nh 0  -un 0 -o $(buildir)/out/script")
        --     else
        --         os.exec("./tools/xt804/wm_tool"..(is_plat("windows") and ".exe" or "").." -b  $(buildir)/out/script.bin -it 1 -fc 0 -ih 20008000 -ra 80E0000 -ua 0 -nh 0  -un 0 -o $(buildir)/out/script")
        --     end
        --     local script = io.readfile("$(buildir)/out/script.img", {encoding = "binary"})
        --     local fls = io.open("$(buildir)/out/"..TARGET_NAME..".fls", "a+")
        --     if fls then fls:write(script) fls:close() end
        -- elseif is_mode("release") then
            import("lib.detect.find_file")
            os.cp("$(buildir)/out/"..TARGET_NAME..".fls", "./soc_tools/"..TARGET_NAME..".fls")
            local path7z = nil
            if is_plat("windows") then
                path7z = "\"$(programdir)/winenv/bin/7z.exe\""
            elseif is_plat("linux") then
                path7z = find_file("7z", { "/usr/bin/"})
                if not path7z then
                    path7z = find_file("7zr", { "/usr/bin/"})
                end
            end
            if path7z then
                if AIR10X_FLASH_FS_REGION_SIZE then
                    print("AIR10X_FLASH_FS_REGION_SIZE",AIR10X_FLASH_FS_REGION_SIZE)
                    local info_data = io.readfile("./soc_tools/"..TARGET_NAME..".json")
                    local LVGL_CONF = info_data:gsub("\"size\" : 112\n","\"size\" : "..AIR10X_FLASH_FS_REGION_SIZE.."\n")
                    local offset,LVGL_JSON
                    if TARGET_NAME == "AIR101" then
                        offset = string.format("%X",0x81FC000-AIR10X_FLASH_FS_REGION_SIZE*1024)
                        LVGL_JSON = LVGL_CONF:gsub("\"offset\" : \"81E0000\",\n","\"offset\" : \""..offset.."\",\n")
                    else
                        offset = string.format("%X",0x80FC000-AIR10X_FLASH_FS_REGION_SIZE*1024)
                        LVGL_JSON = LVGL_CONF:gsub("\"offset\" : \"80E0000\",\n","\"offset\" : \""..offset.."\",\n")
                    end
                    io.writefile("./soc_tools/info.json", LVGL_JSON)
                else
                    print("AIR10X_FLASH_FS_REGION_SIZE", "default", 112)
                    os.cp("./soc_tools/"..TARGET_NAME..".json", "./soc_tools/info.json")
                end
                os.exec(path7z.." a -mx9 LuatOS-SoC_"..AIR10X_VERSION.."_"..TARGET_NAME..".7z ./soc_tools/air101_flash.exe ./soc_tools/info.json ./app/port/luat_conf_bsp.h ./soc_tools/"..TARGET_NAME..".fls")
                os.mv("LuatOS-SoC_"..AIR10X_VERSION.."_"..TARGET_NAME..".7z", "$(buildir)/out/LuatOS-SoC_"..AIR10X_VERSION.."_"..TARGET_NAME..".soc")
                os.rm("./soc_tools/info.json")
                os.rm("./soc_tools/"..TARGET_NAME..".fls")
            else
                print("7z not find")
                os.rm("./soc_tools/"..TARGET_NAME..".fls")
                return
            end
            
        -- end
        os.rm("./ld/air101_103.ld")
        -- os.exec("./tools/xt804/wm_tool"..(is_plat("windows") and ".exe" or "").." -b $(buildir)/out/AIR101.img -fc 1 -it 1 -ih 80D0000 -ra 80D0400 -ua 8010000 -nh 0 -un 0 -vs G01.00.02 -o $(buildir)/out/AIR101")
        -- os.mv("$(buildir)/out/AIR101_gz.img", "$(buildir)/out/AIR101_ota.img")
    end)
target_end()

