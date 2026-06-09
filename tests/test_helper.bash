# tests/test_helper.bash
# Подключается из каждого .bats файла через: load 'test_helper'

PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
LIB_DIR="$PROJECT_ROOT/lib"
ADAPTERS_DIR="$PROJECT_ROOT/adapters"
FIXTURES_DIR="$PROJECT_ROOT/tests/fixtures"

# Подавляем цвета в не-TTY
export NO_COLOR=1
