#!/bin/bash

# Music Party 性能修复验证脚本
# 运行此脚本以验证所有修复是否正确应用

echo "=================================="
echo "Music Party 性能修复验证"
echo "=================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 验证计数
total_checks=0
passed_checks=0

# 验证函数
check_file() {
    local file=$1
    local pattern=$2
    local description=$3

    total_checks=$((total_checks + 1))

    if grep -q "$pattern" "$file" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $description"
        passed_checks=$((passed_checks + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $description"
        return 1
    fi
}

echo "【后端修复验证】"
echo ""

# 1. MusicPlayerService 并发安全
echo "1. 检查 MusicPlayerService 并发安全修复..."
check_file "src/main/java/org/thornex/musicparty/service/MusicPlayerService.java" \
    "private final AtomicBoolean playNextLock" \
    "  - AtomicBoolean playNextLock 已添加"

check_file "src/main/java/org/thornex/musicparty/service/MusicPlayerService.java" \
    "playNextLock.compareAndSet" \
    "  - CAS 锁逻辑已实现"

check_file "src/main/java/org/thornex/musicparty/service/MusicPlayerService.java" \
    "doFinally(signal -> playNextLock.set(false))" \
    "  - 锁释放逻辑已添加"

echo ""

# 2. WebSocket 广播限流
echo "2. 检查 WebSocket 广播限流..."
check_file "src/main/java/org/thornex/musicparty/service/MusicPlayerService.java" \
    "BROADCAST_THROTTLE_MS" \
    "  - 广播限流常量已定义"

check_file "src/main/java/org/thornex/musicparty/service/MusicPlayerService.java" \
    "lastBroadcastTime" \
    "  - 广播时间戳追踪已添加"

check_file "src/main/java/org/thornex/musicparty/service/MusicPlayerService.java" \
    "if (now - last < BROADCAST_THROTTLE_MS)" \
    "  - 限流检查逻辑已实现"

echo ""

# 3. 下载队列限流
echo "3. 检查下载队列限流..."
check_file "src/main/java/org/thornex/musicparty/service/LocalCacheService.java" \
    "MAX_QUEUE_SIZE = 256" \
    "  - 队列大小限制已设置"

check_file "src/main/java/org/thornex/musicparty/service/LocalCacheService.java" \
    "Queues.<DownloadTask>small().get()" \
    "  - 有界队列已启用"

check_file "src/main/java/org/thornex/musicparty/service/LocalCacheService.java" \
    "FAIL_OVERFLOW" \
    "  - 溢出处理已实现"

echo ""

# 4. ChatService 优化
echo "4. 检查 ChatService 历史记录优化..."
check_file "src/main/java/org/thornex/musicparty/service/ChatService.java" \
    "history.descendingIterator()" \
    "  - 迭代器优化已应用"

echo ""

# 5. MusicQueueManager 缓存
echo "5. 检查 MusicQueueManager 缓存优化..."
check_file "src/main/java/org/thornex/musicparty/service/MusicQueueManager.java" \
    "userSongsCache" \
    "  - 用户歌曲缓存已添加"

check_file "src/main/java/org/thornex/musicparty/service/MusicQueueManager.java" \
    "cacheInvalidated" \
    "  - 缓存失效标记已添加"

echo ""
echo "【前端修复验证】"
echo ""

# 6. 前端进度同步优化
echo "6. 检查前端进度同步优化..."
check_file "music-party-web/src/composables/useAudio.js" \
    "updateSyncInterval" \
    "  - 自适应同步间隔已实现"

check_file "music-party-web/src/composables/useAudio.js" \
    "document.hidden ? 2000 : 500" \
    "  - 前后台间隔区分已添加"

echo ""

# 7. AudioVisualizer 优化
echo "7. 检查 AudioVisualizer 渲染优化..."
check_file "music-party-web/src/logic/AudioVisualizer.js" \
    "navigator.hardwareConcurrency" \
    "  - 设备性能检测已添加"

check_file "music-party-web/src/logic/AudioVisualizer.js" \
    "isLowEnd" \
    "  - 低端设备适配已实现"

check_file "music-party-web/src/logic/AudioVisualizer.js" \
    "this.ringSegmentCount" \
    "  - 可变采样率已应用"

echo ""
echo "=================================="
echo "验证结果汇总"
echo "=================================="
echo -e "总计: $total_checks 项检查"
echo -e "通过: ${GREEN}$passed_checks${NC} 项"
echo -e "失败: ${RED}$((total_checks - passed_checks))${NC} 项"
echo ""

if [ $passed_checks -eq $total_checks ]; then
    echo -e "${GREEN}✓ 所有性能修复已正确应用！${NC}"
    echo ""
    echo "建议的下一步操作："
    echo "1. 运行单元测试: mvn test"
    echo "2. 编译项目: mvn clean package"
    echo "3. 启动应用并观察日志"
    echo "4. 使用 JMeter 进行压力测试"
    exit 0
else
    echo -e "${RED}✗ 部分修复未正确应用，请检查文件${NC}"
    echo ""
    echo "请检查以下文件是否正确修改："
    echo "- src/main/java/org/thornex/musicparty/service/MusicPlayerService.java"
    echo "- src/main/java/org/thornex/musicparty/service/LocalCacheService.java"
    echo "- src/main/java/org/thornex/musicparty/service/ChatService.java"
    echo "- src/main/java/org/thornex/musicparty/service/MusicQueueManager.java"
    echo "- music-party-web/src/composables/useAudio.js"
    echo "- music-party-web/src/logic/AudioVisualizer.js"
    exit 1
fi
