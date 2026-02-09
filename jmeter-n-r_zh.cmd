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

rem  ============================================
rem  JMETER.BAT 的非 GUI 远程分布式运行版本
rem
rem  将 JMX 文件拖放到此批处理脚本上，它将
rem  以非 GUI 模式运行，并触发远程服务器执行 (-r)
rem  日志文件基于输入文件名，扩展名为 .jtl
rem
rem  仅使用第一个参数。
rem
rem  ============================================

rem 检查是否提供了文件
if a == a%1 goto winNT2

rem 允许特殊名称 LAST
if LAST == %1 goto winNT3

rem 检查扩展名是否为 .jmx
if "%~x1" == ".jmx" goto winNT3
:winNT2
echo 请提供扩展名为 .jmx 的脚本名称
pause
goto END
:winNT3

rem 切换到脚本所在目录
pushd %~dp1

rem 使用同一目录查找 jmeter 脚本
rem 注意：这里多了 -r 参数，表示启动所有在 jmeter.properties 中定义的远程服务器 (remote_hosts)
call "%~dp0"jmeter -n -t "%~nx1" -j "%~n1.log" -l "%~n1.jtl" -r %2 %3 %4 %5 %6 %7 %8 %9

popd

:END
