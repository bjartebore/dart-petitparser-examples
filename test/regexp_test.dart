import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/regexp.dart';
import 'package:test/test.dart';

void main() {
  group('parser', () {
    final la = LiteralNode('a');
    final lb = LiteralNode('b');
    final lc = LiteralNode('c');
    final ld = LiteralNode('d');
    test('empty', () {
      expect(Node.fromString(r''), EmptyNode());
      expect(Node.fromString(r'()'), EmptyNode());
      expect(Node.fromString(r'(())'), EmptyNode());
    });
    test('dot', () {
      expect(Node.fromString(r'.'), DotNode());
      expect(Node.fromString(r'(.)'), DotNode());
      expect(Node.fromString(r'((.))'), DotNode());
    });
    test('literal', () {
      expect(Node.fromString(r'a'), la);
      expect(Node.fromString(r'(a)'), la);
      expect(Node.fromString(r'((a))'), la);
    });
    test('escape', () {
      expect(Node.fromString(r'\\'), LiteralNode('\\'));
      expect(Node.fromString(r'\('), LiteralNode('('));
      expect(Node.fromString(r'\)'), LiteralNode(')'));
      expect(Node.fromString(r'\?'), LiteralNode('?'));
      expect(Node.fromString(r'\+'), LiteralNode('+'));
      expect(Node.fromString(r'\*'), LiteralNode('*'));
      expect(Node.fromString(r'\|'), LiteralNode('|'));
    });
    test('concat', () {
      expect(Node.fromString(r'ab'), ConcatNode(la, lb));
      expect(Node.fromString(r'abc'), ConcatNode(ConcatNode(la, lb), lc));
      expect(Node.fromString(r'abcd'),
          ConcatNode(ConcatNode(ConcatNode(la, lb), lc), ld));
    });
    test('alternate', () {
      expect(Node.fromString(r'a|b'), AlternateNode(la, lb));
      expect(
          Node.fromString(r'a|b|c'), AlternateNode(AlternateNode(la, lb), lc));
      expect(Node.fromString(r'a|b|c|d'),
          AlternateNode(AlternateNode(AlternateNode(la, lb), lc), ld));
    });
    test('optional', () {
      expect(Node.fromString(r'a?'), QuantifierNode(la, 0, 1));
    });
    test('star', () {
      expect(Node.fromString(r'a*'), QuantifierNode(la, 0, null));
    });
    test('plus', () {
      expect(Node.fromString(r'a+'), QuantifierNode(la, 1, null));
    });
    test('repeat n times', () {
      expect(Node.fromString(r'a{1}'), QuantifierNode(la, 1, 1));
      expect(Node.fromString(r'a{23}'), QuantifierNode(la, 23, 23));
    });
    test('repeat n or more times', () {
      expect(Node.fromString(r'a{4,}'), QuantifierNode(la, 4, null));
      expect(Node.fromString(r'a{56,}'), QuantifierNode(la, 56, null));
    });
    test('repeat up to n times', () {
      expect(Node.fromString(r'a{,7}'), QuantifierNode(la, 0, 7));
      expect(Node.fromString(r'a{,89}'), QuantifierNode(la, 0, 89));
    });
    test('repeat at lest n and at most m times', () {
      expect(Node.fromString(r'a{1,2}'), QuantifierNode(la, 1, 2));
      expect(Node.fromString(r'a{34,567}'), QuantifierNode(la, 34, 567));
    });
    test('concat and or', () {
      expect(Node.fromString(r'ab|cd'),
          AlternateNode(ConcatNode(la, lb), ConcatNode(lc, ld)));
      expect(Node.fromString(r'a(b|c)d'),
          ConcatNode(ConcatNode(la, AlternateNode(lb, lc)), ld));
    });
    test('concat and repeat', () {
      expect(Node.fromString(r'ab+'), ConcatNode(la, QuantifierNode(lb, 1)));
      expect(Node.fromString(r'(ab)+'), QuantifierNode(ConcatNode(la, lb), 1));
    });
  });
  group('NFA', () {
    for (final testData in tests) {
      test(testData.pattern, () {
        final pattern = Nfa.fromString(testData.pattern);
        for (final expectData in testData.expects) {
          expect(pattern.tryMatch(expectData.input), expectData.match,
              reason: '"${testData.pattern}" '
                  '${expectData.match ? 'matches' : 'does not match'} '
                  '"${expectData.input}"');
        }
      });
    }
  });
  test('linter', () {
    expect(linter(nodeParser), isEmpty);
  });
}

class Test {
  const Test(this.pattern, this.expects);

  final String pattern;
  final List<Expect> expects;
}

class Expect {
  const Expect(this.input, this.match);

  final String input;
  final bool match;
}

