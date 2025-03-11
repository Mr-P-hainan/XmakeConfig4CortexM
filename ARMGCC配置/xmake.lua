ProjectName = "LED"--项目名字
LinkScript = "AT32F437xG_FLASH.ld"--ld文件的相对位置
ArmCore = "cortex-m4"--arm内核版本
MCUModel = "AT32F437ZGT7"--MCU型号
FloatVer = "NULL"

-- 判断内核版本并设置对应的浮点单元参数
if ArmCore == "cortex-m4" then
    FloatVer = "fpv4-sp-d16"
elseif ArmCore == "cortex-m7" then
    FloatVer = "fpv5-d16"
else
    -- 如果是其他内核，可以在这里添加其他情况的处理
    -- 或者保持默认值 "xxxx"
    FloatVer = "NULL"
end

-- 设置工具链
toolchain("arm-none-eabi")
    set_kind("standalone")
    --交叉编译工具路径
    set_sdkdir("D:/Compiler/arm-eabi-gcc13.3.1")
toolchain_end()


-- 设置编译目标
target(ProjectName)
    -- 设置生成的文件名称
    set_filename(ProjectName .. ".elf")
    -- 设置编译链
    set_toolchains("arm-none-eabi") 
    -- 生成二进制文件
    set_kind("binary")
    -- 启用所有警告
    set_warnings("all")
    -- 设置优化等级
--     Value	    Description	              gcc/clang	    msvc
--     none	        disable optimization	    -O0	        -Od
--     fast	        quick optimization	        -O1	        default
--     faster	    faster optimization	        -O2	        -O2
--     fastest	    Optimization of the
--                  fastest running speed	    -O3	        -Ox -fp:fast
--     smallest	    Minimize code optimization	-Os	        -O1 -GL
--     aggressive	over-optimization	        -Ofast	    -Ox -fp:fast

    set_optimize("smallest")
    -- 设置编译文件的目录
    set_targetdir("./build")
    
    -- 设置源文件位置
    add_files(
        "BSP/**.c",
        "libraries/**.c",
        "Src/**.c",
        "startup_at32f435_437.s"
    )
    
    -- 设置头文件搜索路径
    add_includedirs(
        "Inc",
        "libraries/cmsis/cm4/core_support",
        "BSP/led",
        "libraries/cmsis/cm4/device_support",
        "libraries/drivers/inc"
    )
    
    -- 添加宏定义(一般为芯片系列或型号)
    add_defines(
        MCUModel,
        "USE_STDPERIPH_DRIVER"
    )
    

    -- 设置C编译参数
    add_cflags(
        "-xc",
        "-Wno-invalid-source-encoding",--忽略无效的源码编码警告
        "-mcpu=" .. ArmCore, --指定目标处理器的 CPU 架构为 Cortex-M4
        "-mthumb", --启用 Thumb 指令集
        "-mthumb-interwork",--设置APCS（ARM程序调用标准）为Thumb-ARM互工作模式
        "-std=c99",--设置C语言标准为C99
        "-mfloat-abi=hard",--指定浮点运算的 ABI（Application Binary Interface）为硬件浮点
        "-mfpu="..FloatVer, --指定使用 fpv4-sp-d16 浮点单元。
        "-fdata-sections -ffunction-sections", --将数据段和函数放置在独立的小节中。这样可以实现对未使用代码和数据的剔除，减少生成的可执行文件大小。
        "--specs=nano.specs --specs=nosys.specs", --加载特定的 C 库规范
        "-funsigned-char",--将char类型视为无符号
        "-fshort-enums",--将枚举类型存储在最短的整数类型中
        "-gdwarf-4",--指定生成调试信息时采用DWARF第4版的格式。
        { force = true } --强制覆盖之前的编译参数设置。
    )
    
    -- 设置汇编编译参数
    add_asflags(
        "-mcpu=" .. ArmCore, --指定目标处理器的 CPU 架构为 Cortex-M4
        "-mthumb", --启用 Thumb 指令集
        "-mthumb-interwork",--设置APCS（ARM程序调用标准）为Thumb-ARM互工作模式
        "-g", --调试信息
        "-mfloat-abi=hard -mfpu="..FloatVer, --指定浮点运算的 ABI（Application Binary Interface）为硬件浮点，同时指定使用 fpv4-sp-d16 浮点单元。
        "-fdata-sections -ffunction-sections", --将数据段和函数放置在独立的小节中。这样可以实现对未使用代码和数据的剔除，减少生成的可执行文件大小。
        { force = true }
    )
    
    -- 设置链接参数
    local MapCMD = "-Wl,-Map=" .. ProjectName .. ".map,--cref,--print-memory-usage"
    add_ldflags(
        "-mcpu=" .. ArmCore,
        "-mthumb",
        "-mthumb-interwork",--设置APCS（ARM程序调用标准）为Thumb-ARM互工作模式
        "-mfloat-abi=hard",
        "-mfpu="..FloatVer,
        "-specs=nosys.specs", -- 使用 'nosys.specs' 而不是 'nano.specs'，以避免对某些系统调用的未定义引用
        "-T".. LinkScript ,
        "-u _printf_float", --定义一个弱符号 _printf_float，用于处理浮点数的打印输出（printf）。这样的处理可能在使用浮点数格式化输出时需要。
        "-lc -lm -lnosys", --链接 C 标准库和 math 库（libm），同时取消对系统调用的链接依赖。
        MapCMD,
        { force = true }
    )

target_end()

--构建完成后的回调函数
after_build(function(target)
    os.exec("arm-none-eabi-objcopy -O ihex ./build/%s.elf ./build/%s.hex", target:name(), target:name())
    os.exec("arm-none-eabi-objcopy -O binary ./build/%s.elf ./build/%s.bin", target:name(), target:name())
    print("Build Complete!")
    print("********************STORAGE_USAGE*****************************")
    os.exec("arm-none-eabi-size -Bd ./build/%s.elf", target:name())
    print("********************STORAGE_USAGE*****************************")
end)