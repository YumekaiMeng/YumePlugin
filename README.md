# YumePlugin README
- 适用于 LyraVoid 旗下 FinaSU 和 FolkPatch 管理器的插件仓库，针对 Aster ，YukiSU 等兼容 Lua 插件的管理器兼容性仍需测试
- 已上传至 FinaSU 官方仓库

## module_unloader
- 自动按照/data/adb/plugins/module_unloader/main.lua中的MODULE列表卸载内核模块
- 默认配置为卸载OPPO的安全模块解决ksud被频繁杀死问题
- ODDO的模块似乎不会自动重载，移除了每30min重新卸载一次，降低性能开销

## boot-script
- 在指定的启动阶段执行自定义命令
- 修复了对Lua5.4或更高版本的兼容性
