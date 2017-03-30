/**
 * code_gen_visitor.dart
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
import 'package:compiler/src/tree/tree.dart';
class CodeGenVisitor extends Visitor {
  CodeGenBuffer buffer;
  CodeGenVisitor() : this.buffer = new CodeGenBuffer();
  CodeGenVisitor.withBuffer(this.buffer);
  visitNodeList(NodeList node) {
    node.visitChildren(this);
  }

  visitNode(Node node) {
    buffer.comment(node);
//    throw new UnimplementedError('$node');
  }
  visitEnum(Enum node) {
    buffer.tab().writeWithLine('public enum ${node.name} {');
    Iterator it = node.names.iterator;
    bool first = true;
    buffer.indent += 1;
    while(it.moveNext()) {
      if (first) {
        first = false;
      } else {
        buffer.writeWithLine(',');
      }
      buffer.tab().write('${it.current}');
    }
    if (!first) {
      buffer.writeWithLine(';');
    }
    buffer.indent -= 1;
    buffer.tab().writeWithLine('}');
  }
  visitLiteralBool(LiteralBool node) => buffer.write('$node');
  visitLiteralDouble(LiteralDouble node) => buffer.write('$node');
  visitLiteralInt(LiteralInt node) => buffer.write('$node');
  visitLiteralList(LiteralList node) {
    buffer.write('asList(');
    Iterator<Node> it = node.elements.iterator;
    bool first = true;
    while(it.moveNext()) {
      if (first) {
        first = false;
      } else {
        buffer.write(', ');
      }
      ReceiverVisitor visitor = new ReceiverVisitor();
      it.current.accept(visitor);
      buffer.join(visitor.buffer);
    }
    buffer.write(')');
  }
  visitLiteralNull(LiteralNull node) => buffer.write('null');
  visitLiteralString(LiteralString node) => buffer.write('"${node.dartString.slowToString()}"');
  visitLiteralMap(LiteralMap node) {
    Iterator<Node> it = node.entries.iterator;
    var list = [];
    while(it.moveNext()) {
      LiteralMapEntry entry = it.current as LiteralMapEntry;
      list.add(entry.key.accept(new CodeGenVisitor()));
      list.add(entry.value.accept(new CodeGenVisitor()));
    }
    buffer.write('asMap(${list.join(",")})');
  }

  String toParamModifiers(Modifiers modifiers) {
    CodeGenBuffer buffer = new CodeGenBuffer();
    if (modifiers.isVar)
      buffer.commentField('var').write(' ');
    if (modifiers.isConst)
      buffer.commentField('const').write(' ');
    if (modifiers.isFactory)
      buffer.commentField('factory').write(' ');
    if (modifiers.isFinal)
      buffer.write('final ');
    if (modifiers.isAbstract)
      buffer.commentField('abstract ');
    if (modifiers.isStatic)
      buffer.commentField('static ');
    return buffer.toString();
  }
  toArguments(Iterator<Node> it) {
    bool first = true;
    while(it.moveNext()) {
      if (first) {
        first = false;
      } else {
        buffer.write(', ');
      }
      ReceiverVisitor visitor = new ReceiverVisitor();
      it.current.accept(visitor);
      buffer.join(visitor.buffer);
//      buffer.write('${it.current}');
    }
  }
  String toTypeAnnotations(Iterator<Node> it) {
    var buffer = new CodeGenBuffer();
    bool first = true;
    buffer.write('<');
    while(it.moveNext()) {
      if (first) {
        first = false;
      } else {
        buffer.write(', ');
      }
      buffer.write(toJavaObjectType(it.current as TypeAnnotation).trim()).write('> ');
    }
    return buffer.toString();
  }
  String toFieldModifiers(VariableDefinitions node) {
    Modifiers modifiers = node.modifiers;
    CodeGenBuffer buffer = _toModifiers(modifiers);
    if (node.definitions.toString().startsWith('_'))
      buffer.write('private ');
    return buffer.toString();
  }

  String toClassModifiers(ClassNode node) {
    Modifiers modifiers = node.modifiers;
    CodeGenBuffer buffer = _toModifiers(modifiers);
    if (node.name.toString().startsWith('_'))
      buffer.write('private ');
    return buffer.toString();
  }
  CodeGenBuffer _toModifiers(Modifiers modifiers) {
    CodeGenBuffer buffer = new CodeGenBuffer();
    if (modifiers.isVar)
      buffer.commentField('var').write(' ');
    if (modifiers.isConst)
      buffer.commentField('const').write(' ');
    if (modifiers.isFactory)
      buffer.commentField('factory').write(' ');
    if (modifiers.isFinal)
      buffer.write('final ');
    if (modifiers.isAbstract)
      buffer.write('abstract ');
    if (modifiers.isStatic)
      buffer.write('static ');
    return buffer;
  }
  String toMethodModifiers(FunctionExpression node) {
    Modifiers modifiers = node.modifiers;
    CodeGenBuffer buffer = _toModifiers(modifiers);
    if (node.name.toString().startsWith('_'))
      buffer.write('private ');
    return buffer.toString();
  }
  String toJavaType(TypeAnnotation type) {
    if (type is NominalTypeAnnotation) {
      switch ('$type') {
        case 'bool':
          return 'boolean ';
        case 'dynamic':
          return 'Object ';
        case 'num':
          return 'Number ';
        default:
          if (type.typeArguments?.isNotEmpty == true) {
           return '${type.typeName}${toTypeAnnotations(type.typeArguments.iterator)}';
          } else {
            return '$type ';
          }
      }
    } else if (type is FunctionTypeAnnotation) {
      return 'Function ';
    } else {
      return 'Object ';
    }
  }

  String toJavaObjectType(TypeAnnotation type) {
    if (type is NominalTypeAnnotation) {
      switch ('$type') {
        case 'bool':
          return 'Boolean ';
        case 'dynamic':
          return 'Object ';
        case 'num':
          return 'Number ';
        case 'int':
          return 'Integer ';
        case 'double':
          return 'Double ';
        default:
          if (type.typeArguments?.isNotEmpty == true) {
            return '${type.typeName}${toTypeAnnotations(type.typeArguments.iterator)} ';
          } else {
            return '$type ';
          }
      }
    } else if (type is FunctionTypeAnnotation) {
      return 'Function ';
    } else {
      return 'Object ';
    }
  }
}
class CodeGenBuffer {
  List<String> queue = [];

  bool get isEmpty => queue.isEmpty;
  bool get isNotEmpty => queue.isNotEmpty;
  int indent = 0;

  CodeGenBuffer line([int times = 1]) {
    while(times-- > 0)
      queue.add('\n');
    return this;
  }

  CodeGenBuffer tab([int times = 1]) {
    var t = indent + times;
    while(t-- > 0)
      queue.add('\t');
    return this;
  }

  CodeGenBuffer comment(s) {
    queue.add('//$s\n');
    return this;
  }
  CodeGenBuffer commentField(s) {
    queue.add('/*$s*/');
    return this;
  }
  CodeGenBuffer operator +(v) {
    if (v is CodeGenBuffer) {
      queue.addAll(v.queue);
      return this;
    } else if (v is String) {
      return this.write(v);
    }
    throw new UnsupportedError('$v');
  }
  CodeGenBuffer write(s) {
    queue.add('$s');
    return this;
  }
  CodeGenBuffer writeWithLine(s) {
    queue..add('$s')..add('\n');
    return this;
  }

  CodeGenBuffer join(CodeGenBuffer buffer) {
    queue.addAll(buffer.queue);
    return this;
  }
  toString() {
    return queue.join('');
  }
}

class ReceiverVisitor extends CodeGenVisitor {

  ReceiverVisitor();
  ReceiverVisitor.withBuffer(buffer): super.withBuffer(buffer);
  visitSend(Send node) {
    if (node.receiver != null) {
      node.receiver.accept(this);
    }
    if (node.selector is Operator) {
      if (node.selector.toString() == '[]') {
        buffer.write('[');
        if (node.argumentCount() > 0) {
          toArguments(node.arguments.iterator);
        }
        buffer.write(']');
      } else {
        buffer.write(' ${node.selector} ');
        if (node.argumentCount() > 0) {
          toArguments(node.arguments.iterator);
        }
      }
    } else {
      if (node.receiver != null) buffer.write('.');
      buffer.write('${node.selector}');

      if (node.argumentCount() > 0) {
        buffer.write('(');
        toArguments(node.arguments.iterator);
        buffer.write(')');
      }
    }
  }
  visitSendSet(SendSet node) {
    if (node.receiver != null) {
      buffer.write('${node.receiver}.');
    }
    buffer.write('${node.selector} = ');
    if (node.argumentCount() > 0)
      toArguments(node.arguments.iterator);
  }
  visitNode(Node node) {
    buffer.write('$node');
  }
}