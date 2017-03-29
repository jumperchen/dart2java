import 'code_gen_visitor.dart';
import 'java_method_visitor.dart';
import 'package:compiler/src/tree/tree.dart';

/**
 * java_constructor_visitor.dart
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
class JavaConstructorVisitor extends CodeGenVisitor {

  @override
  visitFunctionExpression(FunctionExpression node) {
    buffer.tab();
    if (node.modifiers?.nodes?.isNotEmpty == true) {
      buffer.write(toMethodModifiers(node));
    } else {
      if (node.name.toString().startsWith('_')) {
        buffer.write('pivate ');
      } else {
        buffer.write('public '); // public is dart default modifiers
      }
    }
    if (node.name != null) buffer.write('${node.name}');

    // method parameters;
    buffer.write('(');
    JavaMethodParamsVisitor paramsVisitor;
    if (node.parameters != null) {
      paramsVisitor = new JavaMethodParamsVisitor();
      node.parameters.accept(paramsVisitor);
      buffer.join(paramsVisitor.buffer);
    }
    buffer.write(')');

    if (node.asyncModifier != null) {
      throw new UnimplementedError('Not implemented yet');
    }

    buffer.writeWithLine(' {');

    if (node.initializers != null) {
      JavaConstructorInitalizersVisitor visitor = new JavaConstructorInitalizersVisitor();
      visitor.visitNodeList(node.initializers);
      buffer.join(visitor.buffer);
    }

    if (paramsVisitor?.initValues?.isNotEmpty == true) {
      buffer.join(paramsVisitor.initValues);
    }

    if (node.body != null && node.body is! EmptyStatement) {
      JavaMethodBodyVisitor body = new JavaMethodBodyVisitor();
      node.body.accept(body);
      buffer.join(body.buffer);
    }
    buffer.tab().writeWithLine('}');
  }
}

class JavaConstructorInitalizersVisitor extends CodeGenVisitor {

  visitSend(Send node) {
    if (node.receiver != null) {
      node.receiver.accept(new ReceiverVisitor.withBuffer(buffer));
      buffer.write('.');
    }
    buffer.write('${node.selector}(');
    if (node.argumentCount() > 0)
      toArguments(node.arguments.iterator);
    buffer.write(')');
  }
  @override
  visitNodeList(NodeList node) {
    if (node.nodes == null) return;
    Iterator<Node> it = node.iterator;
    while(it.moveNext()) {
      buffer.tab(2);
      it.current.accept(this);
      buffer.writeWithLine(';');
    }
  }
}