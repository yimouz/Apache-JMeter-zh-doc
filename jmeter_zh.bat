@echo off
rem
rem Licensed to the Apache Software Foundation (ASF) under one or more
rem contributor license agreements.  See the NOTICE file distributed with
rem this work for additional information regarding copyright ownership.
rem The ASF licenses this file to you under the Apache License, Version 2.0
rem (the "License"); you may not use this file except in compliance with
rem the License.  You may obtain a copy of the License at
rem
rem http://www.apache.org/licenses/LICENSE-2.0
rem
rem Unless required by applicable law or agreed to in writing, software
rem distributed under the License is distributed on an "AS IS" BASIS,
rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
rem See the License for the specific language governing permissions and
rem limitations under the License.
rem

rem   =====================================================
rem   可以在外部定义的环境变量：
rem
rem   不要在此脚本中设置变量。而是将它们放入 JMETER_HOME/bin 中的
rem   setenv.bat 脚本中，以保持您的自定义设置独立。
rem
rem   DDRAW       - (可选) 影响 direct draw 使用的 JVM 选项，
rem                 例如 '-Dsun.java2d.ddscale=true'
rem
rem   JMETER_BIN  - JMeter bin 目录 (必须以 \ 结尾)
rem
rem   JMETER_COMPLETE_ARGS - 如果设置，表示将仅使用 JVM_ARGS，
rem                 而不是添加其他选项（如 HEAP 或 GC_ALGO）
rem
rem   JMETER_HOME - 安装目录。将根据 jmeter.bat 的位置进行猜测
rem
rem   JM_LAUNCH   - java.exe (默认) 或 javaw.exe
rem
rem   JM_START    - 将其设置为 'start ""' 以在单独的窗口中启动 JMeter
rem                 这是由 jmeterw.cmd 脚本使用的。
rem
rem   JVM_ARGS    - (可选) 启动 JMeter 时使用的 Java 选项，例如 -Dprop=val
rem                 默认为 '-Duser.language="en" -Duser.region="EN"'
rem
rem   GC_ALGO     - (可选) JVM 垃圾收集器选项
rem                 默认为 '-XX:+UseG1GC -XX:MaxGCPauseMillis=100 -XX:G1ReservePercent=20'
rem
rem   HEAP        - (可选) 启动 JMeter 时使用的 JVM 内存设置
rem                 默认为 '-Xms1g -Xmx1g -XX:MaxMetaspaceSize=256m'
rem
rem   =====================================================

setlocal

rem 如果未定义，则猜测 JMETER_HOME
set "CURRENT_DIR=%cd%"
if not "%JMETER_HOME%" == "" goto gotHome
set "JMETER_HOME=%CURRENT_DIR%"
if exist "%JMETER_HOME%\bin\jmeter.bat" goto okHome
cd ..
set "JMETER_HOME=%cd%"
cd "%CURRENT_DIR%"
if exist "%JMETER_HOME%\bin\jmeter.bat" goto okHome
set "JMETER_HOME=%~dp0\.."
:gotHome

if exist "%JMETER_HOME%\bin\jmeter.bat" goto okHome
echo JMETER_HOME 环境变量未正确定义
echo 需要此环境变量来运行此程序
goto end
:okHome

rem 获取标准环境变量
if exist "%JMETER_HOME%\bin\setenv.bat" call "%JMETER_HOME%\bin\setenv.bat"

if not defined JMETER_LANGUAGE (
    rem 设置语言
    rem 默认为 en_EN
    set JMETER_LANGUAGE=-Duser.language="en" -Duser.region="EN"
)

rem 运行 JMeter 的最低版本
set MINIMAL_VERSION=1.8.0


rem --add-opens 如果是 JAVA 9
set JAVA9_OPTS=


for /f "tokens=3" %%g in ('java -version 2^>^&1 ^| findstr /i "version"') do (
    rem @echo Debug Output: %%g
    set JAVAVER=%%g
)
if not defined JAVAVER (
    @echo 无法找到 Java 可执行文件或版本。请检查您的 Java 安装。
    set ERRORLEVEL=2
    goto pause
)



rem 检查版本是否来自 OpenJDK 或 Oracle Hotspot JVM（9 之前的版本包含 1.${version}.x）
rem 对于 Oracle Java 9，JAVAVER 将等于 "9.0.4"（引号是值的一部分）
rem 对于 Oracle Java 8，JAVAVER 将等于 "1.8.0_161"（引号是值的一部分）
rem 所以我们要从索引 1 开始提取 2 个字符
IF "%JAVAVER:~1,2%"=="1." (
    set JAVAVER=%JAVAVER:"=%
    for /f "delims=. tokens=1-3" %%v in ("%JAVAVER%") do (
        set current_minor=%%w
)
) else (
    rem 至少是 Java 9
    set current_minor=9
    set JAVA9_OPTS=--add-opens java.desktop/sun.awt=ALL-UNNAMED --add-opens java.desktop/sun.swing=ALL-UNNAMED --add-opens java.desktop/javax.swing.text.html=ALL-UNNAMED --add-opens java.desktop/java.awt=ALL-UNNAMED --add-opens java.desktop/java.awt.font=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.lang.invoke=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.text=ALL-UNNAMED --add-opens=java.desktop/sun.awt.shell=ALL-UNNAMED
)


