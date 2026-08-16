# mhchem_parser

[English](README.md)

零第三方运行时依赖、纯 Dart 的 mhchemParser 4.2.2 移植版；固定的 117 条官方用例必须逐字符一致。

## 兼容性

- Dart 包版本：`0.1.0`
- 上游兼容版本：`4.2.2`
- 上游提交：`acaf5adb97a08deb234e0a8d62c807c17ee650d6`
- Dart SDK：`>=3.6.0 <4.0.0`
- 已验证下游基线：Flutter `3.27.4`
- 运行时依赖：无

Dart 包版本描述本移植版自身，不替代独立的上游兼容版本。

## 安装

请固定不可变 tag 或完整提交 SHA：

```yaml
dependencies:
  mhchem_parser:
    git:
      url: https://github.com/gcc8080/mhchemParser.git
      ref: <approved-release-tag-or-full-commit-sha>
      path: flutter/mhchemParser
```

## 使用

```dart
import 'package:mhchem_parser/mhchem_parser.dart';

final equation = MhchemParser.convert(
  'CO2 + C -> 2 CO',
  mode: MhchemMode.ce,
);
final unit = MhchemParser.convert(
  '123 kJ*mol-1',
  mode: MhchemMode.pu,
);
final onePassTex = MhchemParser.convert(
  r'm_{\ce{H2O}}',
  mode: MhchemMode.tex,
);
final expandedTex = MhchemParser.expandAllTex(
  r'\ce{$\underset{x}{\ce{H2O}}$}',
);
```

### 模式

| 值 | 输入 |
|---|---|
| `MhchemMode.ce` | 化学方程式和化学式 |
| `MhchemMode.pu` | 物理单位 |
| `MhchemMode.tex` | 含 `\ce`、`\pu` 的 TeX |

`convert` 始终只执行一次转换并保留精确上游输出。`expandAllTex` 默认最多执行 16 次；如果不能证明展开完成，则抛出 `MhchemExpansionException`，原因是 `MhchemExpansionFailure.passLimit` 或 `.noProgress`。

`MhchemParser.toTex(String input, String type)` 已废弃并委托给类型安全 API，但会保留整个 `0.x`，最早只能在 `1.0.0` 移除。

## 输出契约

官方语料输出必须与固定 JavaScript oracle 逐字符一致。解析包会保留渲染器扩展命令，不会做子集归一化；具体渲染支持属于下游职责。

JavaScript 基线和 Node 验证工具只用于仓库测试，不是运行时依赖，也不会被本包导入。

## 测试

```sh
dart pub get
dart format --output=none --set-exit-if-changed lib test
dart analyze --fatal-infos
dart test
dart pub publish --dry-run
```

仓库级来源与一致性命令见 [`UPSTREAM.md`](../../UPSTREAM.md)。

## 发布状态

本变更只准备 `0.1.0` 内容，不代表已创建 tag、GitHub Release 或 pub.dev 发布。

## 许可证

Apache License 2.0。详见 [LICENSE](LICENSE) 和仓库来源记录。
