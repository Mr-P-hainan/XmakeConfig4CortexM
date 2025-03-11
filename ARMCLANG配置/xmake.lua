ProjectName = "LED" -- 项目名字
ArmCore = "cortex-m4" -- arm 内核版本

-- 判断内核版本并设置对应的浮点单元参数
if ArmCore == "cortex-m4" then
    FloatVer = "fpv4-sp-d16"
    CPUVer = "Cortex-M4"
elseif ArmCore == "cortex-m7" then
    FloatVer = "fpv5-d16"
    CPUVer = "Cortex-M7"
else
    FloatVer = "NULL"
    CPUVer = "NULL"
end

-- 设置工具链
toolchain("armclang")
    set_description("ARM Compiler Version 6 of Keil MDK")

    set_kind("binary")

    set_toolset("cc", "armclang")
    set_toolset("cxx", "armclang")
    set_toolset("ld", "armlink")
    set_toolset("ar", "armar")
    set_toolset("as", "armclang")

    on_load(function (toolchain)
        -- 直接设置sdk路径
        toolchain:config_set("sdkdir", "D:/PersonalSoftware/Keil5/Arm/ARM/ARMCLANG")
        toolchain:configs_save()
        return true
    end)

    on_load(function (toolchain)
        toolchain:add("cxflags", "--target=arm-arm-none-eabi")
        toolchain:add("cxflags", "-mcpu=" .. ArmCore)
        toolchain:add("ldflags", "--cpu " .. CPUVer..".fp.dp")
        toolchain:add("asflags", "--target=arm-arm-none-eabi")
        toolchain:add("asflags", "-mcpu=" .. ArmCore)
    end)
toolchain_end()

-- 设置编译目标
target(ProjectName)
    set_filename(ProjectName .. ".axf") -- Armclang 生成的文件扩展名通常为 .axf
    set_kind("binary")
    set_toolset("target","arm-arm-none-eabi")
    set_arch(ArmCore)
    set_toolchains("armclang") -- 设置使用 armclang 工具链
    set_warnings("all")
    set_targetdir("./build")

    add_defines(
        "AT32F437ZGT7",         --设置芯片型号
        "USE_STDPERIPH_DRIVER"  --设置驱动类型
    )

    -- 设置源文件位置
    add_files(
        -- 源文件列表
        "BSP/**.c",
        "libraries/**.c",
        "Src/**.c",
        "startup_at32f435_437.s"
    )

    -- 设置头文件搜索路径
    add_includedirs(
        -- 头文件路径
        "Inc",
        "libraries/cmsis/cm4/core_support",
        "BSP/led",
        "libraries/cmsis/cm4/device_support",
        "libraries/drivers/inc"
    )

    -- 设置 C 编译参数
    add_cflags(
        "-Os",               -- 设置优化等级，启用最高的优化级别，包括 -O3 以及一些额外的可能影响兼容性的优化
        "-std=c99",             -- 指定 C 语言标准为 C99
        "-fno-rtti",            -- 禁用 RTTI（运行时类型信息），减少代码体积和提高性能
        "-funsigned-char",      -- 将 char 类型设置为无符号类型
        "-fshort-enums",        -- 将枚举类型存储在最短的整数类型中，减少内存占用
        "-fshort-wchar",        -- 将 wchar_t 类型设置为 16 位，减少内存占用
        "-gdwarf-4",            -- 指定生成 DWARF 格式的调试信息，版本为 4
        "-mfpu=" .. FloatVer,   -- 指定使用的浮点运算单元版本，FloatVer 是一个变量，表示具体的浮点版本
        "-mfloat-abi=hard",     -- 指定使用硬件浮点 ABI，提高浮点运算性能
        "-ffunction-sections",  -- 将每个函数放入单独的段中，有助于链接时优化
        "-xc",                  -- 指定编译器以 C 语言模式编译
        "-Wno-packed",          -- 禁用对 packed 属性的警告
        "-Wno-missing-variable-declarations", -- 禁用对未声明变量的警告
        "-Wno-missing-prototypes", -- 禁用对缺失原型的警告
        "-Wno-missing-noreturn", -- 禁用对缺失 noreturn 属性的警告
        "-Wno-sign-conversion", -- 禁用符号转换警告
        "-Wno-nonportable-include-path", -- 禁用对非可移植包含路径的警告
        "-Wno-reserved-id-macro", -- 禁用对保留标识符宏的警告
        "-Wno-unused-macros",   -- 禁用对未使用宏的警告
        "-Wno-documentation-unknown-command", -- 禁用对未知文档命令的警告
        "-Wno-documentation",   -- 禁用对文档相关的警告
        "-Wno-license-management", -- 禁用对许可证管理的警告
        "-Wno-parentheses-equality", -- 禁用对括号等式比较的警告
        "-Wno-reserved-identifier", -- 禁用对保留标识符的警告
        "-flto",--链接时优化
    { force = true }        -- 强制应用这些编译选项，覆盖默认设置
    )
    -- 设置汇编编译参数
    add_asflags(
        "-g",                   -- 生成调试信息
        "-masm=auto",           -- 自动选择汇编器模式
    { force = true }        -- 强制应用这些汇编选项，覆盖默认设置
    )
    -- 设置链接参数
    add_ldflags(
        "-flto",--链接时优化
        "--apcs=interwork",     -- 设置 APCS（ARM Procedure Call Standard）选项，启用 interwork（混合 ARM 和 Thumb 模式）
        "--info summarysizes",  -- 输出链接总结信息，包括各模块大小
        "--info totals",        -- 输出链接总信息，包括总大小等
    { force = true }        -- 强制应用这些链接选项，覆盖默认设置
    )

target_end()

-- 构建完成后的回调函数
after_build(function(target)
    os.exec("D:/PersonalSoftware/Keil5/Arm/ARM/ARMCLANG/bin/fromelf.exe --bin --output=./build/%s.bin ./build/%s.axf", target:name(), target:name())
    os.exec("D:/PersonalSoftware/Keil5/Arm/ARM/ARMCLANG/bin/fromelf.exe --elf --output=./build/%s.elf ./build/%s.axf", target:name(), target:name())
    print("生成已完成!")
    print("********************STORAGE_USAGE*****************************")
    os.exec("size ./build/%s.axf", target:name())
    print("********************STORAGE_USAGE*****************************")
end)