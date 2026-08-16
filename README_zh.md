# mhchemParser Dart 移植版

[English](README.md)

本仓库同时保存经过审计的 mhchemParser 4.2.2 JavaScript/TypeScript 基线，以及独立版本管理、零运行时依赖的纯 Dart 移植版，用于将 mhchem 输入转换为 LaTeX。

## 兼容性

| 组件 | 契约 |
|---|---|
| Dart 包 | `mhchem_parser 0.1.0` |
| 上游行为 | mhchemParser `4.2.2`，提交 `acaf5adb97a08deb234e0a8d62c807c17ee650d6` |
| Dart SDK | `>=3.6.0 <4.0.0` |
| 下游 Flutter 基线 | Flutter `3.27.4` 及后续兼容版本 |
| 运行时依赖 | 无；纯 Dart |

Dart 包版本与上游兼容版本相互独立。不可变来源、文件哈希与验证命令见 [UPSTREAM.md](UPSTREAM.md)。

## 仓库结构

```text
mhchemParser/
├── js/mhchemParser/               # 经审计的上游 4.2.2 源码和 JS oracle
├── flutter/mhchemParser/          # 可发布的纯 Dart 包
├── tools/conformance/             # 来源、语料、oracle 和运行时边界检查
├── tool/flutter_consumer/         # Flutter 3.27.4 消费方验证
└── openspec/                      # 版本化行为契约与实施计划
```

## 安装

请固定完整提交 SHA 或经过批准的不可变 tag；Dart 包继续位于仓库子目录：

```yaml
dependencies:
  mhchem_parser:
    git:
      url: https://github.com/gcc8080/mhchemParser.git
      ref: <approved-release-tag-or-full-commit-sha>
      path: flutter/mhchemParser
```

本地开发也可以使用 path 依赖：

```yaml
dependencies:
  mhchem_parser:
    path: ../mhchemParser/flutter/mhchemParser
```

## 公共 API

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

final onePass = MhchemParser.convert(
  r'm_{\ce{H2O}} = \pu{1.2kg}',
  mode: MhchemMode.tex,
);

final completelyExpanded = MhchemParser.expandAllTex(
  r'\ce{$\frac{\ce{H2O}}{1}$}',
);
```

`convert` 严格执行一次上游兼容转换。`expandAllTex` 是显式选择的完整展开接口，默认最多 16 次；如果达到上限或无法继续推进，会抛出带 `passLimit` 或 `noProgress` 原因的 `MhchemExpansionException`，不会把不完整结果伪装成成功。

旧接口 `MhchemParser.toTex(input, 'ce')` 已废弃，但会在整个 `0.x` 版本线中保留，最早只能在 `1.0.0` 移除。

公共版本元数据：

- `MhchemParser.packageVersion`
- `MhchemParser.upstreamVersion`
- `MhchemParser.upstreamCommit`

## 精确输出边界

117 条固定官方用例必须与上游 4.2.2 输出逐字符一致。解析包不会为了适配较小的 KaTeX 命令子集而改写输出。`\mathchoice`、`\smash`、水平叠放、垂直位移、`\tripledash` 以及 mhchem 长箭头等命令属于下游渲染器契约。

JavaScript 仅在离线一致性验证中作为 oracle 使用。发布的 Dart 包运行时不依赖 JavaScript、Flutter、WebView、插件或网络。

## 验证

```sh
node tools/conformance/check-upstream.mjs
node tools/conformance/extract-corpus.mjs --check
node tools/conformance/verify-oracle.mjs
node tools/conformance/check-runtime-boundary.mjs

cd flutter/mhchemParser
dart pub get
dart format --output=none --set-exit-if-changed lib test
dart analyze --fatal-infos
dart test
dart pub publish --dry-run
```

CI 会使用 Dart 3.6、当前 stable Dart 和 Flutter 3.27.4 消费方运行检查。117 条用例代表固定官方兼容语料，不表示所有非法输入都与 JavaScript 完全等价。

## 发布边界

本变更只准备 `0.1.0` 包内容。创建 Git tag、GitHub Release 或发布到 pub.dev 均需单独授权。

## 许可证

Apache License 2.0。上游版权与归属保留在 [LICENSE](LICENSE)、[UPSTREAM.md](UPSTREAM.md) 和经审计的源码中。
