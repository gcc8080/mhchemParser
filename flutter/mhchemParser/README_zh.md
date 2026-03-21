# mhchem_parser

[English](README.md)

[mhchemParser](https://github.com/mhchem/mhchemParser) v4.2.2 的 Dart 移植版本 — 将 mhchem 语法转换为 LaTeX 语法，支持化学方程式和物理单位。

## 功能特性

- **化学方程式** (`\ce`)：元素、电荷、化学计量数、同位素、反应箭头、化学键、氧化态、Kröger-Vink 记号等
- **物理单位** (`\pu`)：SI 单位、科学计数法、千分位分隔、温度单位等
- **TeX 透传** (`tex`)：自动替换 TeX 字符串中的 `\ce{...}` 和 `\pu{...}`
- 零第三方依赖，纯 Dart 实现

## 环境要求

- Dart SDK: `>=2.17.0 <3.0.0`

## 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  mhchem_parser:
    path: path/to/this/directory
```

## 使用方法

```dart
import 'package:mhchem_parser/mhchem_parser.dart';

// 化学方程式
MhchemParser.toTex('CO2 + C -> 2 CO', 'ce');
// → {\mathrm{CO}{\vphantom{A}}_{\smash[t]{2}} {}+{} \mathrm{C} {}\mathrel{\longrightarrow}{} 2\,\mathrm{CO}}

// 物理单位
MhchemParser.toTex('123 kJ*mol-1', 'pu');
// → {123~\mathrm{kJ}\mkern1mu{\cdot}\mkern1mu \mathrm{mol^{-1}}}

// TeX 字符串（自动替换 \ce / \pu）
MhchemParser.toTex(r'm_{\ce{H2O}}', 'tex');
```

## API

### `MhchemParser.toTex(String input, String type) → String`

| 参数    | 说明 |
|---------|------|
| `input` | 待解析的 mhchem 语法字符串 |
| `type`  | `'ce'`（化学方程式）、`'pu'`（物理单位）或 `'tex'`（TeX 透传） |

返回 LaTeX 字符串。

## 运行测试

```bash
dart pub get
dart test
```

## 许可证

基于 Martin Hensel 的 [mhchemParser](https://github.com/mhchem/mhchemParser)，采用 [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0) 许可。
