#!/usr/bin/env python3
"""
EA 代码静态检查工具
检查常见的配置和代码问题
"""

import json
import re
from pathlib import Path


class SanityChecker:
    """EA 代码检查器"""
    
    def __init__(self, project_root):
        self.project_root = Path(project_root)
        self.errors = []
        self.warnings = []
    
    def check_config_files(self):
        """检查配置文件"""
        print("Checking config files...")
        
        # 检查 params.default.json
        params_file = self.project_root / "config" / "params.default.json"
        if not params_file.exists():
            self.errors.append("Missing config/params.default.json")
            return
        
        with open(params_file) as f:
            params = json.load(f)
        
        # 检查风险参数
        risk = params.get("risk", {})
        risk_pct = risk.get("risk_per_trade_percent", 0)
        if risk_pct > 0.5:
            self.warnings.append(f"Risk per trade is {risk_pct}% (>0.5%)")
        
        max_dd = risk.get("max_drawdown_percent", 0)
        if max_dd > 10:
            self.warnings.append(f"Max drawdown is {max_dd}% (>10%)")
        
        print(f"  Config checks: {len(self.warnings)} warnings")
    
    def check_hard_coded_values(self):
        """检查硬编码的风险参数"""
        print("Checking for hard-coded values...")
        
        src_dir = self.project_root / "src"
        if not src_dir.exists():
            return
        
        # 搜索 .mq4 和 .mq5 文件
        for mq_file in src_dir.rglob("*.mq[45]"):
            with open(mq_file) as f:
                content = f.read()
            
            # 检查是否有硬编码的 lot size
            if re.search(r'OrderSend\s*\([^,]*,\s*\d+\.\d+', content):
                self.warnings.append(
                    f"{mq_file.name}: Possible hard-coded lot size in OrderSend"
                )
        
        print(f"  Hard-coded checks: {len(self.warnings)} warnings")
    
    def check_repainting_indicators(self):
        """检查可能的重绘指标"""
        print("Checking for repainting indicators...")
        
        indicators_dir = self.project_root / "src" / "indicators"
        if not indicators_dir.exists():
            return
        
        for ind_file in indicators_dir.rglob("*.mq[45]"):
            with open(ind_file) as f:
                content = f.read()
            
            # 检查是否使用了未来数据
            if "IndicatorCounted()" not in content and "prev_calculated" not in content:
                self.warnings.append(
                    f"{ind_file.name}: Missing proper buffer calculation (possible repainting)"
                )
        
        print(f"  Repainting checks: {len(self.warnings)} warnings")
    
    def check_logging(self):
        """检查日志记录"""
        print("Checking logging...")
        
        src_dir = self.project_root / "src"
        if not src_dir.exists():
            return
        
        for mq_file in src_dir.rglob("*.mq[45]"):
            with open(mq_file) as f:
                content = f.read()
            
            # 检查 OrderSend 是否有日志
            if "OrderSend" in content and "Print" not in content:
                self.warnings.append(
                    f"{mq_file.name}: OrderSend without logging"
                )
        
        print(f"  Logging checks: {len(self.warnings)} warnings")
    
    def run_all_checks(self):
        """运行所有检查"""
        print("="*60)
        print("Running EA Sanity Checks")
        print("="*60)
        
        self.check_config_files()
        self.check_hard_coded_values()
        self.check_repainting_indicators()
        self.check_logging()
        
        print("\n" + "="*60)
        print("SUMMARY")
        print("="*60)
        print(f"Errors: {len(self.errors)}")
        print(f"Warnings: {len(self.warnings)}")
        
        if self.errors:
            print("\nERRORS:")
            for error in self.errors:
                print(f"  ❌ {error}")
        
        if self.warnings:
            print("\nWARNINGS:")
            for warning in self.warnings:
                print(f"  ⚠️  {warning}")
        
        if not self.errors and not self.warnings:
            print("\n✅ All checks passed!")
        
        return len(self.errors) == 0


def main():
    """主函数"""
    import sys
    
    project_root = sys.argv[1] if len(sys.argv) > 1 else "."
    checker = SanityChecker(project_root)
    success = checker.run_all_checks()
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()

