import 'code_gen_visitor.dart';
import 'java_class_visitor.dart';
import 'package:compiler/src/tree/tree.dart';

/**
 * java_code_gen_visitor.dart
 *
 * Purpose:
 *
 * Description:
 *
 * History:
 *   23/03/2017, Created by jumperchen
 *
 * Copyright (C) 2017 Potix Corporation. All Rights Reserved.
 */
class JavaCodeGenVisitor extends CodeGenVisitor {

  JavaCodeGenVisitor() {
    buffer.writeWithLine('import static java.util.Arrays.asList;');
//    buffer.writeWithLine('import static com.foo.bar.Utils.asMap;');
    buffer.writeWithLine('import java.util.List;');
  }

  @override
  visitLibraryName(LibraryName node) {
    buffer.writeWithLine('//$node');
  }

  @override
  visitImport(Import node) {
    buffer.comment(node);
  }

  @override
  visitClassNode(ClassNode node) {
    this.buffer.line();
    JavaClassVisitor visitor = new JavaClassVisitor(node);
    node.accept(visitor);
    this.buffer.join(visitor.buffer);
    //throw new UnimplementedError();// TODO: implement visitClassNode
  }
}