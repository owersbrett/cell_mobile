// Parse — snippet bank for the code-construct identification quiz.
//
// Each item pairs a SHORT (1–4 line), real, idiomatic code snippet with the
// language it is written in and the CONSTRUCT it represents. The player's job is
// to name the construct — FUNCTION / CLASS / VARIABLE / INTERFACE (and later
// LOOP / IMPORT / ENUM) — NOT to guess the language (which is shown as a chip).
//
// The bank deliberately includes "tricky" late-game forms where the surface
// syntax fights the answer: arrow functions and lambdas assigned to a `const`
// (still a FUNCTION), Swift `protocol` / Python `Protocol` (an INTERFACE),
// `const x = require(...)` (an IMPORT), a Python `class C(Enum)` (an ENUM). The
// tell is taught in-context on the reveal via [ParseSnippet.note].
//
// This is data only — the renderer + syntax tinter live in `parse_game.dart`.

/// The seven code constructs the game can quiz. Reserved words (`class`,
/// `interface`, `enum`, `import`) force the odd enumerator names.
enum CodeConstruct { function, klass, variable, interfaceType, loop, importStmt, enumType }

/// The base four constructs the opening phase quizzes; LOOP / IMPORT / ENUM are
/// unlocked only in the late phase (see the game's phase logic).
const Set<CodeConstruct> kBaseConstructs = {
  CodeConstruct.function,
  CodeConstruct.klass,
  CodeConstruct.variable,
  CodeConstruct.interfaceType,
};

/// The extra constructs the late phase adds on top of [kBaseConstructs].
const Set<CodeConstruct> kExtraConstructs = {
  CodeConstruct.loop,
  CodeConstruct.importStmt,
  CodeConstruct.enumType,
};

/// Short UPPERCASE chip label for a construct.
String constructLabel(CodeConstruct c) {
  switch (c) {
    case CodeConstruct.function:
      return 'FUNCTION';
    case CodeConstruct.klass:
      return 'CLASS';
    case CodeConstruct.variable:
      return 'VARIABLE';
    case CodeConstruct.interfaceType:
      return 'INTERFACE';
    case CodeConstruct.loop:
      return 'LOOP';
    case CodeConstruct.importStmt:
      return 'IMPORT';
    case CodeConstruct.enumType:
      return 'ENUM';
  }
}

/// The six languages the snippets are drawn from.
enum CodeLang { python, swift, kotlin, java, typescript, javascript }

/// The "obvious"/easiest languages the opening phase restricts itself to.
const Set<CodeLang> kStarterLangs = {CodeLang.python, CodeLang.javascript};

/// Short display name for the language chip.
String langLabel(CodeLang l) {
  switch (l) {
    case CodeLang.python:
      return 'PYTHON';
    case CodeLang.swift:
      return 'SWIFT';
    case CodeLang.kotlin:
      return 'KOTLIN';
    case CodeLang.java:
      return 'JAVA';
    case CodeLang.typescript:
      return 'TYPESCRIPT';
    case CodeLang.javascript:
      return 'JAVASCRIPT';
  }
}

/// One quiz card: a snippet, its language, the construct it IS, whether it is a
/// tricky late-game form, and an optional one-line tell surfaced on the reveal.
class ParseSnippet {
  final CodeConstruct construct;
  final CodeLang lang;

  /// The code, newline-separated (1–4 lines). Rendered monospace.
  final String code;

  /// True for forms whose surface syntax fights the answer — held back until
  /// the phase that wants tricky snippets.
  final bool tricky;

  /// One-line explanation of the tell, shown on the post-answer reveal.
  final String? note;

  const ParseSnippet({
    required this.construct,
    required this.lang,
    required this.code,
    this.tricky = false,
    this.note,
  });
}

