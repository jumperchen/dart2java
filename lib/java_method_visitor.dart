import 'code_gen_visitor.dart';
import 'dart:io';
import 'java_class_visitor.dart';
import 'package:compiler/src/tree/tree.dart';
import 'package:front_end/src/scanner/token.dart';

/**
 * java_method_visitor.dart
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
class JavaMethodVisitor extends CodeGenVisitor {

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

    // abstract class
    if (node.body is EmptyStatement) {
      buffer.write('abstract ');
    }

    // type info is put before return type in java
    if (node.typeVariables != null) {
      buffer.write('${node.typeVariables} ');
    }
    if (node.returnType != null) {
      TypeAnnotation returnType = node.returnType;
      buffer.write(toJavaType(returnType));
    } else if (node.body is Return) {
      buffer.write('Object ');
    } else {
      buffer.write('void ');
    }
    var methodName = node.name.toString();
    if (node.getOrSet != null) {
      if (node.getOrSet.keyword == Keyword.SET) {
        methodName = 'set${methodName.substring(0, 1).toUpperCase()}${methodName.substring(1)}';
      } else {
        if (node.returnType is NominalTypeAnnotation && node.returnType.toString() == 'bool') {
          // bool get foo => boolean isFoo()
          if (!methodName.startsWith('is')) {
            methodName =
            'is${methodName.substring(0, 1).toUpperCase()}${methodName
                .substring(1)}';
          }
        } else {
          methodName =
          'get${methodName.substring(0, 1).toUpperCase()}${methodName.substring(
              1)}';
        }
      }
    }
    buffer.write('$methodName');

    // method parameters;
    buffer.write('(');
    if (node.parameters != null) {
      JavaMethodParamsVisitor visitor = new JavaMethodParamsVisitor();
      node.parameters.accept(visitor);
      buffer.join(visitor.buffer);
    }
    buffer.write(')');

    if (node.initializers != null) {
      throw new UnimplementedError('Not implemented yet');
    }
    if (node.asyncModifier != null) {
      throw new UnimplementedError('Not implemented yet');
    }
    if (node.body != null && node.body is! EmptyStatement) {
      buffer.writeWithLine(' {');

      JavaMethodBodyVisitor body = new JavaMethodBodyVisitor();
      if (node.body is Return) {
        buffer.tab();
      }
      node.body.accept(body);
      buffer.join(body.buffer);

      buffer.tab().writeWithLine('}');
    } else {
      buffer.writeWithLine(';');
    }
  }

}

class JavaMethodParamsVisitor extends CodeGenVisitor {
  CodeGenBuffer initValues = new CodeGenBuffer();
  visitVariableDefinitions(VariableDefinitions node) {
    if (node.modifiers?.nodes?.isNotEmpty == true)
      buffer.write(toParamModifiers(node.modifiers));
    if (node.type != null) {
      buffer.write(toJavaType(node.type));
    } else {
      buffer.write('Object '); // default type
    }
    // we need handle the default value for the params.
    Iterator<Node> it = node.definitions.iterator;
    while(it.moveNext()) {
      if (it.current is SendSet) {
        SendSet set = it.current as SendSet;
        buffer.write(set.selector);
        initValues.tab(2).write('if (${set.selector} == null) ${set.selector} = ${set.arguments.head};\n');
      } else {
        buffer.write(it.current);
      }
    }
  }

  @override
  visitNodeList(NodeList node) {
    if (node.nodes == null) return;
    Iterator<Node> it = node.iterator;
    bool first = true;
    while(it.moveNext()) {
      if (first) {
        first = false;
      } else {
        buffer.write(', ');
      }
      it.current.accept(this);
    }
  }
}

class JavaMethodBodyVisitor extends CodeGenVisitor {
  visitReturn(Return node) {
    buffer.tab().write('return ');
    node.visitChildren(this);
    buffer.write(';').line();
  }

  visitSend(Send node) {
    bool isNot;
    if (node.receiver != null) {
      if (node.selector is Operator) {
        if (node.selector.toString() == 'is!') {
          isNot = true;
          buffer.write('!(');
        }
        node.receiver.accept(new ReceiverVisitor.withBuffer(buffer));
      } else {
        node.receiver.accept(new ReceiverVisitor.withBuffer(buffer));
        buffer.write('.');
      }
    }
    bool isOp = false;
    if (node.selector is Operator) {
      isOp = true;
      if (node.selector.toString().startsWith('is')) {
        buffer.write(' instanceOf ');
      } else {
        buffer.write(' ${node.selector} ');
      }
    } else {
      buffer.write('${node.selector}');
    }
    if (node.argumentCount() > 0) {
      if (!isOp || node.argumentCount() > 1)
        buffer.write('(');
      toArguments(node.arguments.iterator);
      if (!isOp || node.argumentCount() > 1)
        buffer.write(')');
    }
    if (isNot == true) {
      buffer.write(')'); // for !(xx instanceof YY);
    }
  }
  visitSendSet(SendSet node) {
    if (node.receiver != null) {
      node.receiver.accept(new ReceiverVisitor.withBuffer(buffer));
      buffer.write('.');
    }
    buffer.write('${node.selector} = ');
    if (node.argumentCount() > 0)
      toArguments(node.arguments.iterator);
  }
  visitExpressionStatement(ExpressionStatement node) {
    buffer.tab();
    node.visitChildren(this);
    buffer.writeWithLine(';');
  }

  visitBlock(Block node) {
    buffer.indent += 1;
    node.visitChildren(this);
    buffer.indent -= 1;
  }

  visitEmptyStatement(EmptyStatement node) {
    // ignore;
  }
  visitIf(If node) {
    buffer.tab().write('if ');
    if (node.condition != null) {
      buffer.write('(');
      node.condition.visitChildren(this);
      buffer.write(') ');
    }
    if (node.thenPart != null) {
        buffer.writeWithLine('{');
        buffer.indent += 1;

        if (node.thenPart is Return) {
          buffer.tab().write('return ');
          node.thenPart.visitChildren(this);
          buffer.writeWithLine(';');
        } else {
          node.thenPart.visitChildren(this);
        }
        buffer.indent -= 1;
        buffer.tab().write('}');
    }
    if (node.elsePart != null) {
      buffer.writeWithLine(' else {');
      buffer.indent += 1;
      if (node.elsePart is Return) {
        buffer.tab().write('return ');
        node.elsePart.visitChildren(this);
        buffer.writeWithLine(';');
      } else {
        node.elsePart.visitChildren(this);
      }
      buffer.indent -= 1;
      buffer.tab().writeWithLine('}');
    } else {
      buffer.line();
    }
  }
  visitSyncForIn(SyncForIn node) {
    buffer.tab().write('for (');
    if (node.declaredIdentifier != null) {
      VariableDefinitions variable = node.declaredIdentifier;
      buffer.write(toParamModifiers(variable.modifiers));
      buffer.write(variable.type ?? 'Object').write(' ');
      buffer.write(variable.definitions);
    }
    buffer.write(' : ');
    node.expression?.accept(this);
    buffer.write(') ');
    if (node.body != null) {
      buffer.writeWithLine('{');
      buffer.indent += 1;
      node.body.visitChildren(this);
      buffer.indent -= 1;
      buffer.tab().writeWithLine('}');
    }
  }

  visitVariableDefinitions(VariableDefinitions node) {
    if (node.type == null) {
      buffer.tab().commentField(node.modifiers.toString()).write('\t').write('Object ');
      node.definitions.visitChildren(this);
      buffer.writeWithLine(';');
    } else {
      buffer.tab().write(toFieldModifiers(node)).write(toJavaType(node.type));
      JavaVariableDefinitions visitor = new JavaVariableDefinitions();
      node.definitions.accept(visitor);
      buffer.join(visitor.buffer);
      buffer.writeWithLine(';');
    }
  }
}