const tests = [
  // Basics
  Test(r'', [
    Expect('', true),
    Expect('a', false),
    Expect('ab', false),
  ]),
  Test(r'.', [
    Expect('', false),
    Expect('a', true),
    Expect('b', true),
    Expect('aaa', false),
  ]),
  Test(r'a', [
    Expect('', false),
    Expect('a', true),
    Expect('aaa', false),
  ]),
  Test(r'ab', [
    Expect('ab', true),
    Expect('', false),
    Expect('a', false),
    Expect('ax', false),
    Expect('xa', false),
    Expect('xb', false),
    Expect('abx', false),
    Expect('ba', false),
  ]),
  Test(r'a|b', [
    Expect('a', true),
    Expect('b', true),
    Expect('d', false),
  ]),
  Test(r'a?', [
    Expect('', true),
    Expect('a', true),
    Expect('aa', false),
    Expect('aaa', false),
    Expect('aba', false),
    Expect('b', false),
  ]),
  Test(r'a*', [
    Expect('', true),
    Expect('aaaa', true),
    Expect('aa', true),
    Expect('aba', false),
  ]),
  Test(r'a+', [
    Expect('', false),
    Expect('a', true),
    Expect('aa', true),
    Expect('aaa', true),
    Expect('aba', false),
    Expect('b', false),
  ]),
  // https://regex-generate.github.io/regenerate/
  Test(r'(b(ab*a)*b|a)*', [
    Expect('a', true),
    Expect('aa', true),
    Expect('bb', true),
    Expect('aaa', true),
    Expect('abb', true),
    Expect('bbaa', true),
    Expect('bbbb', true),
    Expect('abbaa', true),
    Expect('bbabb', true),
    Expect('baabaa', true),
    Expect('baabbb', true),
    Expect('abbbaab', true),
    Expect('baababb', true),
    Expect('bababaa', true),
    Expect('bababbb', true),
    Expect('bbabbaa', true),
    Expect('aaaabbaa', true),
    Expect('abaabaaa', true),
    Expect('abbbbabb', true),
    Expect('b', false),
    Expect('ab', false),
    Expect('ba', false),
    Expect('aab', false),
    Expect('aba', false),
    Expect('bbab', false),
    Expect('baaaa', false),
    Expect('babba', false),
    Expect('aaabbb', false),
    Expect('aababa', false),
    Expect('aabbba', false),
    Expect('abbaba', false),
    Expect('baabab', false),
    Expect('babaab', false),
    Expect('bababb', false),
    Expect('babbaa', false),
    Expect('babbba', false),
    Expect('aaaabaa', false),
    Expect('aabaaab', false),
    Expect('aabbbaa', false),
  ]),
  Test(r'(ab*)*', [
    Expect('a', true),
    Expect('aa', true),
    Expect('ab', true),
    Expect('aaa', true),
    Expect('aab', true),
    Expect('aba', true),
    Expect('aaaa', true),
    Expect('abaa', true),
    Expect('abba', true),
    Expect('aaaab', true),
    Expect('aabaa', true),
    Expect('aabba', true),
    Expect('abaab', true),
    Expect('abbab', true),
    Expect('abbba', true),
    Expect('abbbb', true),
    Expect('aaaaaa', true),
    Expect('aaabaa', true),
    Expect('aabbaa', true),
    Expect('b', false),
    Expect('ba', false),
    Expect('bb', false),
    Expect('baa', false),
    Expect('bab', false),
    Expect('baab', false),
    Expect('babab', false),
    Expect('babbb', false),
    Expect('bbbbb', false),
    Expect('baabba', false),
    Expect('baabbb', false),
    Expect('babbba', false),
    Expect('bbbaba', false),
    Expect('bbbabb', false),
    Expect('bbbbbb', false),
    Expect('baaabab', false),
    Expect('baababa', false),
    Expect('bababaa', false),
    Expect('babbaab', false),
    Expect('babbbbb', false),
  ]),
  Test(r'(b*ab*ab*a)*b*', [
    Expect('b', true),
    Expect('bb', true),
    Expect('aaa', true),
    Expect('bbb', true),
    Expect('bbbb', true),
    Expect('bbaaa', true),
    Expect('abbaba', true),
    Expect('abbbaa', true),
    Expect('babaab', true),
    Expect('bbaaba', true),
    Expect('aaabbbb', true),
    Expect('aababbb', true),
    Expect('aabbbba', true),
    Expect('ababbba', true),
    Expect('baababb', true),
    Expect('babbbaa', true),
    Expect('bbbaaab', true),
    Expect('bbbabaa', true),
    Expect('aabbbbba', true),
    Expect('a', false),
    Expect('aa', false),
    Expect('ab', false),
    Expect('ba', false),
    Expect('aab', false),
    Expect('aba', false),
    Expect('baab', false),
    Expect('aabbb', false),
    Expect('ababb', false),
    Expect('bbaab', false),
    Expect('bbbba', false),
    Expect('aabaab', false),
    Expect('aabbaa', false),
    Expect('abaaab', false),
    Expect('abbabb', false),
    Expect('baaaab', false),
    Expect('bbaaaa', false),
    Expect('aaaabba', false),
    Expect('aababab', false),
    Expect('aabbbbb', false),
  ]),
  // https://github.com/xysun/regex/blob/master/testing.py
  Test(r'(ab|a)(bc|c)', [Expect('abc', true), Expect('acb', false)]),
  Test(r'(ab)c|abc', [Expect('abc', true), Expect('ab', false)]),
  Test(r'(a*)(b?)(b+)', [Expect('aaabbbb', true), Expect('aaaa', false)]),
  Test(r'((a|a)|a)', [Expect('a', true), Expect('aa', false)]),
  Test(r'(a*)(a|aa)', [Expect('aaaa', true), Expect('b', false)]),
  Test(r'a(b)|c(d)|a(e)f', [Expect('aef', true), Expect('adf', false)]),
  Test(r'(a|b)c|a(b|c)', [Expect('ac', true), Expect('acc', false)]),
  Test(r'(a|b)c|a(b|c)', [Expect('ab', true), Expect('acc', false)]),
  Test(r'(a|b)*c|(a|ab)*c', [Expect('abc', true), Expect('bbbcabbbc', false)]),
  Test(r'a?(ab|ba)ab', [Expect('abab', true), Expect('aaabab', false)]),
  Test(r'(aa|aaa)*|(a|aaaaa)', [Expect('aa', true)]),
  Test(r'(a)(b)(c)', [Expect('abc', true)]),
  Test(r'((((((((((x))))))))))', [Expect('x', true)]),
  Test(r'((((((((((x))))))))))*', [Expect('xx', true)]),
  Test(r'a?(ab|ba)*', [Expect('ababababababababababababababababa', true)]),
  Test(r'a*a*a*a*a*b', [Expect('aaaaaaaab', true)]),
  Test(r'abc', [Expect('abc', true)]),
  Test(r'ab*c', [Expect('abc', true)]),
  Test(r'ab*bc', [Expect('abbc', true)]),
  Test(r'ab*bc', [Expect('abbbbc', true)]),
  Test(r'ab+bc', [Expect('abbc', true)]),
  Test(r'ab+bc', [Expect('abbbbc', true)]),
  Test(r'ab?bc', [Expect('abbc', true)]),
  Test(r'ab?bc', [Expect('abc', true)]),
  Test(r'ab|cd', [Expect('ab', true)]),
  Test(r'(a)b(c)', [Expect('abc', true)]),
  Test(r'a*', [Expect('aaa', true)]),
  Test(r'(a+|b)*', [Expect('ab', true)]),
  Test(r'(a+|b)+', [Expect('ab', true)]),
  Test(r'a|b|c|d|e', [Expect('e', true)]),
  Test(r'(a|b|c|d|e)f', [Expect('ef', true)]),
  Test(r'abcd*efg', [Expect('abcdefg', true)]),
  Test(r'(ab|ab*)bc', [Expect('abc', true)]),
  Test(r'(ab|a)b*c', [Expect('abc', true)]),
  Test(r'((a)(b)c)(d)', [Expect('abcd', true)]),
  Test(r'(a|ab)(c|bcd)', [Expect('abcd', true)]),
  Test(r'(a|ab)(bcd|c)', [Expect('abcd', true)]),
  Test(r'(ab|a)(c|bcd)', [Expect('abcd', true)]),
  Test(r'(ab|a)(bcd|c)', [Expect('abcd', true)]),
  Test(r'((a|ab)(c|bcd))(d*)', [Expect('abcd', true)]),
  Test(r'((a|ab)(bcd|c))(d*)', [Expect('abcd', true)]),
  Test(r'((ab|a)(c|bcd))(d*)', [Expect('abcd', true)]),
  Test(r'((ab|a)(bcd|c))(d*)', [Expect('abcd', true)]),
  Test(r'(a|ab)((c|bcd)(d*))', [Expect('abcd', true)]),
  Test(r'(a|ab)((bcd|c)(d*))', [Expect('abcd', true)]),
  Test(r'(ab|a)((c|bcd)(d*))', [Expect('abcd', true)]),
  Test(r'(ab|a)((bcd|c)(d*))', [Expect('abcd', true)]),
  Test(r'(a*)(b|abc)', [Expect('abc', true)]),
  Test(r'(a*)(abc|b)', [Expect('abc', true)]),
  Test(r'((a*)(b|abc))(c*)', [Expect('abc', true)]),
  Test(r'((a*)(abc|b))(c*)', [Expect('abc', true)]),
  Test(r'(a*)((b|abc))(c*)', [Expect('abc', true)]),
  Test(r'(a*)((abc|b)(c*))', [Expect('abc', true)]),
  Test(r'(a*)(b|abc)', [Expect('abc', true)]),
  Test(r'(a*)(abc|b)', [Expect('abc', true)]),
  Test(r'((a*)(b|abc))(c*)', [Expect('abc', true)]),
  Test(r'((a*)(abc|b))(c*)', [Expect('abc', true)]),
  Test(r'(a*)((b|abc)(c*))', [Expect('abc', true)]),
  Test(r'(a*)((abc|b)(c*))', [Expect('abc', true)]),
  Test(r'(a|ab)', [Expect('ab', true)]),
  Test(r'(ab|a)', [Expect('ab', true)]),
  Test(r'(a|ab)(b*)', [Expect('ab', true)]),
  Test(r'(ab|a)(b*)', [Expect('ab', true)]),
];