/// The full snippet bank — ≥8 per construct, spread across all six languages.
const List<ParseSnippet> kParseBank = [
  // ── FUNCTION ───────────────────────────────────────────────────────────────
  ParseSnippet(
    construct: CodeConstruct.function,
    lang: CodeLang.python,
    code: 'def greet(name):\n    return f"Hi {name}"',
  ),
  ParseSnippet(
    construct: CodeConstruct.function,
    lang: CodeLang.javascript,
    code: 'function add(a, b) {\n  return a + b;\n}',
  ),
  ParseSnippet(
    construct: CodeConstruct.function,
    lang: CodeLang.javascript,
    code: 'const double = (n) => n * 2;',
    tricky: true,
    note: 'An arrow function — still a FUNCTION, even assigned to a const.',
  ),
  ParseSnippet(
    construct: CodeConstruct.function,
    lang: CodeLang.python,
    code: 'square = lambda x: x * x',
    tricky: true,
    note: 'A lambda is an anonymous FUNCTION, bound here to a name.',
  ),
  ParseSnippet(
    construct: CodeConstruct.function,
    lang: CodeLang.typescript,
    code: 'function id<T>(x: T): T {\n  return x;\n}',
  ),
  ParseSnippet(
    construct: CodeConstruct.function,
    lang: CodeLang.swift,
    code: 'func area(_ r: Double) -> Double {\n  return .pi * r * r\n}',
  ),
  ParseSnippet(
    construct: CodeConstruct.function,
    lang: CodeLang.kotlin,
    code: 'fun sum(a: Int, b: Int): Int = a + b',
    tricky: true,
    note: 'A single-expression FUNCTION — the `fun` keyword gives it away.',
  ),
  ParseSnippet(
    construct: CodeConstruct.function,
    lang: CodeLang.java,
    code: 'int square(int n) {\n  return n * n;\n}',
  ),
  ParseSnippet(
    construct: CodeConstruct.function,
    lang: CodeLang.javascript,
    code: 'items.map(function (x) {\n  return x + 1;\n});',
    tricky: true,
    note: 'An anonymous FUNCTION passed as a callback.',
  ),
  ParseSnippet(
    construct: CodeConstruct.function,
    lang: CodeLang.kotlin,
    code: 'val onTap = { id: Int -> println(id) }',
    tricky: true,
    note: 'A lambda literal — a FUNCTION value, despite the `val`.',
  ),

  // ── CLASS ──────────────────────────────────────────────────────────────────
  ParseSnippet(
    construct: CodeConstruct.klass,
    lang: CodeLang.python,
    code: 'class Dog:\n    def bark(self):\n        print("woof")',
  ),
  ParseSnippet(
    construct: CodeConstruct.klass,
    lang: CodeLang.swift,
    code: 'class Vehicle {\n  var speed = 0\n}',
  ),
  ParseSnippet(
    construct: CodeConstruct.klass,
    lang: CodeLang.kotlin,
    code: 'class Point(val x: Int, val y: Int)',
  ),
  ParseSnippet(
    construct: CodeConstruct.klass,
    lang: CodeLang.java,
    code: 'public class User {\n  private String name;\n}',
  ),
  ParseSnippet(
    construct: CodeConstruct.klass,
    lang: CodeLang.typescript,
    code: 'class Stack<T> {\n  private items: T[] = [];\n}',
  ),
  ParseSnippet(
    construct: CodeConstruct.klass,
    lang: CodeLang.javascript,
    code: 'class Animal {\n  constructor(name) {\n    this.name = name;\n  }\n}',
  ),
  ParseSnippet(
    construct: CodeConstruct.klass,
    lang: CodeLang.python,
    code: '@dataclass\nclass Point:\n    x: int\n    y: int',
    tricky: true,
    note: 'A decorated CLASS — @dataclass just annotates it.',
  ),
  ParseSnippet(
    construct: CodeConstruct.klass,
    lang: CodeLang.javascript,
    code: 'const C = class {\n  run() {}\n};',
    tricky: true,
    note: 'A class expression — an anonymous CLASS bound to a const.',
  ),
  ParseSnippet(
    construct: CodeConstruct.klass,
    lang: CodeLang.kotlin,
    code: 'data class User(val id: Int)',
    tricky: true,
    note: 'A data class is still a CLASS — Kotlin just generates its boilerplate.',
  ),
  ParseSnippet(
    construct: CodeConstruct.klass,
    lang: CodeLang.java,
    code: 'abstract class Shape {\n  abstract double area();\n}',
  ),

  // ── VARIABLE ───────────────────────────────────────────────────────────────
  ParseSnippet(
    construct: CodeConstruct.variable,
    lang: CodeLang.python,
    code: 'count = 0',
  ),
  ParseSnippet(
    construct: CodeConstruct.variable,
    lang: CodeLang.javascript,
    code: 'let total = 0;',
  ),
  ParseSnippet(
    construct: CodeConstruct.variable,
    lang: CodeLang.javascript,
    code: 'const PI = 3.14159;',
  ),
  ParseSnippet(
    construct: CodeConstruct.variable,
    lang: CodeLang.typescript,
    code: 'let name: string = "Ada";',
  ),
  ParseSnippet(
    construct: CodeConstruct.variable,
    lang: CodeLang.swift,
    code: 'let maxScore = 100',
    tricky: true,
    note: 'Swift `let` is a constant VARIABLE binding, not a function.',
  ),
  ParseSnippet(
    construct: CodeConstruct.variable,
    lang: CodeLang.swift,
    code: 'var attempts = 0',
  ),
  ParseSnippet(
    construct: CodeConstruct.variable,
    lang: CodeLang.kotlin,
    code: 'val greeting = "hello"',
    tricky: true,
    note: 'A `val` bound to a value is a VARIABLE — a lambda would be a function.',
  ),
  ParseSnippet(
    construct: CodeConstruct.variable,
    lang: CodeLang.kotlin,
    code: 'var counter: Int = 0',
  ),
  ParseSnippet(
    construct: CodeConstruct.variable,
    lang: CodeLang.java,
    code: 'int score = 42;',
  ),
  ParseSnippet(
    construct: CodeConstruct.variable,
    lang: CodeLang.java,
    code: 'final double rate = 0.05;',
  ),
  ParseSnippet(
    construct: CodeConstruct.variable,
    lang: CodeLang.python,
    code: 'age: int = 30',
    tricky: true,
    note: 'A type-annotated VARIABLE assignment.',
  ),

  // ── INTERFACE ──────────────────────────────────────────────────────────────
  ParseSnippet(
    construct: CodeConstruct.interfaceType,
    lang: CodeLang.typescript,
    code: 'interface Point {\n  x: number;\n  y: number;\n}',
  ),
  ParseSnippet(
    construct: CodeConstruct.interfaceType,
    lang: CodeLang.typescript,
    code: 'interface Greeter {\n  greet(name: string): string;\n}',
  ),
  ParseSnippet(
    construct: CodeConstruct.interfaceType,
    lang: CodeLang.java,
    code: 'interface Runnable {\n  void run();\n}',
  ),
  ParseSnippet(
    construct: CodeConstruct.interfaceType,
    lang: CodeLang.kotlin,
    code: 'interface Clickable {\n  fun click()\n}',
  ),
  ParseSnippet(
    construct: CodeConstruct.interfaceType,
    lang: CodeLang.swift,
    code: 'protocol Drawable {\n  func draw()\n}',
    tricky: true,
    note: "Swift's INTERFACE is spelled `protocol` — same idea, a contract.",
  ),
  ParseSnippet(
    construct: CodeConstruct.interfaceType,
    lang: CodeLang.python,
    code: 'class Sized(Protocol):\n    def __len__(self) -> int: ...',
    tricky: true,
    note: 'A Python `Protocol` is a structural INTERFACE, not a normal class.',
  ),
  ParseSnippet(
    construct: CodeConstruct.interfaceType,
    lang: CodeLang.java,
    code: 'interface List<E> {\n  void add(E e);\n}',
  ),
  ParseSnippet(
    construct: CodeConstruct.interfaceType,
    lang: CodeLang.kotlin,
    code: 'interface Named {\n  val name: String\n}',
  ),
  ParseSnippet(
    construct: CodeConstruct.interfaceType,
    lang: CodeLang.typescript,
    code: 'interface Admin extends User {\n  role: string;\n}',
  ),
  ParseSnippet(
    construct: CodeConstruct.interfaceType,
    lang: CodeLang.swift,
    code: 'protocol Container {\n  associatedtype Item\n}',
    tricky: true,
    note: 'Still a `protocol` — Swift for INTERFACE.',
  ),

  // ── LOOP (late phase) ──────────────────────────────────────────────────────
  ParseSnippet(
    construct: CodeConstruct.loop,
    lang: CodeLang.python,
    code: 'for i in range(10):\n    print(i)',
  ),
  ParseSnippet(
    construct: CodeConstruct.loop,
    lang: CodeLang.python,
    code: 'while n > 0:\n    n -= 1',
  ),
  ParseSnippet(
    construct: CodeConstruct.loop,
    lang: CodeLang.javascript,
    code: 'for (let i = 0; i < n; i++) {\n  sum += i;\n}',
  ),
  ParseSnippet(
    construct: CodeConstruct.loop,
    lang: CodeLang.javascript,
    code: 'for (const x of items) {\n  print(x);\n}',
  ),
  ParseSnippet(
    construct: CodeConstruct.loop,
    lang: CodeLang.java,
    code: 'for (int i = 0; i < 10; i++) {\n  total += i;\n}',
  ),
  ParseSnippet(
    construct: CodeConstruct.loop,
    lang: CodeLang.java,
    code: 'while (running) {\n  tick();\n}',
  ),
  ParseSnippet(
    construct: CodeConstruct.loop,
    lang: CodeLang.swift,
    code: 'for item in list {\n  print(item)\n}',
  ),
  ParseSnippet(
    construct: CodeConstruct.loop,
    lang: CodeLang.kotlin,
    code: 'for (i in 1..100) {\n  sum += i\n}',
  ),
  ParseSnippet(
    construct: CodeConstruct.loop,
    lang: CodeLang.kotlin,
    code: 'while (queue.isNotEmpty()) {\n  process()\n}',
  ),
  ParseSnippet(
    construct: CodeConstruct.loop,
    lang: CodeLang.swift,
    code: 'repeat {\n  roll()\n} while dice != 6',
    tricky: true,
    note: 'A repeat-while LOOP — runs the body first, then tests.',
  ),

  // ── IMPORT (late phase) ────────────────────────────────────────────────────
  ParseSnippet(
    construct: CodeConstruct.importStmt,
    lang: CodeLang.python,
    code: 'import numpy as np',
  ),
  ParseSnippet(
    construct: CodeConstruct.importStmt,
    lang: CodeLang.python,
    code: 'from typing import List',
  ),
  ParseSnippet(
    construct: CodeConstruct.importStmt,
    lang: CodeLang.javascript,
    code: 'import React from "react";',
  ),
  ParseSnippet(
    construct: CodeConstruct.importStmt,
    lang: CodeLang.javascript,
    code: 'import { useState } from "react";',
  ),
  ParseSnippet(
    construct: CodeConstruct.importStmt,
    lang: CodeLang.typescript,
    code: 'import type { User } from "./user";',
  ),
  ParseSnippet(
    construct: CodeConstruct.importStmt,
    lang: CodeLang.java,
    code: 'import java.util.List;',
  ),
  ParseSnippet(
    construct: CodeConstruct.importStmt,
    lang: CodeLang.swift,
    code: 'import Foundation',
  ),
  ParseSnippet(
    construct: CodeConstruct.importStmt,
    lang: CodeLang.kotlin,
    code: 'import kotlin.math.sqrt',
  ),
  ParseSnippet(
    construct: CodeConstruct.importStmt,
    lang: CodeLang.javascript,
    code: 'const fs = require("fs");',
    tricky: true,
    note: 'CommonJS require IS an IMPORT — despite looking like a const.',
  ),
  ParseSnippet(
    construct: CodeConstruct.importStmt,
    lang: CodeLang.python,
    code: 'from os import path',
  ),

  // ── ENUM (late phase) ──────────────────────────────────────────────────────
  ParseSnippet(
    construct: CodeConstruct.enumType,
    lang: CodeLang.swift,
    code: 'enum Direction {\n  case north, south, east, west\n}',
  ),
  ParseSnippet(
    construct: CodeConstruct.enumType,
    lang: CodeLang.kotlin,
    code: 'enum class Color {\n  RED, GREEN, BLUE\n}',
    tricky: true,
    note: 'Kotlin writes it `enum class`, but it is an ENUM.',
  ),
  ParseSnippet(
    construct: CodeConstruct.enumType,
    lang: CodeLang.java,
    code: 'enum Day {\n  MON, TUE, WED\n}',
  ),
  ParseSnippet(
    construct: CodeConstruct.enumType,
    lang: CodeLang.typescript,
    code: 'enum Status {\n  Active,\n  Inactive,\n}',
  ),
  ParseSnippet(
    construct: CodeConstruct.enumType,
    lang: CodeLang.python,
    code: 'class Color(Enum):\n    RED = 1\n    GREEN = 2',
    tricky: true,
    note: 'Subclassing `Enum` makes this an ENUM, not a plain class.',
  ),
  ParseSnippet(
    construct: CodeConstruct.enumType,
    lang: CodeLang.swift,
    code: 'enum Planet: Int {\n  case mercury = 1\n}',
  ),
  ParseSnippet(
    construct: CodeConstruct.enumType,
    lang: CodeLang.typescript,
    code: 'const enum Dir {\n  Up,\n  Down,\n}',
    tricky: true,
    note: 'A `const enum` is still an ENUM — inlined at compile time.',
  ),
  ParseSnippet(
    construct: CodeConstruct.enumType,
    lang: CodeLang.java,
    code: 'enum Suit {\n  HEARTS, SPADES;\n}',
  ),
  ParseSnippet(
    construct: CodeConstruct.enumType,
    lang: CodeLang.kotlin,
    code: 'enum class Coin(val cents: Int) {\n  DIME(10)\n}',
    tricky: true,
    note: 'An ENUM with a constructor — each case carries data.',
  ),
];
