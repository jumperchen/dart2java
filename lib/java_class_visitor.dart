import 'code_gen_visitor.dart';
import 'java_constructor_visitor.dart';
import 'java_method_visitor.dart';
import 'package:compiler/src/tree/tree.dart';

/**
 * java_class_visitor.dart
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
class JavaClassVisitor extends CodeGenVisitor {
  ClassNode root;
  String className;
  JavaClassVisitor(this.root) {
    buffer += root.modifiers.isAbstract ? 'abstract class' : 'public class';
  }

  @override
  visitClassNode(ClassNode node) {
    if (node.name != null) node.name.accept(this);
    if (node.typeParameters != null) {
      buffer.write('${node.typeParameters} ');
    }
    if (node.superclass != null) {
      buffer.write('extends ${node.superclass} ');
    }
    if (node.interfaces?.nodes?.isNotEmpty == true) {
      buffer.write('${node.interfaces} ');
    }
    buffer.writeWithLine('{');
    if (node.body != null) node.body.accept(this);
    buffer.writeWithLine('}');
  }

  @override
  visitFunctionExpression(FunctionExpression node) {
    if (node.name.toString().startsWith(className)) {
      // constructor
      JavaConstructorVisitor visitor = new JavaConstructorVisitor();
      node.accept(visitor);
      buffer.line().join(visitor.buffer);
    } else {
      // method
      JavaMethodVisitor visitor = new JavaMethodVisitor();
      node.accept(visitor);
      buffer.line().join(visitor.buffer);
    }
  }

  @override
  visitIdentifier(Identifier node) {
    className = node.toString();
    buffer.write(' $node ');
  }

  @override
  visitVariableDefinitions(VariableDefinitions node) {
    if (node.type == null) {
      buffer.commentField(node.modifiers.toString()).write('\t').write('Object ').writeWithLine(node.definitions);
    } else {
      buffer.tab().write(toFieldModifiers(node)).write(toJavaType(node.type));
      JavaVariableDefinitions visitor = new JavaVariableDefinitions();
      node.definitions.accept(visitor);
      buffer.join(visitor.buffer);
      buffer.writeWithLine(';');
    }
  }
}

class JavaVariableDefinitions extends JavaMethodBodyVisitor {
  @override
  visitIdentifier(Identifier node) {
    buffer.write('$node');
  }
}