for /f "delims=. tokens=1-3" %%v in ("%MINIMAL_VERSION%") do (
    set minimal_minor=%%w
)

if not defined current_minor (
    @echo 无法找到 Java 可执行文件或版本。请检查您的 Java 安装。
    set ERRORLEVEL=2
    goto pause
)
rem @echo Debug: CURRENT=%current_minor% - MINIMAL=%minimal_minor%
if %current_minor% LSS %minimal_minor% (
    @echo 错误: Java 版本 -- %JAVAVER% -- 太低，无法运行 JMeter。需要 Java 版本大于或等于 %MINIMAL_VERSION%
    set ERRORLEVEL=3
    goto pause
)

if not defined JM_LAUNCH (
    set JM_LAUNCH=java.exe
)

if exist jmeter.bat goto winNT1
if not defined JMETER_BIN (
    set JMETER_BIN=%~dp0
)

:winNT1
rem 在 NT/2K 上一次性获取所有参数
set JMETER_CMD_LINE_ARGS=%*

rem 以下链接描述了 -XX 选项：
rem http://docs.oracle.com/javase/8/docs/technotes/tools/unix/java.html

if not defined HEAP (
    rem 有关以下参数的基本原理，请参阅 unix 启动文件，
    rem 包括一些调整建议
    set HEAP=-Xms1g -Xmx1g -XX:MaxMetaspaceSize=256m
)

rem 取消注释此行以使用 Java 9 之前的版本生成 GC 详细文件
rem set VERBOSE_GC=-verbose:gc -Xloggc:gc_jmeter_%%p.log -XX:+PrintGCDetails -XX:+PrintGCCause -XX:+PrintTenuringDistribution -XX:+PrintHeapAtGC -XX:+PrintGCApplicationConcurrentTime -XX:+PrintGCApplicationStoppedTime -XX:+PrintGCDateStamps -XX:+PrintAdaptiveSizePolicy

rem 取消注释此行以使用 Java 9 及更高版本生成 GC 详细文件
rem set VERBOSE_GC=-Xlog:gc*,gc+age=trace,gc+heap=debug:file=gc_jmeter_%%p.log
rem 您可能想要添加这些设置
rem -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem
if not defined GC_ALGO (
    set GC_ALGO=-XX:+UseG1GC -XX:MaxGCPauseMillis=100 -XX:G1ReservePercent=20
)

set SYSTEM_PROPS=-Djava.security.egd=file:/dev/urandom

rem 始终在 OOM 时转储（除非触发，否则不消耗任何东西）
set DUMP=-XX:+HeapDumpOnOutOfMemoryError

rem 如果您在 DOCKER 中运行 JMeter（需要 Java SE 8u131 或 JDK 9），请取消注释此行
rem 参见 https://blogs.oracle.com/java-platform-group/java-se-support-for-docker-cpu-and-memory-limits
rem set RUN_IN_DOCKER=-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap

rem 其他设置可能有助于提高某些平台上的 GUI 性能
rem 参见：http://www.oracle.com/technetwork/java/perf-graphics-135933.html

if not defined DDRAW (
    set DDRAW=
    rem  将此标志设置为 true 会关闭 DirectDraw 使用，这有时有助于摆脱 Win32 上的许多渲染问题。
    rem set DDRAW=%DDRAW% -Dsun.java2d.noddraw=true

    rem  将此标志设置为 false 会通过强制所有 createVolatileImage 调用变为 createImage 调用来关闭 DirectDraw 离屏表面加速，并禁用对使用 createImage 创建的表面执行的隐藏加速。
    rem set DDRAW=%DDRAW% -Dsun.java2d.ddoffscreen=false

    rem 将此标志设置为 true 启用硬件加速缩放。
    rem set DDRAW=%DDRAW% -Dsun.java2d.ddscale=true
)

rem 收集上面定义的设置
if not defined JMETER_COMPLETE_ARGS (
    set ARGS=%JAVA9_OPTS% %DUMP% %HEAP% %VERBOSE_GC% %GC_ALGO% %DDRAW% %SYSTEM_PROPS% %JMETER_LANGUAGE% %RUN_IN_DOCKER%
) else (
    set ARGS=
)

if "%JM_START%" == "start" (
    set JM_START=start "Apache_JMeter"
)

%JM_START% "%JM_LAUNCH%" %ARGS% %JVM_ARGS% -jar "%JMETER_BIN%ApacheJMeter.jar" %JMETER_CMD_LINE_ARGS%

rem 如果 errorlevel 不为零，则显示它并暂停

if NOT errorlevel 0 goto pause
if errorlevel 1 goto pause

goto end

:pause
echo errorlevel=%ERRORLEVEL%
pause

:end
