# mhchem Parser

[English](README.md)

mhchem 是一种用于排版化学方程式和物理单位的输入语法。

本项目是 [mhchemParser](https://github.com/mhchem/mhchemParser) v4.2.2 的 Dart/Flutter 移植版本，将 mhchem 语法转换为 LaTeX 语法，可用于 MathJax、KaTeX 等数学排版引擎的下游集成。

## 项目结构

```
mhchemParser/
├── js/                         # JavaScript/TypeScript 原始版本 (v4.2.2)
│   └── mhchemParser/
│       ├── src/                # TypeScript 源码
│       ├── dist/               # 编译后的 JS (UMD)
│       ├── esm/                # ES Module 版本
│       └── test/               # 测试文件
├── flutter/                    # Dart 移植版本
│   └── mhchemParser/
│       ├── lib/
│       │   ├── mhchem_parser.dart           # 对外导出入口
│       │   └── src/
│       │       ├── mhchem_parser.dart       # 公共 API
│       │       ├── mhchem_parser_core.dart  # 核心解析器 (状态机)
│       │       ├── mhchem_texify.dart       # LaTeX 渲染器
│       │       └── types.dart               # 类型定义
│       ├── test/
│       │   └── mhchem_parser_test.dart      # 测试用例
│       └── pubspec.yaml
└── README.md
```

## Dart 版本

### 环境要求

- Dart SDK: `>=2.17.0 <3.0.0`
- Flutter: `3.10.6`（兼容）
- 零第三方依赖

### 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  mhchem_parser:
    path: path/to/flutter/mhchemParser
```

### 使用方法

```dart
import 'package:mhchem_parser/mhchem_parser.dart';

// 化学方程式
String tex = MhchemParser.toTex('CO2 + C -> 2 CO', 'ce');

// 物理单位
String pu = MhchemParser.toTex('123 kJ*mol-1', 'pu');

// TeX 字符串（自动替换其中的 \ce 和 \pu）
String tex2 = MhchemParser.toTex(r'm_{\ce{H2O}}', 'tex');
```

### 支持的模式

| 模式   | 说明         | 示例输入              |
|--------|--------------|----------------------|
| `ce`   | 化学方程式    | `CO2 + C -> 2 CO`   |
| `pu`   | 物理单位      | `123 kJ*mol-1`      |
| `tex`  | TeX 透传模式  | `m_{\ce{H2O}}`      |

### 功能特性

- 化学方程式与化学式（元素、电荷、化学计量数）
- 反应箭头（`->`、`<->`、`<=>`、`<-->`等）
- 化学键（单键、双键、三键、芳香键等）
- 同位素与核素标记
- 氧化态（罗马数字）
- 聚集态标记（`(aq)`、`(s)`、`(g)`、`(l)`）
- 物理单位（SI 单位、科学计数法、千分位分隔）
- Kröger-Vink 记号
- 希腊字母
- 颜色标记

### 运行测试

```bash
cd flutter/mhchemParser
dart pub get
dart test
```

## 原始版本

JavaScript/TypeScript 原始版本的使用方法请参考 [mhchemParser 官方仓库](https://github.com/mhchem/mhchemParser)。

## 许可证

原始项目基于 [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0) 许可，版权归 Martin Hensel 所有（2015-2023）。

Dart 移植版本沿用相同许可证。
