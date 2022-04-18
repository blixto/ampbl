# ampbl
A Mui Pequena e Besta Linguagem

Or: The Little Dumb Language

This niche language was created to facilitate the translation of '|' separated files from one format to another by reading each field and transforming it according to a rule encoded in this language, which vaguely resembles LISP.

The parser reads strings in the format (OP;OPERAND1;OPERAND2;...;OPERANDK) and returns the result to the caller. There are a handful of built in relational and arithmetic operators, and a sequential operator that only parses each of its fields in sequence until its end, which provides a way of building little programs with it.
