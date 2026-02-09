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

rem   ===============================================================
rem   环境变量说明
rem   SERVER_PORT (可选) - 定义 rmiregistry 和服务器端口
rem
rem   JVM_ARGS - Java 标志参数 - 这些由 jmeter.bat 处理
rem
rem   ===============================================================


REM 保护环境免受更改
setlocal

if exist jmeter-server.bat goto winNT1
echo 正在切换到 JMeter 主目录
cd /D %~dp0
:winNT1

if exist %JMETER_HOME%\lib\ext\ApacheJMeter_core.jar goto setCP
echo 找不到 ApacheJmeter_core.jar ...
REM 尝试推断 JMETER_HOME
echo ... 尝试 JMETER_HOME=..
set JMETER_HOME=..
if exist %JMETER_HOME%\lib\ext\ApacheJMeter_core.jar goto setCP
echo ... 尝试 JMETER_HOME=.
set JMETER_HOME=.
if exist %JMETER_HOME%\lib\ext\ApacheJMeter_core.jar goto setCP
echo 无法确定 JMETER_HOME !
goto exit

:setCP
echo 找到 ApacheJMeter_core.jar

REM 不再需要创建 rmiregistry，因为它由服务器完成
REM set CLASSPATH=%JMETER_HOME%\lib\ext\ApacheJMeter_core.jar;%JMETER_HOME%\lib\jorphan.jar

REM START rmiregistry %SERVER_PORT%
REM

rem 在 NT/2K 上一次性获取所有参数
set JMETER_CMD_LINE_ARGS=%*

if not "%SERVER_PORT%" == "" goto port

rem 启动 JMeter 服务器模式 (-s) 并记录日志到 jmeter-server.log
call jmeter -s -j jmeter-server.log %JMETER_CMD_LINE_ARGS%
goto end


:port
rem 如果指定了端口，使用 -Dserver_port 参数启动
call jmeter -Dserver_port=%SERVER_PORT% -s -j jmeter-server.log %JMETER_CMD_LINE_ARGS%

:end

rem 不再需要，因为服务器是在进程内启动的
rem taskkill /F /IM rmiregistry.exe

:exit
