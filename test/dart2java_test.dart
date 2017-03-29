// Copyright (c) 2017, jumperchen. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import '../../sdk/pkg/compiler/tool/perf.dart';

import 'package:compiler/src/io/source_file.dart';
import 'package:compiler/src/tree/tree.dart';
import 'package:dart2java/java_code_gen_visitor.dart';

main () async {
  var dartFile = ''; // a dart file.
  var entryUri = Uri.base.resolve(dartFile);
  await setup(entryUri);
  Set<SourceFile> files = await scanReachableFiles(entryUri);
  NodeList tokens = parseFull(files.first);
  JavaCodeGenVisitor visitor = new JavaCodeGenVisitor();
  tokens.visitChildren(visitor);
//  print(unparse(tokens, minify: false));
  print(visitor.buffer);
}